import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _stickyQuestions = <String>[];
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
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
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
    if (mounted)
      _addSystemMessage('Server started at $localIp:${_serverSocket!.port}');
    _serverSocket!.listen(_handleClientConnection);
  }

  void _handleClientConnection(Socket client) {
    final clientId = '${client.remoteAddress.address}:${client.remotePort}';
    setState(() {
      _clients.add(clientId);
      _connectedClients.add(client);
    });
    client.listen((data) => _handleClientData(client, data),
        onDone: () => _handleClientDisconnect(client, clientId));
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
    if (mounted)
      setState(() => _messages.add({
            'nickname': imageData['nickname'],
            'image': imageData['image'],
            'isImage': true
          }));
    await Future.delayed(Duration(milliseconds: 200));
    _processImageQueue();
  }

  void _sendStickyQuestion(String question) {
    final trimmedQuestion = question.trim();
    final encodedMessage = utf8.encode("Question:$trimmedQuestion");
    for (var client in _connectedClients) client.add(encodedMessage);
    setState(() {
      _stickyQuestions.add(trimmedQuestion);
      print('Added sticky question: "$trimmedQuestion"');
      print('Updated _stickyQuestions: $_stickyQuestions');
    });
  }

  void _removeStickyQuestion(String question) {
    print('Attempting to remove: "$question"');
    print('Current _stickyQuestions: $_stickyQuestions');
    String questionToRemove = question.trim();
    bool isMultipleChoice = questionToRemove.endsWith(" (Multiple Choice)");

    for (var client in _connectedClients) {
      client.write("Removed:$questionToRemove");
    }

    setState(() {
      bool removed = _stickyQuestions.remove(questionToRemove);
      print('Exact match removal result: $removed');
      if (!removed) {
        String baseQuestion = isMultipleChoice
            ? questionToRemove.replaceAll(" (Multiple Choice)", "")
            : questionToRemove;
        _stickyQuestions.removeWhere(
            (q) => q == baseQuestion || q == "$baseQuestion (Multiple Choice)");
        print(
            'Fallback removal attempted. Updated _stickyQuestions: $_stickyQuestions');
      }
    });

    Navigator.pop(context);
    if (_stickyQuestions.isNotEmpty) {
      _showStickyQuestionsDialog();
    } else {
      print('No sticky questions remain after removal.');
    }
  }

  void _sendMultipleChoiceQuestion(String question, List<String> options) {
    final trimmedQuestion = question.trim();
    final fullQuestion = "$trimmedQuestion (Multiple Choice)";
    final message = "MC:$trimmedQuestion|${options.join('|')}";
    for (var client in _connectedClients) client.write(message);
    setState(() {
      _stickyQuestions.add(fullQuestion);
      print('Added MC question: "$fullQuestion"');
      print('Updated _stickyQuestions: $_stickyQuestions');
    });
  }

  void _startSession() {
    for (var client in _connectedClients) client.write("Session started:");
  }

  @override
  void dispose() {
    if (_connectedClients.isNotEmpty) {
      for (var client in _connectedClients) client.write("Host Disconnected");
    }
    _broadcast.stopBroadcast();
    _serverSocket?.close();
    _questionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Exit Session?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('All connections will be terminated.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Exit', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildImageThumbnail(String base64Image) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(base64Decode(base64Image)),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(base64Decode(base64Image),
            width: 100, height: 100, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message['nickname'] ?? 'Unknown',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
            SizedBox(height: 4),
            if (message['text'] != null)
              Text(message['text'], style: TextStyle(fontSize: 16)),
            if (message['isImage'] == true)
              _buildImageThumbnail(message['image']),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(Map<String, dynamic> message) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(message['nickname'] ?? 'Unknown',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
            SizedBox(height: 8),
            _buildImageThumbnail(message['image']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _lobbyState == "lobby" ? 'Lobby' : '$_selectedMode Mode',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onBackPressed()) {
                _serverSocket?.close();
                _broadcast.stopBroadcast();
                Navigator.pop(context);
              }
            },
          ),
          actions: _lobbyState == "start"
              ? [
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showModeSelector,
                  ),
                ]
              : null,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
              child: _lobbyState == "lobby"
                  ? _buildLobbyView()
                  : _buildSessionView()),
        ),
        floatingActionButton:
            _lobbyState == "start" && _stickyQuestions.isNotEmpty
                ? FloatingActionButton(
                    onPressed: _showStickyQuestionsDialog,
                    backgroundColor: Colors.teal[400],
                    child: Icon(Icons.question_answer),
                  )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildLobbyView() {
    return Column(
      children: [
        Expanded(
          child: _participants.isEmpty
              ? Center(
                  child: Text(
                    'Awaiting Participants...',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey[100],
                          child: Text('${index + 1}',
                              style: TextStyle(
                                  color: Colors.blueGrey[800],
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          _participants.keys.elementAt(index),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _participants.length >= 1
                ? () => setState(() {
                      _broadcast.stopBroadcast();
                      _startSession();
                      _lobbyState = "start";
                      _animationController.forward(from: 0);
                    })
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _participants.isEmpty ? Colors.grey[600] : Colors.teal[400],
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 8,
            ),
            child: Text(
              'START SESSION',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionView() {
    return Column(
      children: [
        Expanded(
          child: _selectedMode == "Chat"
              ? ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageTile(_messages[index]),
                )
              : _selectedMode == "Multiple Choice"
                  ? ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _multipleChoiceResponses.length,
                      itemBuilder: (context, index) {
                        final question =
                            _multipleChoiceResponses.keys.elementAt(index);
                        final responses = _multipleChoiceResponses[question]!;
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(question,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  ...responses.entries.map((entry) => Row(
                                        children: [
                                          Text("${entry.key}: ",
                                              style: TextStyle(fontSize: 16)),
                                          Text("${entry.value} votes",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.teal[400])),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount:
                          _messages.where((m) => m['isImage'] == true).length,
                      itemBuilder: (context, index) => _buildImageTile(_messages
                          .where((m) => m['isImage'] == true)
                          .toList()[index]),
                    ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  maxLength: 100,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _selectedMode == "Multiple Choice"
                        ? "Type a question (add options in dialog)"
                        : "Ask a question...",
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () {
                  if (_questionController.text.isNotEmpty &&
                      _participants.isNotEmpty) {
                    if (_selectedMode == "Multiple Choice") {
                      _showMultipleChoiceDialog();
                    } else {
                      _sendStickyQuestion(_questionController.text);
                      _questionController.clear();
                      _animationController.forward(from: 0);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No participants')));
                  }
                },
                backgroundColor: Colors.teal[400],
                child: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showModeSelector() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Waiting for participants...")));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Chat', 'Picture', 'Drawing', 'Multiple Choice']
              .map((mode) => ListTile(
                    title: Text(mode,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() {
                        _messages.clear();
                        _multipleChoiceResponses.clear();
                        _selectedMode = mode;
                        for (var client in _connectedClients)
                          client.write("Mode:$_selectedMode");
                        _animationController.forward(from: 0);
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showMultipleChoiceDialog() {
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create Multiple Choice Question',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(labelText: 'Question'),
              ),
              SizedBox(height: 16),
              ...optionControllers.map((controller) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Option'),
                    ),
                  )),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final question = _questionController.text;
                  final options = optionControllers
                      .map((c) => c.text)
                      .where((text) => text.isNotEmpty)
                      .toList();
                  if (question.isNotEmpty && options.length >= 2) {
                    _sendMultipleChoiceQuestion(question, options);
                    _questionController.clear();
                    optionControllers.forEach((c) => c.clear());
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Enter a question and at least 2 options')));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Send', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickyQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sticky Questions',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800])),
              SizedBox(height: 16),
              Expanded(
                child: _stickyQuestions.isEmpty
                    ? Center(
                        child: Text('No sticky questions yet',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _stickyQuestions.length,
                        itemBuilder: (context, index) {
                          final question = _stickyQuestions[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListTile(
                              title: Text(question,
                                  style: TextStyle(fontSize: 16)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _removeStickyQuestion(question),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
