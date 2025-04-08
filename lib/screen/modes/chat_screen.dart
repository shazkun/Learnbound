import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/drawing_screen.dart';
import 'package:Learnbound/screen/modes/drawing.dart';
import 'package:Learnbound/screen/modes/questions_dialog.dart';
import 'package:Learnbound/screen/server_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'chat_app_bar.dart';
import 'lobby_ui.dart';
import 'chat_ui.dart';
import 'multiple_choice_ui.dart';
import 'picture_ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
      if (messageQueue.isEmpty || !mounted) return;
      final messageData = messageQueue.removeFirst();
      setState(() => _messages.add(
          {'text': messageData['text'], 'isImage': messageData['isImage']}));
      if (messageQueue.isNotEmpty) {
        Future.delayed(Duration(milliseconds: 50), processNextMessage);
      }
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
            if (mounted) setState(() => _currentMode = message.substring(5));
          } else if (message.startsWith("Question:")) {
            if (mounted) setState(() => _questions.add(message.substring(9)));
          } else if (message.startsWith("MC:")) {
            final parts = message.substring(3).split("|");
            final question = parts[0];
            final options = parts.sublist(1);
            if (mounted) {
              setState(() => _multipleChoiceQuestions[question] = options);
            }
          } else if (message.startsWith("Host Disconnected")) {
            if (mounted) {
              setState(() {
                _messages.clear();
                _questions.clear();
                _multipleChoiceQuestions.clear();
                _selectedAnswers.clear();
                _confirmedAnswers.clear();
                _changeScreen = "S_LIST";
                _isStarted = false;
                _messages.add({'system': true, 'text': 'Host disconnected.'});
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Host disconnected.")));
              });
            }
          } else if (message.startsWith("Removed:")) {
            final question = message.substring(8).trim();
            if (mounted) {
              setState(() {
                _questions.remove(question);
                _multipleChoiceQuestions.remove(question);
                _selectedAnswers.remove(question);
                _confirmedAnswers.remove(question);
                print(
                    'Removed: $question, Remaining: ${_multipleChoiceQuestions.keys}');
              });
            }
          } else if (message.startsWith("Session started:")) {
            if (mounted) {
              setState(() {
                _messages.add({
                  'system': true,
                  'text': 'The host has started the session.'
                });
                _currentMode = "Chat";
                _isStarted = true;
              });
            }
          } else if (message.startsWith("Image:")) {
            messageQueue.add({'text': message.substring(6), 'isImage': true});
            if (messageQueue.length == 1) processNextMessage();
          } else {
            messageQueue.add({'text': message, 'isImage': false});
            if (messageQueue.length == 1) processNextMessage();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _messages
                .add({'system': true, 'text': 'Connection error: $error'}));
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _messages.add({'system': true, 'text': 'Connection closed'});
              _questions.clear();
              _multipleChoiceQuestions.clear();
              _selectedAnswers.clear();
              _confirmedAnswers.clear();
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({
              'system': true,
              'text':
                  'Connection failed: Failed to connect, server does not exist.'
            }));
      }
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

  void _showHostWaitSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Please wait for the host to start this session.")),
    );
  }

  @override
  void dispose() {
    _clientSocket?.destroy();
    _clientSocket = null;
    _messageController.dispose();
    _manualIpController.dispose();
    _manualPortController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    final confirmed = await showDialog<bool>(
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
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  // Close the socket before confirming exit
                  _clientSocket?.destroy();
                  _clientSocket = null;
                  Navigator.pop(context, true);
                },
                child: Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed && kDebugMode) {
      print('Dialog dismissed without explicit choice');
    }

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: _changeScreen == "S_CHAT"
          ? Scaffold(
              extendBodyBehindAppBar: true,
              appBar: ChatAppBar(user: user, onBackPressed: _onBackPressed),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(child: _buildModeUI()),
              ),
              floatingActionButton:
                  _questions.isNotEmpty || _multipleChoiceQuestions.isNotEmpty
                      ? FloatingActionButton(
                          onPressed: () => showQuestionsDialog(
                            context: context,
                            questions: _questions,
                            multipleChoiceQuestions: _multipleChoiceQuestions,
                            selectedAnswers: _selectedAnswers,
                            confirmedAnswers: _confirmedAnswers,
                            fadeAnimation: _fadeAnimation,
                            clientSocket: _clientSocket,
                            onStateUpdate: setState,
                          ),
                          backgroundColor: Colors.teal[400],
                          child: Icon(Icons.question_answer),
                        )
                      : null,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            )
          : ServerList(
              onSelectServer: (serverInfo) {
                final ipRegex =
                    RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
                final match = ipRegex.firstMatch(serverInfo);
                if (match != null) _connectToServer('${match.group(1)}:4040');
              },
            ),
    );
  }

  Widget _buildModeUI() {
    switch (_currentMode) {
      case "LOBBY":
        return LobbyUI(onShowServerList: _showServerList);
      case "Chat":
        return ChatUI(
          messages: _messages,
          fadeAnimation: _fadeAnimation,
          messageController: _messageController,
          isStarted: _isStarted,
          onSendMessage: _sendMessage,
          onWaitSnackBar: _showHostWaitSnackBar,
        );
      case "Multiple Choice":
        return MultipleChoiceUI(
          questions: _multipleChoiceQuestions,
          selectedAnswers: _selectedAnswers,
          confirmedAnswers: _confirmedAnswers,
          fadeAnimation: _fadeAnimation,
          clientSocket: _clientSocket,
          onStateUpdate: setState,
        );
      case "Picture":
        return PictureUI(onPickAndSendImage: _pickAndSendImage);
      case "Drawing":
        return DrawingUI(onOpenDrawingCanvas: _openDrawingCanvas);
      default:
        return Center(
            child: Text("Unknown mode", style: TextStyle(color: Colors.white)));
    }
  }
}
