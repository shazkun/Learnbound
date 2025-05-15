import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:provider/provider.dart';

class MultipleChoiceUI extends StatelessWidget {
  final Map<String, List<String>> questions;
  final Map<String, String?> selectedAnswers;
  final Set<String> confirmedAnswers;
  final Animation<double> fadeAnimation;
  final Socket? clientSocket;
  final Function(VoidCallback) onStateUpdate;

  const MultipleChoiceUI({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.confirmedAnswers,
    required this.fadeAnimation,
    required this.clientSocket,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final username = user?.username;
    if (questions.isEmpty) {
      // If the questions map is empty, show a centered placeholder message
      return Center(
        child: Text(
          'No questions available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

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
                          backgroundColor:
                              const Color.fromRGBO(211, 172, 112, 1.0),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...options
                      .asMap()
                      .map((i, option) {
                        // Create a unique key using the index
                        return MapEntry(
                          i,
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                Text(option),
                                if (isConfirmed && selectedAnswer == option)
                                  SizedBox(width: 8),
                                if (isConfirmed && selectedAnswer == option)
                                  Icon(Icons.check,
                                      color: const Color.fromRGBO(
                                          211, 172, 112, 1.0)),
                              ],
                            ),
                            value:
                                '$question-$i', // Use unique value by appending index
                            groupValue: selectedAnswer != null
                                ? '$question-${options.indexOf(selectedAnswer)}'
                                : null,
                            onChanged: isConfirmed
                                ? null
                                : (value) => onStateUpdate(() {
                                      selectedAnswers[question] = options[
                                          int.parse(value!.split('-')[1])];
                                    }),
                          ),
                        );
                      })
                      .values
                      .toList(),
                  if (!isConfirmed && selectedAnswer != null)
                    ElevatedButton(
                      onPressed: () {
                        if (clientSocket != null) {
                          clientSocket!.write(
                              "Answer:$question|$selectedAnswer|$username");
                          onStateUpdate(() => confirmedAnswers.add(question));
                          print(
                              "Answer sent: $question | $selectedAnswer | $username");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(211, 172, 112, 1.0),
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
