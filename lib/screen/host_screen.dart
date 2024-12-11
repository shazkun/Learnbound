import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Learnbound/database/settings_db.dart';
import 'package:Learnbound/server.dart';
import 'package:flutter/material.dart';

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
  final SettingsDb sdb = SettingsDb();
  final TextEditingController _questionController =
      TextEditingController(); // Controller for TextField
  Map<Socket, String> clientNicknames = {}; // Socket to nickname mapping
  List<Socket> connectedClients = [];

  Map<String, int> participants = {};
  String? receivedImageBase64;
  final StringBuffer dataBuffer =
      StringBuffer(); // Buffer to accumulate incoming data
  final BroadcastServer broadcast = BroadcastServer();
  String lobby = "lobby";

  String selectedMode = "Chat";
  @override
  void initState() {
    super.initState();
    _startServer();
    broadcast.startBroadcast();
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
    serverSocket = await ServerSocket.bind('0.0.0.0', 4040);

    final localIp = await getLocalIp();
    if (mounted) {
      setState(() {
        messages.add({
          'text': 'Server started at $localIp:${serverSocket!.port}',
          'nickname': 'System',
          'isImage': false
        });
      });
    }

    serverSocket!.listen((Socket client) {
      setState(() {
        clients.add('${client.remoteAddress.address}:${client.remotePort}');
        connectedClients.add(client); // Add to the list of connected clients
      });
      client.listen((data) async {
        String message = String.fromCharCodes(data).trim();

        if (message.startsWith("Nickname:")) {
          String nickname =
              message.substring(9); // Extract nickname after "Nickname:"
          clientNicknames[client] = nickname; // Store nickname for this client
          participants[nickname] = 0;
          setState(() {
            messages.add({
              'text': '$nickname connected.',
              'nickname': 'System',
              'isImage': false
            });
          });
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
          if (selectedMode == "Picture" || selectedMode == "Drawing") {
            dataBuffer.write(utf8.decode(data));

            if (dataBuffer.toString().endsWith('\n')) {
              String completeData = dataBuffer.toString().trim();

              // Update the UI with the received image
              setState(() {
                receivedImageBase64 = completeData;
                messages.add({
                  'nickname': clientNicknames[client],
                  'image': receivedImageBase64,
                  'isImage': true
                });
              });

              // Clear the buffer for future data
              dataBuffer.clear();
            }
          }
          if (selectedMode == "Chat") {
            setState(() {
              String nickname =
                  clientNicknames[client] ?? client.remoteAddress.address;
              messages.add({
                'text': ' $message',
                'nickname': nickname,
                'isImage': false
              });
            });
          }
        }
      }, onDone: () {
        if (mounted) {
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
            participants.remove(nickname);
          });
        }
      });
    });
  }

  void _sendStickyQuestion(String question) {
    for (var client in connectedClients) {
      client.write("Question:$question");
    }
    setState(() {
      stickyQuestions.add(question);
    });
  }

  void _removeStickyQuestion(String question) {
    for (var client in connectedClients) {
      client.write("Removed:$question");
    }
    setState(() {
      stickyQuestions.remove(question);
    });
  }

  void startSession() {
    for (var client in connectedClients) {
      client.write("Session started:"); // Send the sticky question message
    }
  }

  @override
  void dispose() {
    if (connectedClients.isNotEmpty) {
      for (var client in connectedClients) {
        // Send the message to each connected client
        client.write(
            "Host Disconnected"); // Notify the client about the host disconnection
      }
    }

    broadcast.stopBroadcast();
    serverSocket?.close();
    _questionController.clear();
    stickyQuestions.clear();
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
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Exit'),
          ),
        ],
      ),
    );
    return shouldPop ??
        false; // Return false if the user cancels, true if they confirm
  }

  // void _addPoints(String participant, int points) {
  //   setState(() {
  //     participants[participant] = (participants[participant] ?? 0) + points;
  //     messages.add({
  //       'text': '$participant received $points points!',
  //       'nickname': 'System',
  //       'isImage': false
  //     });
  //   });
  // }

  // // Decrement points for a participant
  // void _removePoints(String participant, int points) {
  //   setState(() {
  //     participants[participant] = (participants[participant] ?? 0) - points;
  //     if (participants[participant]! < 0) participants[participant] = 0;
  //     messages.add({
  //       'text': '$participant lost $points points!',
  //       'nickname': 'System',
  //       'isImage': false
  //     });
  //   });
  // }

  // // Reset points for all participants
  // void _resetPoints() {
  //   setState(() {
  //     participants.updateAll((key, value) => 0);
  //     messages.add({
  //       'text': 'All points have been reset.',
  //       'nickname': 'System',
  //       'isImage': false
  //     });
  //   });
  // }

  // // Method to show a dialog with point management options
  // void _showPointManagementDialog(String participant) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Manage Points for $participant'),
  //         actions: [
  //           TextButton(
  //             child: Text('Add 10 Points'),
  //             onPressed: () {
  //               _addPoints(participant, 10);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Remove 10 Points'),
  //             onPressed: () {
  //               _removePoints(participant, 10);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Reset Points'),
  //             onPressed: () {
  //               _resetPoints();
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // // Button to open the ParticipantsList with points
  // void _openParticipantsList() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ParticipantsList(
  //         participants: participants,
  //         onManagePoints: _showPointManagementDialog, // Pass the callback
  //       ),
  //     ),
  //   );
  // }

  Widget _buildImageThumbnail(String base64Image) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Image.memory(
              base64Decode(base64Image),
              errorBuilder: (context, error, stackTrace) =>
                  Text('Image not found', style: TextStyle(color: Colors.red)),
            ),
          ),
        );
      },
      child: Image.memory(
        base64Decode(base64Image),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMessagesView() {
    if (selectedMode == "Chat") {
      return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final messageData = messages[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageData['nickname'] ?? 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                if (messageData['text'] != null) Text(messageData['text']),
                if (messageData['isImage'] == true &&
                    messageData['image'] != null)
                  _buildImageThumbnail(messageData['image']),
              ],
            ),
          );
        },
      );
    } else {
      return SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adjust the number of columns based on screen width
            int crossAxisCount =
                (constraints.maxWidth / 150).floor().clamp(2, 4);

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 0.75,
              ),
              itemCount: messages
                  .where(
                      (msg) => msg['isImage'] == true && msg['image'] != null)
                  .length,
              itemBuilder: (context, index) {
                final messageData = messages
                    .where(
                        (msg) => msg['isImage'] == true && msg['image'] != null)
                    .toList()[index];

                return Container(
                  margin: EdgeInsets.all(4.0),
                  padding: EdgeInsets.all(4.0),
                  child: Column(
                    children: [
                      Text(
                        messageData['nickname'] ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12.0), // Rounded corners
                        child: _buildImageThumbnail(messageData['image']),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lobby == "start") {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Mode $selectedMode'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              serverSocket?.close();
              broadcast.stopBroadcast();
              bool shouldExit = await _onBackPressed();
              if (shouldExit) Navigator.of(context).pop();
            },
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.person),
            //   onPressed: _openParticipantsList,
            // ),
            IconButton(
              icon:
                  Icon(Icons.settings_accessibility_sharp, color: Colors.black),
              onPressed: () {
                if (participants.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("please wait others to join...")),
                  );

                  // You can replace this with a widget or other logic
                } else {
                  // Show the dialog if the condition is not met
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
                              messages.clear();
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
                }
              },
            )
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
              Expanded(child: _buildMessagesView()),

              // Sticky questions section
              if (stickyQuestions.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: stickyQuestions
                        .map((question) => ListTile(
                              title: Text(question),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () =>
                                    _removeStickyQuestion(question),
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
                        hintText: "Ask something...",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(color: Colors.black, width: 2),
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
                    onPressed: () {
                      if (_questionController.text.isNotEmpty &&
                          participants.isNotEmpty) {
                        _sendStickyQuestion(_questionController.text);
                        _questionController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Participants list is empty')));
                      }
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      );
    } else if (lobby == "lobby") {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Participants'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              
             
              bool shouldExit = await _onBackPressed();
              if (shouldExit) Navigator.of(context).pop();
            },
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    String participant = participants.keys.elementAt(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Card background color
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.grey.withOpacity(0.2), // Subtle shadow
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              '${index + 1}', // Counter as leading icon
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            participant,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {}, // Handle participant tap
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () {
                      int minParticipants = 1;
                      if (participants.length >= minParticipants && mounted) {
                        setState(() {
                          broadcast.stopBroadcast();
                          startSession();
                          lobby = "start";
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Minimum number of participants required to join: $minParticipants.")),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'START',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
    }

    return Scaffold();
  }
}
