

import 'dart:io';

import 'package:flutter/material.dart';

class MultipleChoiceUI extends StatelessWidget {
  final Map<String, List<String>> questions;
  final Map<String, String?> selectedAnswers;
  final Set<String> confirmedAnswers;
  final Animation<double> fadeAnimation;
  final Socket? clientSocket;
  final Function(VoidCallback) onStateUpdate;

  const MultipleChoiceUI({
    required this.questions,
    required this.selectedAnswers,
    required this.confirmedAnswers,
    required this.fadeAnimation,
    required this.clientSocket,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions.keys.elementAt(index);
        final options = questions[question]!;
        final isConfirmed = confirmedAnswers.contains(question);
        final selectedAnswer = selectedAnswers[question];
        return FadeTransition(
          opacity: fadeAnimation,
          child: Card(
            color: Colors.white.withOpacity(0.95),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isConfirmed)
                        Chip(
                          label: Text('Confirmed',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.teal[400],
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...options.map((option) => RadioListTile<String>(
                        title: Row(
                          children: [
                            Text(option),
                            if (isConfirmed && selectedAnswer == option)
                              SizedBox(width: 8),
                            if (isConfirmed && selectedAnswer == option)
                              Icon(Icons.check, color: Colors.teal[400]),
                          ],
                        ),
                        value: option,
                        groupValue: selectedAnswer,
                        onChanged: isConfirmed
                            ? null
                            : (value) => onStateUpdate(
                                () => selectedAnswers[question] = value),
                      )),
                  if (!isConfirmed && selectedAnswer != null)
                    ElevatedButton(
                      onPressed: () {
                        if (clientSocket != null) {
                          clientSocket!
                              .write("Answer:$question|$selectedAnswer");
                          onStateUpdate(() => confirmedAnswers.add(question));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Confirm',
                          style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
