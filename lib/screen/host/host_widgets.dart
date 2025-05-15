import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:learnbound/screen/host/host_styles.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:learnbound/util/design/wave.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String lobbyState;
  final String selectedMode;
  final VoidCallback? onSettingsPressed;
  final Future<bool> Function() onBackPressed;
  final VoidCallback? onBackSuccess;

  const CustomAppBar({
    super.key,
    required this.lobbyState,
    required this.selectedMode,
    this.onSettingsPressed,
    required this.onBackPressed,
    this.onBackSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize:
          const Size.fromHeight(120), // Increased height for wave design
      child: ClipPath(
        clipper: TopClipper(), // Custom clipper for wave shape
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            lobbyState == "lobby" ? 'Lobby' : '$selectedMode ',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          leading: IconButton(
            icon: Image.asset(
              'assets/back-arrow.png',
              height: 24,
              width: 24,
            ),
            onPressed: () async {
              if (await onBackPressed()) {
                onBackSuccess?.call();
                Navigator.pop(context);
              }
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD7C19C),
            ),
          ),
          actions: lobbyState == "start"
              ? [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onSettingsPressed,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

class LobbyView extends StatelessWidget {
  final Map<String, int> participants;
  final Animation<double> fadeAnimation;
  final VoidCallback onStartSession;

  const LobbyView({
    super.key,
    required this.participants,
    required this.fadeAnimation,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: participants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Iconify(
                        Mdi.account_group_outline,
                        size: 48,
                        color: Colors.black54,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Awaiting Participants...',
                        style: AppStyles.titleText.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.normal, // Remove bold
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: AppStyles.defaultPadding,
                  itemCount: participants.length,
                  itemBuilder: (context, index) => FadeTransition(
                    opacity: fadeAnimation,
                    child: Card(
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          participants.keys.elementAt(index),
                          style: AppStyles.participantText,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: AppStyles.defaultPadding,
          child: ElevatedButton(
            onPressed: participants.isNotEmpty ? onStartSession : null,
            style: AppStyles.elevatedButtonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(
                participants.isEmpty
                    ? Colors.grey.withOpacity(0.4)
                    : Colors.green[400],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Iconify(
                  participants.isEmpty ? Mdi.account_off : Mdi.play_circle,
                  size: 24,
                  color: participants.isEmpty
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  'START SESSION',
                  style: participants.isEmpty
                      ? AppStyles.buttonText
                          .copyWith(color: Colors.black.withOpacity(0.5))
                      : AppStyles.buttonText.copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SessionView extends StatelessWidget {
  final String selectedMode;
  final List<Map<String, dynamic>> messages;
  final Map<String, Map<String, int>> multipleChoiceResponses;
  final Animation<double> fadeAnimation;
  final TextEditingController questionController;
  final VoidCallback onSendQuestion;
  final VoidCallback onShowMultipleChoiceDialog;
  final VoidCallback onShowSticky;

  const SessionView({
    super.key,
    required this.selectedMode,
    required this.messages,
    required this.multipleChoiceResponses,
    required this.fadeAnimation,
    required this.questionController,
    required this.onSendQuestion,
    required this.onShowMultipleChoiceDialog,
    required this.onShowSticky,
  });

  Widget _buildMessageTile(Map<String, dynamic> message, BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: AppStyles.messageTileDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['nickname'] ?? 'Unknown',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
            ),
            const SizedBox(height: 4),
            if (message['text'] != null)
              Text(message['text'], style: const TextStyle(fontSize: 16)),
            if (message['isImage'] == true)
              _buildImageThumbnail(message['image'], context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String base64Image, BuildContext context) {
    Uint8List decodedImage = base64Decode(base64Image);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: AppStyles.dialogShape,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                decodedImage,
                gaplessPlayback: true, // reduces flicker
                filterQuality: FilterQuality.low, // improves speed
              )),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          decodedImage,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          gaplessPlayback: true, // optional: smoother loading
          filterQuality: FilterQuality.low, // optional: faster
        ),
      ),
    );
  }

  Widget _buildImageTile(Map<String, dynamic> message, BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              message['nickname'] ?? 'Unknown',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
            ),
            const SizedBox(height: 8),
            _buildImageThumbnail(message['image'], context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: selectedMode == "Chat"
              ? ListView.builder(
                  padding: AppStyles.defaultPadding,
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageTile(messages[index], context),
                )
              : selectedMode == "Multiple Choice"
                  ? ListView.builder(
                      padding: AppStyles.defaultPadding,
                      itemCount: multipleChoiceResponses.length,
                      itemBuilder: (context, index) {
                        final question =
                            multipleChoiceResponses.keys.elementAt(index);
                        final responses = multipleChoiceResponses[question]!;
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: Card(
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: AppStyles.defaultPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...responses.entries.map((entry) => Row(
                                        children: [
                                          Text("${entry.key}: ",
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          Text(
                                            "${entry.value} votes",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: const Color.fromRGBO(
                                                    211, 172, 112, 1.0)),
                                          ),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      padding: AppStyles.defaultPadding,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount:
                          messages.where((m) => m['isImage'] == true).length,
                      itemBuilder: (context, index) => _buildImageTile(
                          messages
                              .where((m) => m['isImage'] == true)
                              .toList()[index],
                          context),
                    ),
        ),
        Padding(
          padding: AppStyles.defaultPadding,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: questionController,
                  maxLength: 100,
                  style: const TextStyle(color: Colors.black),
                  decoration: AppStyles.textFieldDecoration.copyWith(
                    hintText: selectedMode == "Multiple Choice"
                        ? "Type a question (add options in dialog)"
                        : "Ask a question...",
                    counterText: "",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'send-Host',
                onPressed: () {
                  if (questionController.text.isNotEmpty) {
                    if (selectedMode == "Multiple Choice") {
                      onShowMultipleChoiceDialog();
                    } else {
                      onSendQuestion();
                    }
                  } else {
                    CustomSnackBar.show(context, "Input is empty.",
                        backgroundColor: Colors.orange, icon: Icons.info);
                  }
                },
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: const Icon(Icons.send),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'list-Host',
                onPressed: onShowSticky,
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: const Icon(Icons.question_answer),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class ModeSelectorDialog extends StatelessWidget {
  final Function(String) onModeSelected;

  const ModeSelectorDialog({super.key, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    const modes = ['Chat', 'Picture', 'Drawing', 'Multiple Choice'];
    return Padding(
      padding: AppStyles.defaultPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: modes
            .map((mode) => ListTile(
                  title: Text(mode,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    onModeSelected(mode);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class MultipleChoiceDialog extends StatefulWidget {
  final TextEditingController questionController;
  final Function(String, List<String>) onSend;

  const MultipleChoiceDialog({
    super.key,
    required this.questionController,
    required this.onSend,
  });

  @override
  _MultipleChoiceDialogState createState() => _MultipleChoiceDialogState();
}

class _MultipleChoiceDialogState extends State<MultipleChoiceDialog> {
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.defaultPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create Multiple Choice Question',
              style: AppStyles.dialogTitle),
          const SizedBox(height: 16),
          TextField(
            controller: widget.questionController,
            decoration: const InputDecoration(labelText: 'Question'),
          ),
          const SizedBox(height: 16),
          ...optionControllers.map(
            (controller) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Option'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final question = widget.questionController.text;
              final options = optionControllers
                  .map((c) => c.text)
                  .where((text) => text.isNotEmpty)
                  .toList();

              // Check if there are any duplicate options
              final hasDuplicates = options.toSet().length != options.length;

              if (question.isNotEmpty && options.length >= 2) {
                if (hasDuplicates) {
                  // Show error message if duplicate options exist
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Options must be unique'),
                    ),
                  );
                } else {
                  widget.onSend(question, options);
                  for (var c in optionControllers) {
                    c.clear();
                  }
                  Navigator.pop(context);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a question and at least 2 options'),
                  ),
                );
              }
            },
            style: AppStyles.elevatedButtonStyle,
            child: const Text('Send', style: AppStyles.buttonText),
          ),
        ],
      ),
    );
  }
}

class StickyQuestionsDialog extends StatelessWidget {
  final List<String> stickyQuestions;
  final Animation<double> fadeAnimation;
  final Function(String) onRemoveQuestion;

  const StickyQuestionsDialog({
    super.key,
    required this.stickyQuestions,
    required this.fadeAnimation,
    required this.onRemoveQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: AppStyles.defaultPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sticky Questions', style: AppStyles.dialogTitle),
          const SizedBox(height: 16),
          Expanded(
            child: stickyQuestions.isEmpty
                ? const Center(
                    child: Text('No sticky questions yet',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: stickyQuestions.length,
                    itemBuilder: (context, index) {
                      final question = stickyQuestions[index];
                      return FadeTransition(
                        opacity: fadeAnimation,
                        child: ListTile(
                          title: Text(question,
                              style: const TextStyle(fontSize: 16)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onRemoveQuestion(question),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: AppStyles.elevatedButtonStyle,
            child: const Text('Close', style: AppStyles.buttonText),
          ),
        ],
      ),
    );
  }
}
