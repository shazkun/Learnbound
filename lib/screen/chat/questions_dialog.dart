import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learnbound/screen/chat/question_notifier.dart';
import 'package:provider/provider.dart';

void showQuestionsDialog({
  required BuildContext context,
  required Animation<double> fadeAnimation,
  required Socket? clientSocket,
  required Function(VoidCallback) onStateUpdate,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Consumer<QuestionsProvider>(
          builder: (context, questionsProvider, child) {
            final questions = questionsProvider.questions;
            final multipleChoiceQuestions =
                questionsProvider.multipleChoiceQuestions;
            final selectedAnswers = questionsProvider.selectedAnswers;
            final confirmedAnswers = questionsProvider.confirmedAnswers;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Sticky Questions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey[900],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: (questions.isEmpty && multipleChoiceQuestions.isEmpty)
                      ? Center(
                          child: Text(
                            'No questions yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            ...questions.map((question) => FadeTransition(
                                  opacity: fadeAnimation,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2.0,
                                      ),
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      question,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blueGrey[800],
                                      ),
                                    ),
                                  ),
                                )),
                            ...multipleChoiceQuestions.entries.map((entry) {
                              final question = entry.key;
                              final options = entry.value;
                              final isConfirmed =
                                  confirmedAnswers.contains(question);
                              final selectedAnswer = selectedAnswers[question];
                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            question,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey[900],
                                            ),
                                          ),
                                        ),
                                        if (isConfirmed)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFD3AC70),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Confirmed',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    collapsedBackgroundColor:
                                        Colors.transparent,
                                    backgroundColor: Colors.grey[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    children: options.map((option) {
                                      return ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: isConfirmed
                                                      ? Colors.grey[600]
                                                      : Colors.blueGrey[800],
                                                ),
                                              ),
                                            ),
                                            if (isConfirmed &&
                                                selectedAnswer == option)
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFFD3AC70),
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                        onTap: isConfirmed
                                            ? null
                                            : () {
                                                questionsProvider.selectAnswer(
                                                    question, option);
                                                if (clientSocket != null) {
                                                  clientSocket.write(
                                                    "Answer:$question|$option",
                                                  );
                                                }
                                              },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
