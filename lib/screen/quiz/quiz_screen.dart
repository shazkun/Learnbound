import 'dart:convert';
import 'dart:io';

import 'package:learnbound/screen/quiz/quiz_user.dart';
import 'package:learnbound/util/server.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart' as windows_picker;
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:path_provider/path_provider.dart';

import 'question_form.dart';
import 'question_list.dart';
import 'question_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  BroadcastServer? broadcastServer;
  bool isBroadcasting = false;
  ServerSocket? serverSocket;

  @override
  void initState() {
    super.initState();
    initializeBroadcastServer();
    initializeServerSocket();
  }

  void initializeBroadcastServer() {
    broadcastServer = BroadcastServer();
    broadcastServer!.setBroadcastName('QUZZIZ');
  }

  Future<void> initializeServerSocket() async {
    if (serverSocket != null) {
      print('Server socket is already initialized.');
      return;
    }

    try {
      serverSocket =
          await ServerSocket.bind(InternetAddress.anyIPv4, 4041, shared: true);
      serverSocket!.listen(
        (Socket client) async {
          try {
            final jsonQuestions = questions.isNotEmpty
                ? questions.map((q) => q.toJson()).toList()
                : [];
            final jsonString = jsonEncode(jsonQuestions);
            print('Server sending JSON: $jsonString');
            client.write(jsonString);
            await client.flush();
            await Future.delayed(Duration(milliseconds: 100));
            await client.close();
          } catch (e) {
            print('Error sending data to client: $e');
            await client.close();
          }
        },
        onError: (e) {
          print('Server socket error: $e');
        },
        onDone: () {
          serverSocket?.close();
        },
      );
      print('Server socket listening on port 4041');
    } catch (e) {
      print('Error initializing server socket: $e');
    }
  }

  Future<void> toggleBroadcast() async {
    if (isBroadcasting) {
      broadcastServer?.stopBroadcast();
      setState(() => isBroadcasting = false);
    } else {
      await broadcastServer?.startBroadcast();
      setState(() => isBroadcasting = true);
    }
  }

  void randomizeQuestions() {
    setState(() {
      questions.shuffle(); // Shuffle the list of questions
    });
  }

  Future<String> getPresetsDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final presetDir = Directory('${dir.path}/quiz_presets');
    if (!presetDir.existsSync()) {
      presetDir.createSync(recursive: true);
    }
    return presetDir.path;
  }

  Future<void> savePresetToFolder() async {
    try {
      final jsonQuestions = questions.map((q) => q.toJson()).toList();
      final jsonString = jsonEncode(jsonQuestions);

      final path = await getPresetsDirectoryPath();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$path/preset_$timestamp.json');

      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset saved: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preset: $e')),
      );
    }
  }

  Future<List<FileSystemEntity>> getAllPresets() async {
    final path = await getPresetsDirectoryPath();
    final dir = Directory(path);
    final files =
        dir.listSync().where((f) => f.path.endsWith('.json')).toList();
    return files;
  }

  void _showLoadPresetDialog() async {
    final files = await getAllPresets();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select a Preset'),
        content: SizedBox(
          width: double.maxFinite,
          child: files.isEmpty
              ? Text('No presets found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final fileName = file.path.split('/').last;
                    return ListTile(
                      title: Text(fileName),
                      onTap: () async {
                        Navigator.pop(context);
                        final content = await File(file.path).readAsString();
                        final jsonData = jsonDecode(content);
                        if (jsonData is List) {
                          final loadedQuestions = jsonData
                              .map((e) => Question.fromJson(e))
                              .toList();
                          setState(() {
                            questions = loadedQuestions;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Preset loaded successfully')),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> importQuestions() async {
    try {
      String? filePath;
      if (Platform.isWindows) {
        final file = windows_picker.OpenFilePicker()
          ..filterSpecification = {'JSON and Text Files': '*.json;*.txt'}
          ..title = 'Select a quiz file';
        final result = file.getFile();
        if (result != null) filePath = result.path;
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json', 'txt'],
        );
        if (result != null) filePath = result.files.single.path;
      }

      if (filePath != null) {
        File file = File(filePath);
        String content = await file.readAsString();
        if (filePath.endsWith('.json')) {
          List<dynamic> jsonData = jsonDecode(content);
          setState(() {
            questions = jsonData.map((e) => Question.fromJson(e)).toList();
          });
        } else {
          List<String> lines = content.split('\n');
          setState(() {
            questions = lines
                .where((line) => line.contains('|'))
                .map((line) {
                  var parts = line.split('|');
                  if (parts.length < 3) return null;
                  if (parts[1] == 'short') {
                    return Question(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: parts[0],
                      type: QuestionType.shortAnswer,
                      correctAnswer: parts[2],
                    );
                  } else {
                    return Question(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: parts[0],
                      type: parts[1] == 'multiple'
                          ? QuestionType.multipleChoice
                          : QuestionType.selectMultiple,
                      options: parts[2]
                          .split(',')
                          .asMap()
                          .entries
                          .map((e) => Option(
                              text: e.value,
                              isCorrect: parts[3]
                                  .split(',')
                                  .contains(e.key.toString())))
                          .toList(),
                    );
                  }
                })
                .whereType<Question>()
                .toList();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing questions: $e')),
      );
    }
  }

  Future<void> savePreset(BuildContext context) async {
    TextEditingController fileNameController = TextEditingController();

    // Show dialog to ask for file name
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter File Name"),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(hintText: 'Enter a name for your file'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog without saving
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Get the file name from the TextField
                String fileName = fileNameController.text.trim();

                if (fileName.isEmpty) {
                  // If the file name is empty, show an error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid file name.')),
                  );
                  return;
                }

                try {
                  // Convert your questions to JSON
                  final jsonQuestions =
                      questions.map((q) => q.toJson()).toList();
                  final jsonString = jsonEncode(jsonQuestions);

                  // Get the directory to save the file in (app's documents directory)
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath =
                      '${directory.path}/quiz_presets/$fileName.json';

                  // Save the file with the custom name
                  final file = File(filePath);
                  await file.writeAsString(jsonString);

                  // Notify the user of successful save
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Preset saved successfully as $fileName.json')),
                  );

                  // Close the dialog
                  Navigator.pop(context);
                } catch (e) {
                  // Handle any errors during file saving
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving preset: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void addOrUpdateQuestion(Question question) {
    setState(() {
      final index = questions.indexWhere((q) => q.id == question.id);
      if (index >= 0) {
        questions[index] = question;
      } else {
        questions.add(question);
      }
    });
  }

  void editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Question'),
        content: QuestionForm(
          onAddOrUpdate: addOrUpdateQuestion,
          onEdit: editQuestion,
          questions: questions,
          questionToEdit: questions[index],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void deleteQuestion(int index) {
    setState(() => questions.removeAt(index));
  }

  Future<void> _showServerList() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          child: ServerList(
            onSelectServer: (serverInfo) {
              Navigator.pop(context);
              final ipRegex = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
              final match = ipRegex.firstMatch(serverInfo);
              if (match != null) {
                final ip = match.group(1)!;
                if (serverInfo.contains('QUZZIZ')) {
                  _connectToQuizServer('$ip:4041');
                } else {
                  _connectToOtherServer('$ip:4041');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _connectToQuizServer(String address) async {
    try {
      final parts = address.split(':');
      final ip = parts[0];
      final port = int.parse(parts[1]);
      final socket =
          await Socket.connect(ip, port).timeout(Duration(seconds: 3));
      StringBuffer buffer = StringBuffer();
      socket.listen(
        (data) {
          buffer.write(utf8.decode(data));
        },
        onDone: () {
          final receivedData = buffer.toString();
          print('Client received JSON: $receivedData');
          try {
            final jsonData = jsonDecode(receivedData);
            if (jsonData is List) {
              final fetchedQuestions =
                  jsonData.map((e) => Question.fromJson(e)).toList();
              setState(() => questions.addAll(fetchedQuestions));
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizTakingScreen(
                    questions: fetchedQuestions,
                  ),
                ),
              );
            } else {
              throw FormatException('Expected a JSON list, got: $jsonData');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error parsing questions: $e')),
            );
          } finally {
            socket.close();
          }
        },
        onError: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection error: $e')),
          );
          socket.close();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to server: $e')),
      );
    }
  }

  void _connectToOtherServer(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected to non-QUZZIZ server at $address')),
    );
  }

  void _showCreateQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Question'),
        content: QuestionForm(
          onAddOrUpdate: addOrUpdateQuestion,
          onEdit: editQuestion,
          questions: questions,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuizDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingScreen(
          questions: questions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    broadcastServer?.stopBroadcast();
    serverSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('Dashboard'),
        backgroundColor: Color(0xFFD7C19C),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Controls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ElevatedButton.icon(
                    icon: Iconify(
                      isBroadcasting ? Mdi.stop_circle : Mdi.cast,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                        isBroadcasting ? 'Stop Broadcast' : 'Start Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBroadcasting ? Colors.red : Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: toggleBroadcast,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.connection,
                        size: 24, color: Colors.white),
                    label: const Text('Connect to Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _showServerList,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.plus_circle,
                        size: 24, color: Colors.white),
                    label: const Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _showCreateQuizDialog,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.upload,
                        size: 24, color: Colors.white),
                    label: const Text('Import Questions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: importQuestions,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.shuffle,
                        size: 24, color: Colors.white),
                    label: const Text('Randomize Questions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: questions.isNotEmpty ? randomizeQuestions : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.content_save,
                        size: 24, color: Colors.white),
                    label: const Text('Save Preset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed:
                        questions.isNotEmpty ? () => savePreset(context) : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.folder_open,
                        size: 24, color: Colors.white),
                    label: const Text('Load Preset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _showLoadPresetDialog,
                  ),
                  ElevatedButton.icon(
                    icon: const Iconify(Mdi.play_circle,
                        size: 24, color: Colors.white),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: questions.isNotEmpty ? _showQuizDialog : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Quiz Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 500,
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFD7C19C),
                ),
                child: questions.isEmpty
                    ? const Center(
                        child: Text(
                          'No questions added yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : QuestionList(
                        questions: questions,
                        onEdit: (index) => editQuestion(index),
                        onDelete: (index) => deleteQuestion(index),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServerList extends StatefulWidget {
  final Function(String) onSelectServer;

  const ServerList({super.key, required this.onSelectServer});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  List<String> servers = [];
  RawDatagramSocket? socket;

  @override
  void initState() {
    super.initState();
    _startListeningForServers();
  }

  Future<void> _startListeningForServers() async {
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4040);
      socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            if (!servers.contains(message)) {
              setState(() => servers.add(message));
            }
          }
        }
      });
    } catch (e) {
      print('Error listening for servers: $e');
    }
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Available Servers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          servers.isEmpty
              ? Text('No servers found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: servers.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(servers[index]),
                    onTap: () => widget.onSelectServer(servers[index]),
                  ),
                ),
        ],
      ),
    );
  }
}
