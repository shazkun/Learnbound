import 'dart:convert';
import 'dart:io';

import 'package:Learnbound/database/database_helper.dart'; // Database helper to fetch profile picture
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../drawing_canvas.dart'; // Drawing canvas import
import '../server_list.dart'; // ServerList widget

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

  String currentMode = "LOBBY"; // Default mode
  bool isStarted = false;

  String changeScreen = "S_LIST";

  @override
  void initState() {
    super.initState();
    _loadProfilePicture(); // Fetch the profile picture on init
    messages.add({
      'system': true,
      'text': 'Please wait for the host to start this session.'
    });
  }

  // Function to load profile picture from the database
  Future<void> _loadProfilePicture() async {
    var db = DatabaseHelper();
    String? userProfile = await db.getProfilePicture(widget.uid ?? 0);
    setState(() {
      profilePicture = userProfile; // Set the profile picture URL
    });
  }

  void connectToServer(String serverInfo) async {
    changeScreen = "S_CHAT";
    try {
      final parts = serverInfo.split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);

      // Start the connection attempt and set a timeout of 3 seconds
      clientSocket =
          await Socket.connect(ip, port).timeout(Duration(seconds: 3));

      // Send nickname as the first message to the server
      clientSocket!.write("Nickname:${widget.nickname}");

      if (!mounted) return;
      setState(() {
        messages
            .add({'text': 'Connected to server $ip:$port', 'isImage': false});
        currentMode = "Chat";
      });

      // Listen for incoming messages
      clientSocket!.listen((data) {
        final message = String.fromCharCodes(data).trim();
        if (!mounted) return;
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
          setState(() {
            if (questions.isNotEmpty) {
              questions.clear();
            }
            changeScreen = "S_LIST";
            isStarted = false;
            messages.add({
              'system': true,
              'text': 'Host disconnected.',
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Host disconnected.")),
            );
          });
        } else if (message.startsWith("Removed:")) {
          final question = message.substring(8);

          setState(() {
            questions.remove(question);
          });
        } else if (message.startsWith("Session started:")) {
          setState(() {
            messages.add(
                {'system': true, 'text': 'The host has started the session.'});
            currentMode = "Chat";
            isStarted = true;
          });
        } else {
          setState(() {
            messages.add({'text': message, 'isImage': false});
          });
        }
      }, onError: (error) {
        setState(() {
          messages.add({'system': true, 'text': 'Connection error: $error'});
        });
      }, onDone: () {
        // Reset connection status when the connection is closed

        setState(() {
          messages.add({'system': true, 'text': 'Connection closed'});
          questions.clear();
        });
      });
    } catch (e) {
      setState(() {
        messages.add({
          'text': 'Connection failed: Failed to connect server does not exist.',
          'system': true
        });
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
    try {
      // Pick an image from the gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return; // If no image is selected, exit

      final imageFile = File(pickedFile.path);

      // Convert the image bytes to base64
      final base64Image = base64Encode(await imageFile.readAsBytes());

      // Send the base64 image string with an end marker (newline)
      if (clientSocket != null) {
        clientSocket!.add(utf8.encode('$base64Image\n'));
        await clientSocket!.flush();
      }

      // Update the UI with the sent image
      setState(() {
        messages.add({
          'text': 'Image sent',
          'isImage': true,
          'image': imageFile,
        });
      });
    } catch (e) {
      // Handle errors (e.g., file read or socket issues)
      debugPrint('Error sending image: $e');
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

  @override
  void dispose() {
    clientSocket?.close();
    super.dispose();
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
  Widget build(BuildContext context) {
    if (changeScreen == "S_CHAT") {
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
                if (shouldExit && mounted) {
                  Navigator.of(context).pop(); // Proceed with navigation pop
                }
              },
            ),
            title: Row(
              children: [
                profilePicture != null && profilePicture!.isNotEmpty ||
                        profilePicture == " "
                    ? CircleAvatar(
                        backgroundImage: FileImage(File(profilePicture!)))
                    : Icon(Icons.account_circle),
                SizedBox(width: 10),
                Text(widget.nickname),
              ],
            ),
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
                                ? Colors.grey
                                : Colors
                                    .grey, // Different border color for system messages
                            width: 2.0,
                          ),
                        ),
                        child: ListTile(
                          leading: isSystemMessage
                              ? Icon(Icons
                                  .info_rounded) // Show system icon for system messages
                              : (profilePicture != null &&
                                          profilePicture!.isNotEmpty ||
                                      profilePicture == " "
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
                if (currentMode == "LOBBY")
                  Center(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.list_alt),
                            onPressed: _showServerList,
                          ),
                          // IconButton(
                          //   icon: Icon(Icons.connected_tv_rounded,
                          //       color: Colors.black),
                          //   onPressed: () {
                          //     showDialog(
                          //       context: context,
                          //       builder: (context) {
                          //         return AlertDialog(
                          //           title: Text("Manual Connect"),
                          //           content: Column(
                          //             mainAxisSize: MainAxisSize.min,
                          //             children: [
                          //               TextField(
                          //                 controller: manualIpController,
                          //                 decoration: InputDecoration(
                          //                     labelText: 'Server IP'),
                          //               ),
                          //             ],
                          //           ),
                          //           actions: [
                          //             TextButton(
                          //               onPressed: () {
                          //                 Navigator.pop(context);
                          //               },
                          //               child: Text('Cancel'),
                          //             ),
                          //             ElevatedButton(
                          //               onPressed: () {
                          //                 Navigator.pop(context);
                          //                 _manualConnect();
                          //               },
                          //               child: Text('Connect'),
                          //             ),
                          //           ],
                          //         );
                          //       },
                          //     );
                          //   },
                          // ),
                        ]),
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
                              borderSide: BorderSide(
                                  color: Colors.grey[400]!, width: 1),
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
                        onPressed: () {
                          if (isStarted) {
                            _sendMessage(messageController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Please wait for the host to start this session.")),
                            );
                          }
                        },
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
    } else if (changeScreen == "S_LIST") {
      return ServerList(
        onSelectServer: (serverInfo) {
          int port = 4040;
          connectToServer('$serverInfo:$port'); // Auto-join selected server
        },
      );
    }
    return Scaffold();
  }
}
