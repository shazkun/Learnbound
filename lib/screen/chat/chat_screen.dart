import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/chat/question_notifier.dart';
import 'package:learnbound/screen/chat/ui/drawing_ui.dart';
import 'package:learnbound/screen/drawing_screen.dart';
import 'package:learnbound/screen/multi_server.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'chat_app_bar.dart';
import 'ui/chat_ui.dart';
import 'ui/lobby_ui.dart';
import 'ui/multiple_choice_ui.dart';
import 'ui/picture_ui.dart';

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
  String? _latestDrawingPath;
  String? _latestImagePath;
  bool hasNotifications = false;

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
    final questionsProvider =
        Provider.of<QuestionsProvider>(context, listen: false);
    final user = userProvider.user;

    _changeScreen = "S_CHAT";
    Queue<Map<String, dynamic>> messageQueue = Queue();

    void processNextMessage() {
      if (messageQueue.isEmpty || !mounted) return;

      final messageData = messageQueue.removeFirst();
      setState(() {
        _messages.add(
            {'text': messageData['text'], 'isImage': messageData['isImage']});
      });

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
            setState(() => _currentMode = message.substring(5));
          } else if (message.startsWith("Question:")) {
            // setState(() => _questions.add(message.substring(9)));
            if (_questions.isEmpty) {
              CustomSnackBar.show(context, 'Host has shared new questions.');
            } else {
              CustomSnackBar.show(context, 'More questions have been added.');
            }

            questionsProvider.addQuestion(message.substring(9));
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
              CustomSnackBar.show(context, "Host disconnected.",
                  isSuccess: false);
            });
          } else if (message.startsWith("Removed:")) {
            final question = message.substring(8).trim();
            questionsProvider.removeQuestion(question);
            // setState(() {
            //   _questions.remove(question);
            //   _multipleChoiceQuestions.remove(question);
            //   _selectedAnswers.remove(question);
            //   _confirmedAnswers.remove(question);
            //   print(
            //       'Removed: $question, Remaining: ${_multipleChoiceQuestions.keys}');
            // });
          } else if (message.startsWith("Session started:")) {
            setState(() {
              _messages.add({
                'system': true,
                'text': 'The host has started the session.'
              });
              _currentMode = "Chat";
              _isStarted = true;
            });
          } else {
            messageQueue.add({'text': message, 'isImage': false});
            if (messageQueue.length == 1) processNextMessage();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _messages.add({
                  'system': true,
                  'text': 'Connection error: $error',
                }));
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
            questionsProvider.clearAll();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({
              'system': true,
              'text':
                  'Connection failed: Failed to connect, server does not exist.',
            }));
      }
    }
  }

  Future<void> _saveSessionLog() async {
    try {
      if (_isStarted) {
        final endTime = DateTime.now().toUtc();
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;

        final participantsLog = [
          {
            'nickname': user?.username ?? 'Unknown',
            'connection_duration_seconds': endTime
                .difference(DateTime.now().subtract(Duration(minutes: 1)))
                .inSeconds,
          }
        ];

        final log = {
          'session': {
            'start_time': DateTime.now()
                .subtract(Duration(minutes: 1))
                .toIso8601String(), // Placeholder for actual start time
            'end_time': endTime.toIso8601String(),
            'mode': _currentMode,
          },
          'messages': _messages.map((msg) {
            final newMsg = Map.fromEntries(msg.entries.map((entry) {
              if (entry.value is bool) {
                return MapEntry(entry.key, entry.value);
              } else if (entry.key == 'image' && entry.value is File) {
                return MapEntry(entry.key, (entry.value as File).path);
              }
              return MapEntry(entry.key, entry.value);
            }));
            return newMsg;
          }).toList(),
          'questions': _questions,
          'multiple_choice_questions': _multipleChoiceQuestions,
          'selected_answers': _selectedAnswers,
          'confirmed_answers': _confirmedAnswers.toList(),
          'participants': participantsLog,
        };

        final tempDir = await getTemporaryDirectory();
        final timestamp = endTime
            .toIso8601String()
            .replaceAll(':', '')
            .replaceAll('-', '')
            .split('.')
            .first;
        final file = File('${tempDir.path}/sessionchat_$timestamp.json');
        await file.writeAsString(jsonEncode(log), flush: true);
        debugPrint('Session log saved to ${file.path}');
      }
    } catch (e) {
      debugPrint('Error saving session log: $e');
    }
  }

  void _sendMessage(String message) {
    if (_clientSocket != null) {
      _clientSocket!.add(utf8.encode(message));
      setState(() => _messages.add({'text': message, 'isImage': false}));
      for (int i = 0; i < _messages.length; i++) {
        print({_messages[i]});
      }
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
      setState(() => _messages.add({
            'text': 'Image sent',
            'isImage': true,
            'image': imageFile,
            'isDrawing': false
          }));

      setState(() => _latestImagePath = imageFile.path);
    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  Future<void> _openDrawingCanvas() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final drawing = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => DrawingCanvas()));
    if (drawing != null) {
      File imgFile = File(drawing);
      final base64Image = base64Encode(await imgFile.readAsBytes());
      _clientSocket!.add(utf8.encode('$base64Image\n'));
      _clientSocket!.flush();
      setState(() => _messages.add({
            'nickname': user?.username,
            'image': imgFile,
            'isImage': true,
            'isDrawing': true
          }));
    }

    if (drawing != null) {
      setState(() => _latestDrawingPath = drawing);
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
    CustomSnackBar.show(
        context, "Please wait for the host to start this session.",
        isSuccess: false);
  }

  @override
  void dispose() {
    _clientSocket?.destroy();
    _clientSocket = null;
    _messageController.dispose();
    _manualIpController.dispose();
    _manualPortController.dispose();
    _animationController.dispose();

    // _messages.clear();
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
                  _clientSocket?.destroy();
                  _clientSocket = null;
                  _saveSessionLog();
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
      onWillPop: () async {
        return CustomExitDialog.show(context, usePushReplacement: false);
      },
      child: _changeScreen == "S_CHAT"
          ? Scaffold(
              extendBodyBehindAppBar: true,
              appBar: ChatAppBar(user: user, onBackPressed: _onBackPressed),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF5F5F5),
                      Color(0xFFFFFFFF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(child: _buildModeUI()),
              ),
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
          clientSocket: _clientSocket,
          onStateUpdate: setState,
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
        return PictureUI(
          onPickAndSendImage: _pickAndSendImage,
          imagePath: _latestImagePath,
          messages: _messages,
          fadeAnimation: _fadeAnimation,
          messageController: _messageController,
          isStarted: _isStarted,
          onWaitSnackBar: _showHostWaitSnackBar,
          questions: _questions,
          multipleChoiceQuestions: _multipleChoiceQuestions,
          selectedAnswers: _selectedAnswers,
          confirmedAnswers: _confirmedAnswers,
          clientSocket: _clientSocket,
          onStateUpdate: setState,
        );
      case "Drawing":
        return DrawingUI(
          onOpenDrawingCanvas: _openDrawingCanvas,
          imagePath: _latestDrawingPath,
          messages: _messages,
          fadeAnimation: _fadeAnimation,
          messageController: _messageController,
          isStarted: _isStarted,
          onWaitSnackBar: _showHostWaitSnackBar,
          clientSocket: _clientSocket,
          onStateUpdate: setState,
        );
      default:
        return Center(
            child: Text("Unknown mode", style: TextStyle(color: Colors.white)));
    }
  }
}
