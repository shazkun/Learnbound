import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Emoji support
import '../drawing_canvas.dart'; // Drawing canvas import
import '../server_list.dart'; // ServerList widget
import 'package:Learnbound/database/database_helper.dart'; // Database helper to fetch profile picture

class ChatScreen extends StatefulWidget {
  final String nickname;
  final int? uid;

  const ChatScreen({super.key, required this.nickname, required this.uid});

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
  final db = DatabaseHelper();

  String currentMode = "Chat"; // Default mode

  @override
  void initState() {
    super.initState();
    _loadProfilePicture(); // Fetch the profile picture on init
  }

  // Function to load profile picture from the database
  Future<void> _loadProfilePicture() async {
    var db = DatabaseHelper();
    String? userpf = await db.getProfilePicture(widget.uid ?? 0);
    setState(() {
      profilePicture = userpf; // Set the profile picture URL
    });
  }

  bool isConnected = false; // Flag to track connection status

  void connectToServer(String serverInfo) async {
    // if (isConnected) {
    //   setState(() {
    //     messages.add({'text': 'Already connected to a server.', 'isImage': false});
    //   });
    //   return; // Exit early if already connected
    // }
    try {
      final parts = serverInfo.split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);

      clientSocket = await Socket.connect(ip, port);

      // Set connection status to true
      isConnected = true;

      // Send nickname as the first message to the server
      clientSocket!.write("Nickname:${widget.nickname}");

      setState(() {
        messages
            .add({'text': 'Connected to server $ip:$port', 'isImage': false});
      });

      // Listen for incoming messages
      clientSocket!.listen((data) {
        final message = String.fromCharCodes(data).trim();

        if (message.startsWith("Mode:")) {
          final mode = message.substring(5);
          setState(() {
            currentMode = mode;
          });
        } else if (message.startsWith("Question:")) {
          final question = message.substring(9);
          setState(() {
            questions.add(question);
          });
        } else if (message.startsWith("Host Disconnected")) {
          if (mounted) {
            setState(() {
              if (questions.isNotEmpty) {
                questions.clear();
              }
              messages.add({
                'system': true,
                'text': 'Host disconnected.',
              });
            });
          }
        } else if (message.startsWith("Removed:")) {
          final question = message.substring(8);
          setState(() {
            questions.remove(question);
          });
        } else {
          setState(() {
            messages.add({'text': message, 'isImage': false});
          });
        }
      }, onError: (error) {
        setState(() {
          messages.add({'text': 'Connection error: $error', 'isImage': false});
        });
      }, onDone: () {
        // Reset connection status when the connection is closed
        if (mounted) {
          setState(() {
            messages.add({'text': 'Connection closed', 'isImage': false});
            questions.clear();
            isConnected = false;
          });
        }
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
  Future<void> _pickAndSendImage() async {
    // Pick an image from the gallery
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await File(pickedFile.path).readAsBytes();
      File imageFile = File(pickedFile.path);

      // Convert the image bytes to base64
      String base64Image = base64Encode(imageBytes);

      // Send the base64 image string with an end marker (newline)

      clientSocket?.add(utf8.encode('$base64Image\n'));
      clientSocket?.flush();

      setState(() {
        messages
            .add({'text': 'Image sent', 'isImage': true, 'image': imageFile});
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
      File imgFile = File(drawing);
      final imageBytes = await File(drawing).readAsBytes();

      // Convert the image bytes to base64
      String base64Image = base64Encode(imageBytes);

      // Send the base64 image string with an end marker (newline)
      clientSocket!.add(utf8.encode('$base64Image\n'));
      clientSocket!.flush();
      setState(() {
        messages.add({
          'nickname': widget.nickname,
          'image': imgFile,
          'isImage': true
        }); // Add drawing as image
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
            connectToServer('$serverInfo:$port'); // Auto-join selected server
          },
        );
      },
    );
  }

  // Manual connection to the server
  void _manualConnect() {
    String ip = manualIpController.text;
    int port = 4040;
    connectToServer('$ip:$port');
  }

  Future<bool> _onBackPressed() async {
    // Show a confirmation dialog when the user tries to leave the screen
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to exit?'),
        content: Text('Any ongoing connections will be lost.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit'),
          ),
        ],
      ),
    );
    return shouldPop ??
        false; // Return false if the user cancels, true if they confirm
  }

  @override
  void dispose() {
    clientSocket!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              // Handling custom back press
              bool shouldExit = await _onBackPressed();
              if (shouldExit) {
                Navigator.of(context).pop(); // Proceed with navigation pop
              }
            },
          ),
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
              SizedBox(height: 20),
              questions.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0), // Padding on left and right
                      child: Container(
                        padding:
                            EdgeInsets.all(8), // Padding inside the container
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                              255, 129, 109, 109), // Transparent background
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey
                                  .withOpacity(0.3), // Soft shadow color
                              spreadRadius: 2, // Shadow spread
                              blurRadius: 5, // Shadow blur
                              offset: Offset(0, 3), // Shadow offset
                            ),
                          ],
                        ),
                        child: Column(
                          children: questions.map((question) {
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8), // Rounded corners for ListTile
                              ),
                              tileColor: Colors
                                  .white, // White background for each ListTile
                              title: Text(
                                question,
                                style: TextStyle(
                                    color: Colors.blue), // Blue text color
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  : Container(), // Empty container for when `questions` is empty, effectively showing nothing

              // List of messages
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];

                    // Check if the message is a system message safely
                    bool isSystemMessage = messageData['system'] ?? false;

                    return Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal:
                              12.0), // Optional: Adds space between the list items
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12.0), // Rounded corners
                        border: Border.all(
                          color: isSystemMessage
                              ? Colors.blue
                              : Colors
                                  .grey, // Different border color for system messages
                          width: 2.0,
                        ),
                      ),
                      child: ListTile(
                        leading: isSystemMessage
                            ? Icon(Icons
                                .info_rounded) // Show system icon for system messages
                            : (profilePicture != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        FileImage(File(profilePicture!)))
                                : Icon(Icons
                                    .account_circle)), // Show default icon if no profile picture
                        title: messageData['isImage'] == true
                            ? (messageData['image'] != null
                                ? Image.file(messageData[
                                    'image']) // Show image if it's not null
                                : SizedBox()) // Empty widget if image is null
                            : Text(messageData['text'] ??
                                ''), // Show text, default to empty string if null
                      ),
                    );
                  },
                ),
              ),

              // Message input and actions based on mode
              if (currentMode == "Chat")
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          labelText: "Type a question",
                          hintText: "Ask something...",
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide:
                                BorderSide(color: Colors.grey[400]!, width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () => _sendMessage(messageController.text),
                    ),
                  ],
                ),
              SizedBox(
                height: 10,
              ),
              if (currentMode == "Picture")
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickAndSendImage,
                ),
              if (currentMode == "Drawing")
                IconButton(
                  icon: Icon(Icons.brush),
                  onPressed: _openDrawingCanvas,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
