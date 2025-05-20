import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart' as windows_picker;
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:learnbound/models/question.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/screen/quiz/quiz_server.dart';
import 'package:learnbound/screen/quiz/quiz_take.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/design/appbar.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:learnbound/util/server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../database/user_provider.dart';
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    broadcastServer = BroadcastServer();
    broadcastServer!.setBroadcastName('${user?.username} - QUIZ-PAD');
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
      questions.shuffle();
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

  Future<void> savePreset(BuildContext context) async {
    final TextEditingController fileNameController = TextEditingController();
    bool overwriteFile = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Save Quiz Preset',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fileNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter preset name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: overwriteFile,
                          onChanged: (value) {
                            setDialogState(() {
                              overwriteFile = value ?? false;
                            });
                          },
                        ),
                        const Text('Overwrite if exists'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            final fileName = fileNameController.text.trim();
                            if (fileName.isEmpty) {
                              CustomSnackBar.show(
                                context,
                                'Please enter a valid file name',
                                backgroundColor: Colors.orange,
                                icon: Icons.warning,
                                iconColor: Colors.white,
                                textColor: Colors.white,
                              );
                              return;
                            }

                            try {
                              final directory =
                                  await getApplicationDocumentsDirectory();
                              final filePath =
                                  '${directory.path}/quiz_presets/$fileName.json';
                              final file = File(filePath);

                              if (await file.exists() && !overwriteFile) {
                                CustomSnackBar.show(
                                  context,
                                  'File already exists. Check overwrite option.',
                                  backgroundColor: Colors.orange,
                                  icon: Icons.warning,
                                  iconColor: Colors.white,
                                  textColor: Colors.white,
                                );
                                return;
                              }

                              final jsonQuestions =
                                  questions.map((q) => q.toJson()).toList();
                              final jsonString = jsonEncode(jsonQuestions);
                              await file.writeAsString(jsonString);

                              CustomSnackBar.show(
                                context,
                                'Preset saved as $fileName.json',
                                backgroundColor: Colors.green,
                                icon: Icons.save,
                                iconColor: Colors.white,
                                textColor: Colors.white,
                              );

                              Navigator.pop(context);
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
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deletePreset(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        CustomSnackBar.show(
          context,
          'Preset deleted successfully',
          backgroundColor: Colors.green,
          icon: Icons.delete,
          iconColor: Colors.white,
          textColor: Colors.white,
        );
      } else {
        CustomSnackBar.show(
          context,
          'Preset not found',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
          iconColor: Colors.white,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error deleting preset: $e',
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

  void _showLoadPresetDialog() async {
    final files = await getAllPresets();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Load Preset',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                child: files.isEmpty
                    ? const Text(
                        'No presets found.',
                        style: TextStyle(fontSize: 16),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final fileName = file.path.split('/').last;
                          return ListTile(
                            title: Text(fileName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                        'Are you sure you want to delete $fileName?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await deletePreset(file.path);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  _showLoadPresetDialog();
                                }
                              },
                            ),
                            onTap: () async {
                              if (!mounted) return;
                              Navigator.pop(context);
                              setState(() {
                                questions.clear();
                              });
                              CustomSnackBar.show(
                                  context, 'Preset loaded successfully',
                                  backgroundColor: Colors.green,
                                  icon: Icons.check_circle,
                                  iconColor: Colors.white,
                                  textColor: Colors.white);

                              await Future.delayed(Duration(milliseconds: 500));

                              try {
                                final content =
                                    await File(file.path).readAsString();
                                final jsonData = jsonDecode(content);

                                if (jsonData is List) {
                                  final loadedQuestions = jsonData
                                      .map((e) => Question.fromJson(e))
                                      .toList();

                                  if (!mounted) return;
                                  setState(() {
                                    questions = loadedQuestions;
                                  });
                                } else {
                                  throw FormatException('Invalid file format');
                                }
                              } catch (e) {
                                if (mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    'Failed to load preset: ${e.toString()}',
                                    backgroundColor: Colors.red,
                                    iconColor: Colors.white,
                                    textColor: Colors.white,
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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

        if (filePath.endsWith('.json')) {
          List<dynamic> jsonData = jsonDecode(content);
          tempQuestions = jsonData.map((e) => Question.fromJson(e)).toList();
        } else {
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

        int chunkSize = 10;
        for (int i = 0; i < tempQuestions.length; i += chunkSize) {
          int end = (i + chunkSize < tempQuestions.length)
              ? i + chunkSize
              : tempQuestions.length;

          List<Question> chunk = tempQuestions.sublist(i, end);
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
      backgroundColor: Colors.blue,
      icon: Icons.wifi,
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

  Widget buildButton({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 180,
      child: ElevatedButton.icon(
        icon: icon,
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
        onPressed: onPressed,
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
          return CustomExitDialog.show(context,
              usePushReplacement: true, targetPage: HomeScreen());
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
                  buildButton(
                    icon: Iconify(
                      isBroadcasting ? Mdi.stop_circle : Mdi.cast,
                      size: 24,
                      color: Colors.white,
                    ),
                    label:
                        isBroadcasting ? 'Broadcast' : 'Broadcast',
                    color: isBroadcasting ? Colors.red : Colors.amber,
                    onPressed: toggleBroadcast,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.connection,
                        size: 24, color: Colors.white),
                    label: 'Connect',
                    color: Colors.blue,
                    onPressed: _showServerList,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.plus_circle,
                        size: 24, color: Colors.white),
                    label: 'Add',
                    color: Colors.deepPurple,
                    onPressed: _showCreateQuizDialog,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.upload,
                        size: 24, color: Colors.white),
                    label: 'Import',
                    color: Colors.deepPurple,
                    onPressed: importQuestions,
                  ),
                  buildButton(
                    icon:
                        const Iconify(Mdi.clear, size: 24, color: Colors.white),
                    label: 'Clear',
                    color: Colors.teal,
                    onPressed: questions.isNotEmpty
                        ? () => setState(() {
                              questions.clear();
                              CustomSnackBar.show(
                                  context, "Questions cleared.");
                            })
                        : null,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.shuffle,
                        size: 24, color: Colors.white),
                    label: 'Randomize',
                    color: Colors.orange,
                    onPressed: questions.isNotEmpty ? randomizeQuestions : null,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.content_save,
                        size: 24, color: Colors.white),
                    label: 'Save',
                    color: Colors.teal,
                    onPressed:
                        questions.isNotEmpty ? () => savePreset(context) : null,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.folder_open,
                        size: 24, color: Colors.white),
                    label: 'Load',
                    color: Colors.orange,
                    onPressed: _showLoadPresetDialog,
                  ),
                  buildButton(
                    icon: const Iconify(Mdi.play_circle,
                        size: 24, color: Colors.white),
                    label: 'Start',
                    color: Colors.green,
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
