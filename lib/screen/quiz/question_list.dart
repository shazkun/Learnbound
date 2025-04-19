import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import 'question_model.dart';

class QuestionList extends StatefulWidget {
  final List<Question> questions;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const QuestionList({
    super.key,
    required this.questions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  _QuestionListState createState() => _QuestionListState();
}

class _QuestionListState extends State<QuestionList> {
  int _currentIndex = 0;

  bool _isListView = true; // Toggle between list and slide view

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final bool isEmpty = question.text.trim().isEmpty;

    return Stack(
      children: [
        Column(
          children: [
            // View Toggle (Icons for list and slide view)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.list,
                      color: _isListView ? Colors.black : Colors.white),
                  onPressed: () {
                    setState(() {
                      _isListView = true;
                    });
                  },
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.view_carousel,
                      color: !_isListView ? Colors.black : Colors.white),
                  onPressed: () {
                    setState(() {
                      _isListView = false;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            if (!_isListView)
              Text(
                "${_currentIndex + 1} / ${widget.questions.length}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

            Expanded(
              child: _isListView
                  ? ListView.builder(
                      itemCount: widget.questions.length,
                      itemBuilder: (context, index) {
                        final question = widget.questions[index];
                        final bool isEmpty = question.text.trim().isEmpty;

                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: buildQuestionCard(question, index),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: FadeInUp(
                        delay: Duration(milliseconds: _currentIndex * 100),
                        child: buildQuestionCard(question, _currentIndex),
                      ),
                    ),
            ),
            SizedBox(height: 60), // Reserve space for the arrows
          ],
        ),

        // Only show arrows in Slide View
        if (!_isListView)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: _currentIndex > 0 ? Colors.black : Colors.grey),
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                          });
                        }
                      : null,
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded,
                      color: _currentIndex < widget.questions.length - 1
                          ? Colors.black
                          : Colors.grey),
                  onPressed: _currentIndex < widget.questions.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildQuestionCard(Question question, int index) {
    final isEmpty = question.text.trim().isEmpty;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEmpty ? 'No question text provided.' : question.text,
            style: TextStyle(
              fontSize: 16,
              color: isEmpty ? Colors.red : Colors.black,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            question.type == QuestionType.shortAnswer
                ? 'Answer: ${question.correctAnswer}'
                : 'Type: ${question.type.toString().split('.').last}\nOptions: ${question.options.map((o) => o.text + (o.isCorrect ? " (Correct)" : "")).join(", ")}',
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () => widget.onEdit(index),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => widget.onDelete(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
