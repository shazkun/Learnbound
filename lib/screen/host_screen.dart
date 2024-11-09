import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Learnbound/participants_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  List<String> clients = [];
  List<Map<String, dynamic>> messages = [];
  List<String> stickyQuestions = [];
  List<File> drawings = [];
  ServerSocket? serverSocket;
  final TextEditingController _questionController =
      TextEditingController(); // Controller for TextField
// To track emoji picker visibility
  Map<Socket, String> clientNicknames = {}; // Socket to nickname mapping
  List<Socket> connectedClients = [];
  String? selectedMode;
  Map<String, int> participants = {};

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address; // Return the first non-loopback IPv4 address
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null; // Return null if no valid address is found
  }

  void _startServer() async {
    try {
      // Bind the RawDatagramSocket to any IPv4 address on port 4040
      final socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4040);
      socket.broadcastEnabled = true;

      final localIp = await getLocalIp();

      // Create the broadcast message with the local IP address
      final message = utf8.encode('$localIp');

      // Set up a timer to send the broadcast message every second
      Timer.periodic(Duration(seconds: 1), (timer) {
        try {
          socket.send(
            message, 
            InternetAddress('255.255.255.255'), 
            4040,
          );
        } catch (e) {
          print('Error sending message: $e');
        }
            });
      // socket.close();
    } catch (error) {
      print('Error occurred while running server: $error');
    }
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
    final localIp = await getLocalIp();
    setState(() {
      messages.add({
        'text': 'Server started at $localIp:${serverSocket!.port}',
        'nickname': 'System',
        'isImage': false
      });
    });

    serverSocket!.listen((Socket client) {
      setState(() {
        clients.add('${client.remoteAddress.address}:${client.remotePort}');
        connectedClients.add(client); // Add to the list of connected clients
      });
      client.listen((data) {
        String message = String.fromCharCodes(data).trim();

        // Check if this is the initial Nickname message
        if (message.startsWith("Nickname:")) {
          String nickname =
              message.substring(9); // Extract nickname after "Nickname:"
          clientNicknames[client] = nickname; // Store nickname for this client
          setState(() {
            messages.add({
              'text': '$nickname connected.',
              'nickname': 'System',
              'isImage': false
            });
          });
        } else if (message.startsWith("Drawing:")) {
          String drawingPath = message.substring(8);
          File drawingFile = File(drawingPath);
          print('Drawing Path: $drawingPath');
          if (drawingFile.existsSync()) {
            setState(() {
              drawings.add(drawingFile);
              messages.add({
                'text': 'Drawing received',
                'nickname': clientNicknames[client],
                'isImage': true,
                'image': drawingFile // Add drawing file to message map
              });
            });
          } else {
            setState(() {
              messages.add({
                'text': 'Failed to load drawing: file not found',
                'nickname': clientNicknames[client],
                'isImage': false
              });
            });
          }
        } else if (message.startsWith("Question:")) {
          String question = message.substring(9);
          setState(() {
            messages.add({
              'text': question,
              'nickname': clientNicknames[client],
              'isImage': false
            });
          });
        } else {
          setState(() {
            messages.add({
              'text': message,
              'nickname': clientNicknames[client],
              'isImage': false
            });
          });
        }
        if (message.startsWith("Image:")) {
          // Extract base64 data from the message
          String base64Image =
              message.substring(6).trim(); // <-- Remove "Image:" prefix
          base64Image =
              addBase64Padding(base64Image); // <-- Add padding if needed
          Uint8List imageBytes = base64Decode(base64Image); // <-- 
          setState(() {
            messages.add({
              'isImage': true,
              'imageBytes': imageBytes,
            });
          });
        }
      }, onDone: () {
        setState(() {
          String nickname =
              clientNicknames[client] ?? client.remoteAddress.address;
          messages.add({
            'text': '$nickname disconnected.',
            'nickname': 'System',
            'isImage': false
          });
          clients
              .remove('${client.remoteAddress.address}:${client.remotePort}');
          clientNicknames.remove(client);
        });
      });
    });
  }

  String addBase64Padding(String base64String) {
    int mod = base64String.length % 4;
    if (mod > 0) {
      return base64String + '=' * (4 - mod); // Adds '=' padding if necessary
    }
    return base64String;
  }

  void _sendStickyQuestion(String question) {
    for (var client in connectedClients) {
      // Iterate over connected clients
      client.write("Question:$question"); // Send the sticky question message
    }
    setState(() {
      stickyQuestions.add(question); // Add sticky question to the list
    });
  }

  void _removeStickyQuestion(String question) {
    for (var client in connectedClients) {
      // Iterate over connected clients
      client.write("Removed:$question"); // Send the sticky question message
    }
    setState(() {
      stickyQuestions.remove(question);
    });
  }

  @override
  void dispose() {
    serverSocket?.close();
    _questionController.dispose();
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
    return shouldPop ?? false; // Return false if the user cancels, true if they confirm
  }

  void _openParticipantsList() {
    // Navigate to the ParticipantsList screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantsList(participants: participants),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Screen'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            bool shouldExit = await _onBackPressed();
            if (shouldExit) Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person), // Participants list icon
            onPressed: _openParticipantsList, // Open participants list
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Select Mode'),
                    content: DropdownButton<String>(
                      value: selectedMode,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMode = newValue!;
                          for (var client in connectedClients) {
                            client.write("Mode:$selectedMode");
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      items: <String>['Chat', 'Picture', 'Drawing']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
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
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData = messages[index];
                  return ListTile(
                    leading: Icon(Icons.account_circle),
                    title: messageData['isImage'] && messageData['image'] != null
                        ? Image.file(
                            messageData['image'],
                            errorBuilder: (context, error, stackTrace) => Text(
                              'Image not found',
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                        : Text(messageData['text'] ?? 'Message not available'),
                  );
                },
              ),
            ),
            if (stickyQuestions.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: stickyQuestions
                      .map((question) => ListTile(
                            title: Text(question),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _removeStickyQuestion(question),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: "Type a question",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_questionController.text.isNotEmpty) {
                      _sendStickyQuestion(_questionController.text);
                      _questionController.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}