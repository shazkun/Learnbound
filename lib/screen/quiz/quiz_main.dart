import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart' as windows_picker;
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:learnbound/models/question.dart';
import 'package:learnbound/screen/quiz/quiz_server.dart';
import 'package:learnbound/screen/quiz/quiz_take.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/design/appbar.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:learnbound/util/server.dart';
import 'package:path_provider/path_provider.dart';

import 'question_creator.dart';
import 'question_widget.dart';

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
    broadcastServer!.setBroadcastName('QUIZ-PAD');
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

    if (!await presetDir.exists()) {
      await presetDir.create(recursive: true);
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

      CustomSnackBar.show(
        context,
        'Preset saved: ${file.path}',
        backgroundColor: Colors.green,
        icon: Icons.save,
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error saving preset: $e',
        isSuccess: false,
        backgroundColor: Colors.red,
        icon: Icons.error,
        iconColor: Colors.white,
        textColor: Colors.white,
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
                  CustomSnackBar.show(
                    context,
                    'Please enter a valid file name.',
                    backgroundColor: Colors.orange,
                    icon: Icons.warning,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                  );
                  return;
                }

                try {
                  // Get the directory to save the file in (app's documents directory)
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath =
                      '${directory.path}/quiz_presets/$fileName.json';
                  final file = File(filePath);

                  // Check if the file already exists
                  if (await file.exists()) {
                    // If the file exists, show a warning snackbar
                    CustomSnackBar.show(
                      context,
                      'A file with this name already exists.',
                      backgroundColor: Colors.orange,
                      icon: Icons.warning,
                      iconColor: Colors.white,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  // Convert your questions to JSON
                  final jsonQuestions =
                      questions.map((q) => q.toJson()).toList();
                  final jsonString = jsonEncode(jsonQuestions);

                  // Save the file with the custom name
                  await file.writeAsString(jsonString);

                  // Notify the user of successful save
                  CustomSnackBar.show(
                    context,
                    'Preset saved successfully as $fileName.json',
                    backgroundColor: Colors.green,
                    icon: Icons.save,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                  );

                  // Close the dialog
                  Navigator.pop(context);
                } catch (e) {
                  // Handle any errors during file saving
                  CustomSnackBar.show(
                    context,
                    'Error saving preset: $e',
                    isSuccess: false,
                    backgroundColor: Colors.red,
                    icon: Icons.error,
                    iconColor: Colors.white,
                    textColor: Colors.white,
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
                        setState(() {
                          questions.clear();
                        });

                        // Delay before clearing the list
                        await Future.delayed(Duration(milliseconds: 500));

                        try {
                          final content = await File(file.path).readAsString();
                          final jsonData = jsonDecode(content);

                          if (jsonData is List) {
                            final loadedQuestions = jsonData
                                .map((e) => Question.fromJson(e))
                                .toList();

                            setState(() {
                              questions = loadedQuestions;
                            });

                            if (mounted) {
                              Future.delayed(Duration.zero, () {
                                if (mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    'Preset loaded successfully',
                                    backgroundColor: Colors.green,
                                    icon: Icons.check_circle,
                                    iconColor: Colors.white,
                                    textColor: Colors.white,
                                  );
                                }
                              });
                            }
                          } else {
                            throw FormatException('Invalid file format');
                          }
                        } catch (e) {
                          if (mounted) {
                            Future.delayed(Duration.zero, () {
                              if (mounted) {
                                CustomSnackBar.show(
                                  context,
                                  'Failed to load preset: ${e.toString()}',
                                  backgroundColor: Colors.red,
                                  iconColor: Colors.white,
                                  textColor: Colors.white,
                                );
                              }
                            });
                          }
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

        List<Question> tempQuestions = [];

        // If it's a JSON file
        if (filePath.endsWith('.json')) {
          List<dynamic> jsonData = jsonDecode(content);
          tempQuestions = jsonData.map((e) => Question.fromJson(e)).toList();
        } else {
          // If it's a text file
          List<String> lines = content.split('\n');
          tempQuestions = lines
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
                            isCorrect:
                                parts[3].split(',').contains(e.key.toString())))
                        .toList(),
                  );
                }
              })
              .whereType<Question>()
              .toList();
        }

        // Process the questions in chunks of 10
        int chunkSize = 10;
        for (int i = 0; i < tempQuestions.length; i += chunkSize) {
          int end = (i + chunkSize < tempQuestions.length)
              ? i + chunkSize
              : tempQuestions.length;

          // Create a batch of questions to add to the UI
          List<Question> chunk = tempQuestions.sublist(i, end);

          // Wait for 50ms (or adjust based on your needs) to avoid lag
          await Future.delayed(Duration(milliseconds: 50));

          setState(() {
            questions.addAll(chunk);
          });
        }
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error importing questions: $e',
        isSuccess: false,
        backgroundColor: Colors.red,
        icon: Icons.error,
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    }
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
                if (serverInfo.contains('QUIZ-PAD')) {
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
            CustomSnackBar.show(context, 'Error parsing questions: $e',
                isSuccess: false,
                backgroundColor: Colors.red,
                icon: Icons.error,
                iconColor: Colors.white,
                textColor: Colors.white);
          } finally {
            socket.close();
          }
        },
        onError: (e) {
          CustomSnackBar.show(
            context,
            'Connection error: $e',
            isSuccess: false,
            backgroundColor: Colors.redAccent,
            icon: Icons.signal_wifi_off,
            iconColor: Colors.white,
            textColor: Colors.white,
          );

          socket.close();
        },
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to connect to server: $e',
        isSuccess: false,
        backgroundColor: Colors.redAccent,
        icon: Icons.signal_wifi_off,
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    }
  }

  void _connectToOtherServer(String address) {
    CustomSnackBar.show(
      context,
      'Connected to non-QUZZIZ server at $address',
      backgroundColor: Colors.blue, // optional: choose a color you like
      icon: Icons.wifi, // optional: better matching icon
      iconColor: Colors.white,
      textColor: Colors.white,
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
      appBar: AppBarCustom(
        titleText: "Dashboard",
        showBackButton: true,
        onBackPressed: () async {
          return CustomExitDialog.show(context);
        },
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
                    icon: Iconify(
                      Mdi.clear,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        if (questions.isNotEmpty) {
                          questions.clear();
                        } else {
                          CustomSnackBar.show(
                            context,
                            'Question list is empty.',
                            backgroundColor: Colors.amber,
                            icon: Icons
                                .warning, // <-- use only IconData like this
                            iconColor: Colors.black,
                            textColor: Colors.black,
                          );
                        }
                      });
                    },
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
