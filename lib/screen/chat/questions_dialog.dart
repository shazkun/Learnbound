import 'dart:io';

import 'package:flutter/material.dart';

void showQuestionsDialog({
  required BuildContext context,
  required List<String> questions,
  required Map<String, List<String>> multipleChoiceQuestions,
  required Map<String, String?> selectedAnswers,
  required Set<String> confirmedAnswers,
  required Animation<double> fadeAnimation,
  required Socket? clientSocket,
  required Function(VoidCallback) onStateUpdate,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sticky Questions',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800]),
            ),
            SizedBox(height: 16),
            Expanded(
              child: (questions.isEmpty && multipleChoiceQuestions.isEmpty)
                  ? Center(
                      child: Text('No questions yet',
                          style: TextStyle(color: Colors.grey)))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        ...questions.map((question) => FadeTransition(
                              opacity: fadeAnimation,
                              child: ListTile(
                                  title: Text(question,
                                      style: TextStyle(fontSize: 16))),
                            )),
                        ...multipleChoiceQuestions.entries.map((entry) {
                          final question = entry.key;
                          final options = entry.value;
                          final isConfirmed =
                              confirmedAnswers.contains(question);
                          final selectedAnswer = selectedAnswers[question];
                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(question,
                                          style: TextStyle(fontSize: 16))),
                                  if (isConfirmed)
                                    Chip(
                                      label: Text('Confirmed',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: const Color.fromRGBO(
                                          211, 172, 112, 1.0),
                                    ),
                                ],
                              ),
                              children: [
                                ...options.map((option) => ListTile(
                                      title: Row(
                                        children: [
                                          Text(option),
                                          if (isConfirmed &&
                                              selectedAnswer == option)
                                            SizedBox(width: 8),
                                          if (isConfirmed &&
                                              selectedAnswer == option)
                                            Icon(Icons.check,
                                                color: const Color.fromRGBO(
                                                    211, 172, 112, 1.0)),
                                        ],
                                      ),
                                      onTap: isConfirmed
                                          ? null
                                          : () => onStateUpdate(() =>
                                              selectedAnswers[question] =
                                                  option),
                                    )),
                                if (!isConfirmed && selectedAnswer != null)
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (clientSocket != null) {
                                          clientSocket.write(
                                              "Answer:$question|$selectedAnswer");
                                          onStateUpdate(() =>
                                              confirmedAnswers.add(question));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            211, 172, 112, 1.0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text('Confirm',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}
