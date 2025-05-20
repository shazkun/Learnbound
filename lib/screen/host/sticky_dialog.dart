import 'package:flutter/material.dart';

import 'host_styles.dart';

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
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.2), // stronger shadow
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  question,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => onRemoveQuestion(question),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
