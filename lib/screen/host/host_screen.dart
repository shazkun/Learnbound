import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/host/host_styles.dart';
import 'package:learnbound/screen/host/host_widgets.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxMessages = 100; // Limit message history
  static const int _maxImageQueueSize = 10; // Limit image queue

  final _clientsNotifier = ValueNotifier<List<String>>([]);
  final _messagesNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _stickyQuestions = <String>[];
  final _multipleChoiceResponses = <String, Map<String, int>>{};
  ServerSocket? _serverSocket;
  final _questionController = TextEditingController();
  final _clientNicknames = <Socket, String>{};
  final _connectedClients = <Socket>[];
  final _participants = <String, int>{};
  final _clientStreams = <Socket, StreamController<String>>{};
  final _imageQueue = Queue<Map<String, dynamic>>();
  final _broadcast = BroadcastServer();
  final _participantConnectionTimes = <String, DateTime>{};
  String _lobbyState = "lobby";
  String _selectedMode = "Chat";
  bool _isProcessingImage = false;
  late DateTime _sessionStartTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server failed to start: $e')),
      );
    }
  }

  void _handleClientConnection(Socket client) {
    final clientId = '${client.remoteAddress.address}:${client.remotePort}';
    final streamController = StreamController<String>();
    _clientStreams[client] = streamController;
    _connectedClients.add(client);
    _clientsNotifier.value = [..._clientsNotifier.value, clientId];

    client.listen(
      (data) {
        try {
          final message = utf8.decode(data).trim();
          streamController.add(message);
        } catch (e) {
          print('Error decoding client data: $e');
        }
      },
      onDone: () => _handleClientDisconnect(client, clientId),
      onError: (e) => _addSystemMessage('Client error: $e'),
    );

    streamController.stream
        .listen((message) => _handleClientData(client, message));
  }

  void _handleClientData(Socket client, String message) {
    if (message.isEmpty || message.length > 1000) {
      client.add(utf8.encode('Error: Invalid message'));
      return;
    }

    final nickname = _clientNicknames[client] ?? client.remoteAddress.address;

    if (!_clientNicknames.containsKey(client)) {
      if (message.startsWith("Nickname:")) {
        final newNickname = message.substring(9);
        if (newNickname.isNotEmpty && newNickname.length <= 20) {
          _clientNicknames[client] = newNickname;
          _participants[newNickname] = 0;
          _participantConnectionTimes[newNickname] = DateTime.now().toUtc();
          _addSystemMessage('$newNickname connected.');
        } else {
          client.add(utf8.encode('Error: Invalid nickname'));
        }
      } else {
        client.add(utf8.encode('Error: Send nickname first'));
      }
      return;
    }

    final timestamp = DateTime.now().toUtc().toIso8601String();

    if (message.startsWith("Question:")) {
      final question = message.substring(9);
      _addMessage(question, nickname, timestamp);
    } else if (_selectedMode == "Picture" || _selectedMode == "Drawing") {
      if (_imageQueue.length < _maxImageQueueSize) {
        _imageQueue.add({
          'nickname': nickname,
          'image': message,
          'timestamp': timestamp,
        });
        if (!_isProcessingImage) _processImageQueue();
      } else {
        client.add(utf8.encode('Error: Image queue full'));
      }
    } else if (_selectedMode == "Multiple Choice" &&
        message.startsWith("Answer:")) {
      final answerData = message.substring(7).split("|");
      if (answerData.length == 2) {
        final question = answerData[0];
        final option = answerData[1];
        _multipleChoiceResponses.putIfAbsent(question, () => {});
        _multipleChoiceResponses[question]![option] =
            (_multipleChoiceResponses[question]![option] ?? 0) + 1;
        _messagesNotifier.value = [
          ..._messagesNotifier.value
        ]; // Trigger UI update
      }
    } else if (_selectedMode == "Chat") {
      _addMessage(message, nickname, timestamp);
    }
  }

  void _handleClientDisconnect(Socket client, String clientId) {
    if (!mounted) return;

    final nickname = _clientNicknames[client] ?? client.remoteAddress.address;
    _addSystemMessage('$nickname disconnected.');
    _clientsNotifier.value =
        _clientsNotifier.value.where((id) => id != clientId).toList();
    _clientNicknames.remove(client);
    _participants.remove(nickname);
    _clientStreams.remove(client)?.close();
    _connectedClients.remove(client);
    _participantConnectionTimes.remove(nickname);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nickname disconnected')),
    );
  }

  void _addSystemMessage(String text) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    _messagesNotifier.value = [
      ..._messagesNotifier.value,
      {
        'text': text,
        'nickname': 'System',
        'is_image': false,
        'timestamp': timestamp,
      }
    ];
    if (_messagesNotifier.value.length > _maxMessages) {
      _messagesNotifier.value = _messagesNotifier.value.sublist(1);
    }
  }

  void _addMessage(String text, String nickname, String timestamp) {
    _messagesNotifier.value = [
      ..._messagesNotifier.value,
      {
        'text': text,
        'nickname': nickname,
        'is_image': false,
        'timestamp': timestamp,
      }
    ];
    if (_messagesNotifier.value.length > _maxMessages) {
      _messagesNotifier.value = _messagesNotifier.value.sublist(1);
    }
  }

  Future<void> _processImageQueue() async {
    if (_imageQueue.isEmpty) {
      _isProcessingImage = false;
      return;
    }
    _isProcessingImage = true;
    final imageData = _imageQueue.removeFirst();
    if (mounted) {
      _messagesNotifier.value = [
        ..._messagesNotifier.value,
        {
          'nickname': imageData['nickname'],
          'image': imageData['image'],
          'is_image': true,
          'timestamp': imageData['timestamp'],
        }
      ];
      if (_messagesNotifier.value.length > _maxMessages) {
        _messagesNotifier.value = _messagesNotifier.value.sublist(1);
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    _processImageQueue();
  }

  void _sendStickyQuestion(String question) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question and options cannot be empty')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiting for participants...")),
      );
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
                _messagesNotifier.value = [];
                _multipleChoiceResponses.clear();
                _selectedMode = mode;
                for (var client in _connectedClients) {
                  client.add(utf8.encode("Mode:$_selectedMode"));
                }
                _animationController.forward(from: 0);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Mode switched to $mode")),
              );
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
          'messages': _messagesNotifier.value,
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
        final file = File('${tempDir.path}/session_$timestamp.json');
        await file.writeAsString(jsonEncode(log), flush: true);
        print('Session log saved to ${file.path}');
      }
    } catch (e) {
      print('Error saving session log: $e');
    }
  }

  @override
  void dispose() {
    for (var client in _connectedClients) {
      client.add(utf8.encode("Host Disconnected"));
      client.flush();
      client.close();
    }
    _serverSocket?.close();
    _broadcast.stopBroadcast();
    _saveSessionLog();
    _questionController.dispose();
    _animationController.dispose();
    for (var controller in _clientStreams.values) {
      controller.close();
    }
    _messagesNotifier.dispose();
    _clientsNotifier.dispose();
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
                : ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _messagesNotifier,
                    builder: (context, messages, _) => SessionView(
                      selectedMode: _selectedMode,
                      messages: messages,
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
      ),
    );
  }
}
