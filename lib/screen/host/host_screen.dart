import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/host/app_styles.dart';
import 'package:Learnbound/screen/host/host_widgets.dart';
import 'package:Learnbound/util/server.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen>
    with SingleTickerProviderStateMixin {
  final _clients = <String>[];
  final _messages = <Map<String, dynamic>>[];
  final _stickyQuestions = <String>["test"];
  final _multipleChoiceResponses = <String, Map<String, int>>{};
  ServerSocket? _serverSocket;
  final _questionController = TextEditingController();
  final _clientNicknames = <Socket, String>{};
  final _connectedClients = <Socket>[];
  final _participants = <String, int>{};
  final _dataBuffer = StringBuffer();
  final _broadcast = BroadcastServer();
  String _lobbyState = "lobby";
  String _selectedMode = "Chat";
  final _imageQueue = Queue<Map<String, dynamic>>();
  bool _isProcessingImage = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startServer();
    _broadcast.startBroadcast();
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

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      return interfaces
          .expand((i) => i.addresses)
          .firstWhere((addr) =>
              addr.type == InternetAddressType.IPv4 && !addr.isLoopback)
          .address;
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  Future<void> _startServer() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _broadcast.setBroadcastName(userProvider.user?.username ?? "no name");
    _serverSocket = await ServerSocket.bind('0.0.0.0', 4040);
    final localIp = await _getLocalIp();
    if (mounted) {
      _addSystemMessage('Server started at $localIp:${_serverSocket!.port}');
    }
    _serverSocket!.listen(_handleClientConnection);
  }

  void _handleClientConnection(Socket client) {
    final clientId = '${client.remoteAddress.address}:${client.remotePort}';
    setState(() {
      _clients.add(clientId);
      _connectedClients.add(client);
    });
    client.listen(
      (data) => _handleClientData(client, data),
      onDone: () => _handleClientDisconnect(client, clientId),
    );
  }

  void _handleClientData(Socket client, List<int> data) async {
    final message = utf8.decode(data).trim();
    final nickname = _clientNicknames[client] ?? client.remoteAddress.address;

    if (message.startsWith("Nickname:")) {
      final newNickname = message.substring(9);
      _clientNicknames[client] = newNickname;
      _participants[newNickname] = 0;
      _addSystemMessage('$newNickname connected.');
    } else if (message.startsWith("Question:")) {
      final question = message.substring(9);
      _addMessage(question, nickname);
    } else if (_selectedMode == "Picture" || _selectedMode == "Drawing") {
      _dataBuffer.write(utf8.decode(data));
      if (_dataBuffer.toString().endsWith('\n')) {
        _imageQueue.add(
            {'nickname': nickname, 'image': _dataBuffer.toString().trim()});
        if (!_isProcessingImage) _processImageQueue();
        _dataBuffer.clear();
      }
    } else if (_selectedMode == "Multiple Choice" &&
        message.startsWith("Answer:")) {
      final answerData = message.substring(7).split("|");
      final question = answerData[0];
      final option = answerData[1];
      setState(() {
        _multipleChoiceResponses.putIfAbsent(question, () => {});
        _multipleChoiceResponses[question]![option] =
            (_multipleChoiceResponses[question]![option] ?? 0) + 1;
      });
    } else if (_selectedMode == "Chat") {
      _addMessage(message, nickname);
    }
  }

  void _handleClientDisconnect(Socket client, String clientId) {
    if (!mounted) return;
    final nickname = _clientNicknames[client] ?? client.remoteAddress.address;
    setState(() {
      _addSystemMessage('$nickname disconnected.');
      _clients.remove(clientId);
      _clientNicknames.remove(client);
      _participants.remove(nickname);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$nickname disconnected")));
  }

  void _addSystemMessage(String text) => setState(() =>
      _messages.add({'text': text, 'nickname': 'System', 'isImage': false}));
  void _addMessage(String text, String nickname) => setState(() =>
      _messages.add({'text': text, 'nickname': nickname, 'isImage': false}));

  Future<void> _processImageQueue() async {
    if (_imageQueue.isEmpty) {
      _isProcessingImage = false;
      return;
    }
    _isProcessingImage = true;
    final imageData = _imageQueue.removeFirst();
    if (mounted) {
      setState(() => _messages.add({
            'nickname': imageData['nickname'],
            'image': imageData['image'],
            'isImage': true,
          }));
    }
    await Future.delayed(const Duration(milliseconds: 200));
    _processImageQueue();
  }

  void _sendStickyQuestion(String question) {
    final trimmedQuestion = question.trim();
    final encodedMessage = utf8.encode("Question:$trimmedQuestion");
    for (var client in _connectedClients) {
      client.add(encodedMessage);
    }
    setState(() {
      _stickyQuestions.add(trimmedQuestion);
    });
  }

  void _removeStickyQuestion(String question) {
    String questionToRemove = question.trim();
    bool isMultipleChoice = questionToRemove.endsWith(" (Multiple Choice)");
    String broadcastQuestion = isMultipleChoice
        ? questionToRemove.replaceAll(" (Multiple Choice)", "")
        : questionToRemove;

    for (var client in _connectedClients) {
      client.write("Removed:$broadcastQuestion");
    }

    setState(() {
      bool removed = _stickyQuestions.remove(questionToRemove);
      if (!removed) {
        String baseQuestion = isMultipleChoice
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
    final trimmedQuestion = question.trim();
    final fullQuestion = "$trimmedQuestion (Multiple Choice)";
    final message = "MC:$trimmedQuestion|${options.join('|')}";
    for (var client in _connectedClients) {
      client.write(message);
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
      client.write("Session started:");
    }
  }

  Future<bool> _onBackPressed() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: AppStyles.dialogShape,
            title: const Text('Exit Session?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('All connections will be terminated.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
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
      shape: AppStyles.dialogShape, // should already have borderRadius
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // smooth rounding
          child: ModeSelectorDialog(
            onModeSelected: (mode) {
              setState(() {
                _messages.clear();
                _multipleChoiceResponses.clear();
                _selectedMode = mode;
                for (var client in _connectedClients) {
                  client.write("Mode:$_selectedMode");
                }
                _animationController.forward(from: 0);
              });
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

  @override
  void dispose() {
    if (_connectedClients.isNotEmpty) {
      for (var client in _connectedClients) {
        client.write("Host Disconnected");
      }
    }
    _broadcast.stopBroadcast();
    _serverSocket?.close();
    _questionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          lobbyState: _lobbyState,
          selectedMode: _selectedMode,
          onSettingsPressed: _showModeSelector,
          onBackPressed: _onBackPressed,
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
