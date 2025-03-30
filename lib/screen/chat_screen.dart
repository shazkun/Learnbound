import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:Learnbound/database/database_helper.dart';
import 'package:Learnbound/database/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../drawing_canvas.dart';
import '../server_list.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _manualIpController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController();
  Socket? _clientSocket;
  final List<Map<String, dynamic>> _messages = [];
  final List<String> _questions = [];
  final Map<String, List<String>> _multipleChoiceQuestions = {};
  final Map<String, String?> _selectedAnswers = {};
  final Set<String> _confirmedAnswers = {};
  final _picker = ImagePicker();
  String _currentMode = "LOBBY";
  bool _isStarted = false;
  String _changeScreen = "S_LIST";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _messages.add({
      'system': true,
      'text': 'Please wait for the host to start this session.'
    });
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  void _connectToServer(String serverInfo) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    _changeScreen = "S_CHAT";
    Queue<Map<String, dynamic>> messageQueue = Queue();

    void processNextMessage() {
      if (messageQueue.isEmpty) return;
      final messageData = messageQueue.removeFirst();
      setState(() => _messages.add(
          {'text': messageData['text'], 'isImage': messageData['isImage']}));
      if (messageQueue.isNotEmpty)
        Future.delayed(Duration(milliseconds: 50), processNextMessage);
    }

    try {
      final parts = serverInfo.split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);
      _clientSocket =
          await Socket.connect(ip, port).timeout(Duration(seconds: 3));
      _clientSocket!.write("Nickname:${user?.username}");

      if (!mounted) return;
      setState(() {
        _messages
            .add({'text': 'Connected to server $ip:$port', 'isImage': false});
        _currentMode = "Chat";
      });

      _clientSocket!.listen(
        (data) {
          final message = String.fromCharCodes(data).trim();
          if (!mounted) return;

          if (message.startsWith("Mode:")) {
            setState(() => _currentMode = message.substring(5));
          } else if (message.startsWith("Question:")) {
            setState(() => _questions.add(message.substring(9)));
          } else if (message.startsWith("MC:")) {
            final parts = message.substring(3).split("|");
            final question = parts[0];
            final options = parts.sublist(1);
            setState(() => _multipleChoiceQuestions[question] = options);
          } else if (message.startsWith("Host Disconnected")) {
            setState(() {
              _messages.clear();
              _questions.clear();
              _multipleChoiceQuestions.clear();
              _selectedAnswers.clear();
              _confirmedAnswers.clear();
              _changeScreen = "S_LIST";
              _isStarted = false;
              _messages.add({'system': true, 'text': 'Host disconnected.'});
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("Host disconnected.")));
            });
          } else if (message.startsWith("Removed:")) {
            final question = message.substring(8);
            setState(() {
              _questions.remove(question);
              _multipleChoiceQuestions
                  .removeWhere((key, value) => key.contains(question));
              _selectedAnswers.remove(question);
              _confirmedAnswers.remove(question);
            });
          } else if (message.startsWith("Session started:")) {
            setState(() {
              _messages.add({
                'system': true,
                'text': 'The host has started the session.'
              });
              _currentMode = "Chat";
              _isStarted = true;
            });
          } else if (message.startsWith("Image:")) {
            messageQueue.add({'text': message.substring(6), 'isImage': true});
            if (messageQueue.length == 1) processNextMessage();
          } else {
            messageQueue.add({'text': message, 'isImage': false});
            if (messageQueue.length == 1) processNextMessage();
          }
        },
        onError: (error) => setState(() => _messages
            .add({'system': true, 'text': 'Connection error: $error'})),
        onDone: () => setState(() {
          _messages.add({'system': true, 'text': 'Connection closed'});
          _questions.clear();
          _multipleChoiceQuestions.clear();
          _selectedAnswers.clear();
          _confirmedAnswers.clear();
        }),
      );
    } catch (e) {
      setState(() => _messages.add({
            'system': true,
            'text':
                'Connection failed: Failed to connect, server does not exist.'
          }));
    }
  }

  void _sendMessage(String message) {
    if (_clientSocket != null) {
      _clientSocket!.add(utf8.encode(message));
      setState(() => _messages.add({'text': message, 'isImage': false}));
      _messageController.clear();
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      final imageFile = File(pickedFile.path);
      final base64Image = base64Encode(await imageFile.readAsBytes());
      if (_clientSocket != null) {
        _clientSocket!.add(utf8.encode('$base64Image\n'));
        await _clientSocket!.flush();
      }
      setState(() => _messages
          .add({'text': 'Image sent', 'isImage': true, 'image': imageFile}));
    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  Future<void> _openDrawingCanvas() async {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final drawing = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => DrawingCanvas()));
    if (drawing != null) {
      File imgFile = File(drawing);
      final base64Image = base64Encode(await imgFile.readAsBytes());
      _clientSocket!.add(utf8.encode('$base64Image\n'));
      _clientSocket!.flush();
      setState(() => _messages.add(
          {'nickname': user?.username, 'image': imgFile, 'isImage': true}));
    }
  }

  Future<void> _showServerList() async {
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => ServerList(
        onSelectServer: (serverInfo) {
          Navigator.pop(context);
          final ipRegex = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
          final match = ipRegex.firstMatch(serverInfo);
          if (match != null) _connectToServer('${match.group(1)}:4040');
        },
      ),
    );
  }

  @override
  void dispose() {
    _clientSocket?.close();
    _messageController.dispose();
    _manualIpController.dispose();
    _manualPortController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Exit Chat?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Your connection will be lost.'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child:
          _changeScreen == "S_CHAT" ? _buildChatView() : _buildServerListView(),
    );
  }

  Widget _buildChatView() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final profilePicture = user?.profilePicture;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onBackPressed()) Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
               profilePicture!= null && profilePicture!.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: FileImage(File(profilePicture!)))
                  : CircleAvatar(
                      child: Icon(Icons.account_circle, color: Colors.white)),
              SizedBox(width: 12),
              Text(user!.username,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
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
            child: Column(
              children: [
                Expanded(
                  child: _currentMode == "Multiple Choice"
                      ? ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _multipleChoiceQuestions.length,
                          itemBuilder: (context, index) {
                            final question =
                                _multipleChoiceQuestions.keys.elementAt(index);
                            final options = _multipleChoiceQuestions[question]!;
                            final isConfirmed =
                                _confirmedAnswers.contains(question);
                            final selectedAnswer = _selectedAnswers[question];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                              child: Text(question,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                          if (isConfirmed)
                                            Chip(
                                              label: Text('Confirmed',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              backgroundColor: Colors.teal[400],
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      ...options.map((option) =>
                                          RadioListTile<String>(
                                            title: Row(
                                              children: [
                                                Text(option),
                                                if (isConfirmed &&
                                                    selectedAnswer == option)
                                                  SizedBox(width: 8),
                                                if (isConfirmed &&
                                                    selectedAnswer == option)
                                                  Icon(Icons.check,
                                                      color: Colors.teal[400]),
                                              ],
                                            ),
                                            value: option,
                                            groupValue: selectedAnswer,
                                            onChanged: isConfirmed
                                                ? null
                                                : (value) {
                                                    setState(() =>
                                                        _selectedAnswers[
                                                            question] = value);
                                                  },
                                          )),
                                      if (!isConfirmed &&
                                          selectedAnswer != null)
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_clientSocket != null) {
                                              _clientSocket!.write(
                                                  "Answer:$question|$selectedAnswer");
                                              setState(() => _confirmedAnswers
                                                  .add(question));
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal[400],
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: Text('Confirm',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final messageData = _messages[index];
                            bool isSystemMessage =
                                messageData['system'] ?? false;
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isSystemMessage
                                        ? Icon(Icons.info,
                                            color: Colors.blueGrey[800])
                                        : profilePicture != null &&
                                                profilePicture!.isNotEmpty
                                            ? CircleAvatar(
                                                backgroundImage: FileImage(
                                                    File(profilePicture!)))
                                            : CircleAvatar(
                                                child: Icon(
                                                    Icons.account_circle,
                                                    color:
                                                        Colors.blueGrey[800])),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (messageData['isImage'] == true &&
                                              messageData['image'] != null)
                                            GestureDetector(
                                              onTap: () => showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: Image.file(
                                                        messageData['image'],
                                                        fit: BoxFit.contain),
                                                  ),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                    messageData['image'],
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover),
                                              ),
                                            )
                                          else
                                            Text(
                                              messageData['text'] ?? '',
                                              style: TextStyle(
                                                  color: isSystemMessage
                                                      ? Colors.blueGrey[800]
                                                      : Colors.black),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: _currentMode == "LOBBY"
                      ? Center(
                          child: ElevatedButton(
                            onPressed: _showServerList,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[400],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Join Server',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      : _currentMode != "Multiple Choice"
                          ? Row(
                              children: [
                                if (_currentMode == "Chat")
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      maxLength: 100,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: "Type a message...",
                                        hintStyle:
                                            TextStyle(color: Colors.white70),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                SizedBox(width: 8),
                                if (_currentMode == "Chat")
                                  FloatingActionButton(
                                    onPressed: () => _isStarted
                                        ? _sendMessage(_messageController.text)
                                        : _showHostWaitSnackBar(),
                                    backgroundColor: Colors.teal[400],
                                    child: Icon(Icons.send),
                                  ),
                                if (_currentMode == "Picture")
                                  FloatingActionButton(
                                    onPressed: _pickAndSendImage,
                                    backgroundColor: Colors.teal[400],
                                    child: Icon(Icons.image),
                                  ),
                                if (_currentMode == "Drawing")
                                  FloatingActionButton(
                                    onPressed: _openDrawingCanvas,
                                    backgroundColor: Colors.teal[400],
                                    child: Icon(Icons.brush),
                                  ),
                              ],
                            )
                          : Container(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton:
            _questions.isNotEmpty || _multipleChoiceQuestions.isNotEmpty
                ? FloatingActionButton(
                    onPressed: _showQuestionsDialog,
                    backgroundColor: Colors.teal[400],
                    child: Icon(Icons.question_answer),
                  )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildServerListView() {
    return ServerList(
      onSelectServer: (serverInfo) {
        final ipRegex = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
        final match = ipRegex.firstMatch(serverInfo);
        if (match != null) _connectToServer('${match.group(1)}:4040');
      },
    );
  }

  void _showHostWaitSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Please wait for the host to start this session.")),
    );
  }

  void _showQuestionsDialog() {
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
              Text(
                'Sticky Questions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800]),
              ),
              SizedBox(height: 16),
              Expanded(
                child: (_questions.isEmpty && _multipleChoiceQuestions.isEmpty)
                    ? Center(
                        child: Text('No questions yet',
                            style: TextStyle(color: Colors.grey)))
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          ..._questions.map((question) => FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListTile(
                                    title: Text(question,
                                        style: TextStyle(fontSize: 16))),
                              )),
                          ..._multipleChoiceQuestions.entries.map((entry) {
                            final question = entry.key;
                            final options = entry.value;
                            final isConfirmed =
                                _confirmedAnswers.contains(question);
                            final selectedAnswer = _selectedAnswers[question];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: ExpansionTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(question,
                                            style: TextStyle(fontSize: 16))),
                                    if (isConfirmed)
                                      Chip(
                                        label: Text('Confirmed',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.teal[400],
                                      ),
                                  ],
                                ),
                                children: [
                                  ...options.map((option) => ListTile(
                                        title: Row(
                                          children: [
                                            Text(option),
                                            if (isConfirmed &&
                                                selectedAnswer == option)
                                              SizedBox(width: 8),
                                            if (isConfirmed &&
                                                selectedAnswer == option)
                                              Icon(Icons.check,
                                                  color: Colors.teal[400]),
                                          ],
                                        ),
                                        onTap: isConfirmed
                                            ? null
                                            : () {
                                                setState(() =>
                                                    _selectedAnswers[question] =
                                                        option);
                                              },
                                      )),
                                  if (!isConfirmed && selectedAnswer != null)
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_clientSocket != null) {
                                            _clientSocket!.write(
                                                "Answer:$question|$selectedAnswer");
                                            setState(() => _confirmedAnswers
                                                .add(question));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal[400],
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: Text('Confirm',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
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
