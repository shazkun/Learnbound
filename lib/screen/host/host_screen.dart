import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/host/host_styles.dart';
import 'package:learnbound/screen/host/host_widgets.dart';
import 'package:learnbound/screen/host/sticky_dialog.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../util/design/snackbar.dart';
import '../home_screen.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen>
    with SingleTickerProviderStateMixin {
  List<String> _clients = []; // List of client IDs/names (likely legacy)
  final _clientNicknames = <Socket, String>{}; // Mapping sockets to nicknames
  final _connectedClients = <Socket>[]; // Currently connected clients
  final _clientStreams =
      <Socket, StreamController<String>>{}; // Streams for individual clients
  final _participants =
      <String, int>{}; // Participant activity (e.g. response count)
  final _participantConnectionTimes =
      <String, DateTime>{}; // Connection timestamps

  List<Map<String, dynamic>> _messages = []; // Chat/message logs
  final _questionController = TextEditingController(); // Input for questions
  final _stickyQuestions = <String>[]; // Pinned/sticky questions
  final _multipleChoiceResponses = <String, Map<String, int>>{}; // MCQ answers

  ServerSocket? _serverSocket; // The TCP server socket
  final _broadcast = BroadcastServer(); // Broadcast handler
  final StringBuffer dataBuffer =
      StringBuffer(); // Buffer for incoming raw data

  String _lobbyState = "lobby"; // Lobby or active session
  String _selectedMode = "Chat"; // Mode: Chat, Drawing, MCQ, etc.
  late DateTime _sessionStartTime; // When session started

  late AnimationController _animationController; // Animation controller
  late Animation<double> _fadeAnimation; // Fade animation

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now().toUtc();
    _initializeAnimations();
    _startServer();
    _broadcast.startBroadcast();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _startServer() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _broadcast.setBroadcastName(userProvider.user?.username ?? "Host");
    try {
      _serverSocket = await ServerSocket.bind('0.0.0.0', 4040, shared: true);
      final localIp = await _broadcast.getLocalIp();
      _addSystemMessage('Server started at $localIp:4040');
      _serverSocket!.listen(
        _handleClientConnection,
        onError: (e) => _addSystemMessage('Server error: $e'),
      );
    } catch (e) {
      _addSystemMessage('Failed to start server: $e');
      CustomSnackBar.show(
        context,
        "Server failed to start: $e",
        isSuccess: false,
      );
    }
  }

  void _handleClientConnection(Socket client) {
    final clientId = '${client.remoteAddress.address}:${client.remotePort}';
    final timestamp = DateTime.now().toUtc().toIso8601String();
    _connectedClients.add(client);
    setState(() {
      _clients = [..._clients, clientId];
    });

    client.listen(
      (data) {
        try {
          String message = utf8.decode(data).trim();

          if (message.isEmpty) {
            client.add(utf8.encode('Error: Invalid message'));
            return;
          }

          final nickname =
              _clientNicknames[client] ?? client.remoteAddress.address;

          if (!_clientNicknames.containsKey(client)) {
            if (message.startsWith("Nickname:")) {
              final newNickname = message.substring(9);
              if (newNickname.isNotEmpty && newNickname.length <= 20) {
                _clientNicknames[client] = newNickname;
                _participants[newNickname] = 0;
                _participantConnectionTimes[newNickname] =
                    DateTime.now().toUtc();
                _addSystemMessage('$newNickname connected.');
              } else {
                client.add(utf8.encode('Error: Invalid nickname'));
              }
            } else {
              client.add(utf8.encode('Error: Send nickname first'));
            }
            return;
          }

          if (message.startsWith("Question:")) {
            final question = message.substring(9);
            _addMessage(question, nickname, timestamp);
            return;
          }
          if (_selectedMode == "Chat") {
            _addMessage(message, nickname, timestamp);
          }

          if (_selectedMode == "Picture") {
            dataBuffer.write(utf8.decode(data));
            if (dataBuffer.toString().endsWith('\n')) {
              String imageData = dataBuffer.toString().trim();
              addPictureMessage(nickname, imageData, timestamp);
              dataBuffer.clear();
            }
            return;
          }

          if (_selectedMode == "Drawing") {
            dataBuffer.write(utf8.decode(data));
            if (dataBuffer.toString().endsWith('\n')) {
              String imageData = dataBuffer.toString().trim();
              addDrawingMessage(nickname, imageData, timestamp);
              dataBuffer.clear();
            }
            return;
          }

          if (_selectedMode == "Multiple Choice" &&
              message.startsWith("Answer:")) {
            final answerData = message.substring(7).split("|");
            if (answerData.length == 3) {
              final question = answerData[0];
              final option = answerData[1];
              final username = answerData[2];

              _multipleChoiceResponses.putIfAbsent(question, () => {});
              _multipleChoiceResponses[question]![option] =
                  (_multipleChoiceResponses[question]![option] ?? 0) + 1;

              print("Received answer from $username: $question - $option");

              setState(() {});
            }
            return;
          }
        } catch (e) {
          print('Error decoding client data: $e');
        }
      },
      onDone: () => _handleClientDisconnect(client, clientId),
      onError: (e) => _addSystemMessage('Client error: $e'),
    );
  }

  void _handleClientDisconnect(Socket client, String clientId) {
    if (!mounted) return;

    final nickname = _clientNicknames[client] ?? client.remoteAddress.address;
    _addSystemMessage('$nickname disconnected.');
    setState(() {
      _clients = _clients.where((id) => id != clientId).toList();
    });
    _clientNicknames.remove(client);
    _participants.remove(nickname);
    _clientStreams.remove(client)?.close();
    _connectedClients.remove(client);
    _participantConnectionTimes.remove(nickname);

    CustomSnackBar.show(context, "$nickname disconnected.",
        isSuccess: false, backgroundColor: Colors.white12);
  }

  void addDrawingMessage(String nickname, String imageData, String timestamp) {
    return setState(() {
      _messages = [
        ..._messages,
        {
          'nickname': nickname,
          'image': imageData,
          'isImage': true,
          'isDrawing': true,
          'timestamp': timestamp,
        }
      ];
    });
  }

  void addPictureMessage(String nickname, String imageData, String timestamp) {
    return setState(() {
      _messages = [
        ..._messages,
        {
          'nickname': nickname,
          'image': imageData,
          'isImage': true,
          'isDrawing': false,
          'timestamp': timestamp,
        }
      ];
    });
  }

  void _addSystemMessage(String text) {
    if (!mounted) return;
    final timestamp = DateTime.now().toUtc().toIso8601String();
    setState(() {
      _messages = [
        ..._messages,
        {
          'text': text,
          'nickname': 'System',
          'isImage': false,
          'timestamp': timestamp,
        }
      ];
    });
  }

  void _addMessage(String text, String nickname, String timestamp) {
    if (!mounted) return;
    setState(() {
      _messages = [
        ..._messages,
        {
          'text': text,
          'nickname': nickname,
          'isImage': false,
          'timestamp': timestamp,
        }
      ];
    });
  }

  void _sendStickyQuestion(String question) {
    if (!mounted) return;
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) return;
    final encodedMessage = utf8.encode("Question:$trimmedQuestion");
    for (var client in _connectedClients) {
      client.add(encodedMessage);
    }
    setState(() {
      _stickyQuestions.add(trimmedQuestion);
    });
  }

  void _removeStickyQuestion(String question) {
    if (!mounted) return;
    final questionToRemove = question.trim();
    final isMultipleChoice = questionToRemove.endsWith(" (Multiple Choice)");
    final broadcastQuestion = isMultipleChoice
        ? questionToRemove.replaceAll(" (Multiple Choice)", "")
        : questionToRemove;

    for (var client in _connectedClients) {
      client.add(utf8.encode("Removed:$broadcastQuestion"));
    }

    setState(() {
      bool removed = _stickyQuestions.remove(questionToRemove);
      if (!removed) {
        final baseQuestion = isMultipleChoice
            ? questionToRemove.replaceAll(" (Multiple Choice)", "")
            : questionToRemove;
        _stickyQuestions.removeWhere(
            (q) => q == baseQuestion || q == "$baseQuestion (Multiple Choice)");
      }
    });

    Navigator.pop(context);
    if (_stickyQuestions.isNotEmpty) {
      showStickyQuestionsDialog();
    }
  }

  void _sendMultipleChoiceQuestion(String question, List<String> options) {
    if (question.trim().isEmpty ||
        options.isEmpty ||
        options.any((o) => o.trim().isEmpty)) {
      CustomSnackBar.show(context, "Question and options cannot be empty.",
          isSuccess: false, backgroundColor: Colors.orangeAccent);
      return;
    }
    final trimmedQuestion = question.trim();
    final fullQuestion = "$trimmedQuestion (Multiple Choice)";
    final message = "MC:$trimmedQuestion|${options.join('|')}";
    for (var client in _connectedClients) {
      client.add(utf8.encode(message));
    }
    setState(() {
      _stickyQuestions.add(fullQuestion);
      _multipleChoiceResponses[fullQuestion] = {
        for (var option in options) option: 0
      };
    });
  }

  void _startSession() {
    for (var client in _connectedClients) {
      client.add(utf8.encode("Session started:"));
    }
  }

  void _showModeSelector() {
    if (_participants.isEmpty) {
      CustomSnackBar.show(context, 'Waiting for participants...',
          backgroundColor: Colors.white12);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: AppStyles.dialogShape,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ModeSelectorDialog(
            onModeSelected: (mode) {
              setState(() {
                // _messages = [];
                _multipleChoiceResponses.clear();
                _selectedMode = mode;
                for (var client in _connectedClients) {
                  client.add(utf8.encode("Mode:$_selectedMode"));
                }
                _animationController.forward(from: 0);
              });

              CustomSnackBar.show(context, "Mode switched to $mode",
                  backgroundColor: Colors.brown, icon: Icons.info);
            },
          ),
        ),
      ),
    );
  }

  void _showMultipleChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: AppStyles.dialogShape,
        child: MultipleChoiceDialog(
          questionController: _questionController,
          onSend: _sendMultipleChoiceQuestion,
        ),
      ),
    );
  }

  void showStickyQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: AppStyles.dialogShape,
        child: StickyQuestionsDialog(
          stickyQuestions: _stickyQuestions,
          fadeAnimation: _fadeAnimation,
          onRemoveQuestion: _removeStickyQuestion,
        ),
      ),
    );
  }

  Future<void> _saveSessionLog() async {
    try {
      if (_lobbyState == "start") {
        final endTime = DateTime.now().toUtc();
        final participantsLog = _participants.keys.map((nickname) {
          final startTime =
              _participantConnectionTimes[nickname] ?? _sessionStartTime;
          final duration = endTime.difference(startTime).inSeconds;
          return {
            'nickname': nickname,
            'connection_duration_seconds': duration,
          };
        }).toList();

        final log = {
          'session': {
            'start_time': _sessionStartTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'mode': _selectedMode,
          },
          'messages': _messages.map((msg) {
            final newMsg = Map.fromEntries(msg.entries.map((entry) {
              if (entry.value is bool) {
                return MapEntry(entry.key, entry.value);
              }
              return entry;
            }));
            return newMsg;
          }).toList(),
          'sticky_questions': _stickyQuestions,
          'multiple_choice_responses': _multipleChoiceResponses,
          'participants': participantsLog,
        };

        final tempDir = await getTemporaryDirectory();
        final timestamp = endTime
            .toIso8601String()
            .replaceAll(':', '')
            .replaceAll('-', '')
            .split('.')
            .first;
        final file = File('${tempDir.path}/sessionhost_$timestamp.json');
        await file.writeAsString(jsonEncode(log), flush: true);
        print('Session log saved to ${file.path}');
      }
    } catch (e) {
      print('Error saving session log: $e');
    }
  }

  Future<void> _cleanupClients() async {
    for (var client in _connectedClients) {
      try {
        client.add(utf8.encode("Host Disconnected"));
        await client.flush();
        await client.close();
      } catch (e) {
        print("Error closing client: $e");
      }
    }
  }

  @override
  void dispose() {
    _cleanupClients();

    _serverSocket?.close();
    _broadcast.stopBroadcast();
    _questionController.dispose();
    _animationController.dispose();
    for (var controller in _clientStreams.values) {
      controller.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit =
            await CustomExitDialog.show(context, usePushReplacement: false);
        if (shouldExit) {
          await _saveSessionLog();
        }
        return shouldExit;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          lobbyState: _lobbyState,
          selectedMode: _selectedMode,
          onSettingsPressed: _showModeSelector,
          onBackPressed: () async {
            final shouldExit = await CustomExitDialog.show(context,
                usePushReplacement: true, targetPage: HomeScreen());
            if (shouldExit) {
              await _saveSessionLog();
              _serverSocket?.close();
            }
            return shouldExit;
          },
          onBackSuccess: () => _serverSocket?.close(),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppStyles.scaffoldGradient),
          child: SafeArea(
            child: _lobbyState == "lobby"
                ? LobbyView(
                    participants: _participants,
                    fadeAnimation: _fadeAnimation,
                    onStartSession: () {
                      setState(() {
                        _broadcast.stopBroadcast();
                        _startSession();
                        _lobbyState = "start";
                        _animationController.forward(from: 0);
                      });
                    },
                  )
                : SessionView(
                    selectedMode: _selectedMode,
                    messages: _messages,
                    multipleChoiceResponses: _multipleChoiceResponses,
                    fadeAnimation: _fadeAnimation,
                    questionController: _questionController,
                    onSendQuestion: () {
                      _sendStickyQuestion(_questionController.text);
                      _questionController.clear();
                      _animationController.forward(from: 0);
                    },
                    onShowMultipleChoiceDialog: _showMultipleChoiceDialog,
                    onShowSticky: showStickyQuestionsDialog,
                  ),
          ),
        ),
      ),
    );
  }
}
