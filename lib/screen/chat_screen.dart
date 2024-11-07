import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Emoji support
import '../drawing_canvas.dart'; // Drawing canvas import
import '../server_list.dart'; // ServerList widget
import 'package:Learnbound/database/database_helper.dart'; // Database helper to fetch profile picture
import 'package:Learnbound/screen/host_screen.dart';

class ChatScreen extends StatefulWidget {
  final String nickname;

  const ChatScreen({super.key, required this.nickname});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController manualIpController = TextEditingController();
  final TextEditingController manualPortController = TextEditingController();
  Socket? clientSocket;
  List<Map<String, dynamic>> messages = []; // Store both messages and metadata
  List<File> images = []; // Store images to display in chat
  List<String> questions = []; // Store questions from host
  bool isEmojiVisible = false; // Toggle emoji visibility
  bool isAutoJoinEnabled = false; // Auto join toggle
  String? profilePicture; // Store profile picture
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture(); // Fetch the profile picture on init
  }

  // Function to load profile picture from the database
  Future<void> _loadProfilePicture() async {
    var db = DatabaseHelper();

    var user = await db.getUser(widget.nickname);
    if (user != null && user['profile_picture'] != null) {
      setState(() {
        profilePicture = user['profile_picture']; // Set the profile picture URL
      });
    }
  }

  void _connectToServer(String serverInfo) async {
    try {
      final parts = serverInfo.split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);

      clientSocket = await Socket.connect(ip, port);

      // Send nickname as the first message to the server
      clientSocket!.write("Nickname:${widget.nickname}");

      setState(() {
        messages
            .add({'text': 'Connected to server $ip:$port', 'isImage': false});
      });

      // Listen for incoming messages
      clientSocket!.listen((data) {
        final message = String.fromCharCodes(data).trim();

        if (message.startsWith("Question:")) {
          final question = message.substring(9);
          setState(() {
            questions.add(question);
          });
        } else {
          setState(() {
            messages.add({'text': message, 'isImage': false});
          });
        }
        if (message.startsWith("Removed:")) {
          final question = message.substring(8);
          setState(() {
            questions.remove(question);
          });
        } else {
          setState(() {
            messages.remove({'text': message, 'isImage': false});
          });
        }
      }, onError: (error) {
        setState(() {
          messages.add({'text': 'Connection error: $error', 'isImage': false});
        });
      }, onDone: () {
        setState(() {
          messages.add({'text': 'Connection closed', 'isImage': false});
        });
      });
    } catch (e) {
      setState(() {
        messages.add({'text': 'Connection failed: $e', 'isImage': false});
      });
    }
  }

  void _sendMessage(String message) {
    if (clientSocket != null) {
      clientSocket!.write(message);
      setState(() {
        messages.add({'text': message, 'isImage': false});
      });
      messageController.clear();
    }
  }

  // Function to send images in chat
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Preview Image'),
            content: Image.file(imageFile),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    messages.add({'image': imageFile, 'isImage': true});
                  });
                  Navigator.pop(context);
                  clientSocket!.write(
                      "Drawing:${pickedFile.path}"); // Send image metadata to the host
                
                },
                child: Text('Send'),
              ),
            ],
          );
        },
      );
    }
  }
  Future<void> _pickAndSendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = imageFile.readAsBytesSync();
      String base64Image = base64UrlEncode(imageBytes);

      clientSocket?.write("Image:$base64Image");
      setState(() {
        messages.add({'text': 'Image sent', 'isImage': true, 'image': imageFile});
      });
    }
  }

  // Function to open the drawing canvas
  Future<void> _openDrawingCanvas() async {
    final drawing = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrawingCanvas()),
    );
    if (drawing != null) {
      setState(() {
        messages
            .add({'image': drawing, 'isImage': true}); // Add drawing as image
      });
      // Send image metadata to the host
    }
  }

  // Show server list modal for auto-join
  Future<void> _showServerList() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ServerList(
          onSelectServer: (serverInfo) {
            Navigator.pop(context); // Close the dialog
            int port = 4040;
            _connectToServer('$serverInfo:$port'); // Auto-join selected server
          },
        );
      },
    );
  }

  // Manual connection to the server
  void _manualConnect() {
    String ip = manualIpController.text;
    // int port = int.tryParse(manualPortController.text) ?? 0;
    int port = 4040;
    _connectToServer('$ip:$port');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              profilePicture != null
                  ? CircleAvatar(
                      backgroundImage: FileImage(File(profilePicture!)))
                  : Icon(Icons.account_circle),
              SizedBox(width: 10),
              Text(widget.nickname),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.list_alt, color: Colors.grey),
              onPressed: _showServerList,
            ),
            IconButton(
              icon: Icon(Icons.connected_tv_rounded, color: Colors.grey),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Manual Connect"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: manualIpController,
                            decoration: InputDecoration(labelText: 'Server IP'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _manualConnect();
                          },
                          child: Text('Connect'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD3A97D).withOpacity(1),
                Color(0xFFEBE1C8).withOpacity(1),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            children: [
              // Show sticky questions if any
              if (questions.isNotEmpty)
                SizedBox(
                  height: 10,
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.0), // Add padding to left and right
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Set background color to white
                    borderRadius:
                        BorderRadius.circular(12), // Round the corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // Add a shadow for depth
                      ),
                    ],
                  ),
                  child: Column(
                    children: questions.map((question) {
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rounds each ListTile
                        ),
                        tileColor:
                            Colors.white, // Keep each ListTile background white
                        title: Text(
                          question,
                          style: TextStyle(color: Colors.blue),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // List of messages
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    return ListTile(
                      leading: profilePicture != null
                          ? CircleAvatar(
                              backgroundImage: FileImage(File(profilePicture!)))
                          : Icon(Icons.account_circle),
                      title: messageData['isImage']
                          ? Image.file(messageData['image'])
                          : Text(messageData['text']),
                    );
                  },
                ),
              ),

              // Message input and actions
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions),
                    onPressed: () {
                      setState(() {
                        isEmojiVisible = !isEmojiVisible;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: _pickAndSendImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.brush),
                    onPressed: _openDrawingCanvas,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: "Type a message",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(messageController.text),
                  ),
                ],
              ),

              if (isEmojiVisible)
                EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    messageController.text += emoji.emoji;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
