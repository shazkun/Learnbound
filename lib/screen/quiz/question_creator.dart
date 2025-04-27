import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../models/question.dart';

class QuestionForm extends StatefulWidget {
  final Function(Question) onAddOrUpdate;
  final Function(int) onEdit;
  final List<Question> questions;
  final Question? questionToEdit;

  const QuestionForm({
    super.key,
    required this.onAddOrUpdate,
    required this.onEdit,
    required this.questions,
    this.questionToEdit,
  });

  @override
  _QuestionFormState createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  List<bool> _correctOptions =
      List<bool>.from([false, false, false, false]); // Growable list
  int? editingIndex;
  QuestionType _selectedType = QuestionType.shortAnswer;

  @override
  void initState() {
    super.initState();
    if (widget.questionToEdit != null) {
      _questionController.text = widget.questionToEdit!.text;
      _selectedType = widget.questionToEdit!.type;
      _answerController.text = widget.questionToEdit!.correctAnswer;

      // Initialize options based on question to edit
      int optionCount = widget.questionToEdit!.options.length > 4
          ? widget.questionToEdit!.options.length
          : 4;
      _optionControllers = List.generate(
        optionCount,
        (i) => TextEditingController(
          text: i < widget.questionToEdit!.options.length
              ? widget.questionToEdit!.options[i].text
              : '',
        ),
      );
      _correctOptions = List<bool>.from(
        List.generate(
          optionCount,
          (i) => i < widget.questionToEdit!.options.length
              ? widget.questionToEdit!.options[i].isCorrect
              : false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _optionControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  void addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
      _correctOptions.add(false);
    });
  }

  void deleteOption(int index) {
    if (_optionControllers.length <= 2)
      return; // Prevent deleting below 2 options
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _correctOptions.removeAt(index);
    });
  }

  void addOrUpdateQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question text is required')),
      );
      return;
    }

    if (_selectedType == QuestionType.shortAnswer &&
        _answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correct answer is required for short answer')),
      );
      return;
    }

    if (_selectedType != QuestionType.shortAnswer) {
      int optionCount =
          _optionControllers.where((c) => c.text.isNotEmpty).length;
      int correctCount = _correctOptions.where((c) => c).length;
      if (optionCount < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide at least 2 options')),
        );
        return;
      }
      if (_selectedType == QuestionType.selectMultiple && correctCount < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Select at least 2 correct answers for select multiple')),
        );
        return;
      }
      if (_selectedType == QuestionType.multipleChoice && correctCount != 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Select exactly one correct answer for multiple choice')),
        );
        return;
      }
    }

    List<Option> options = _selectedType != QuestionType.shortAnswer
        ? _optionControllers
            .asMap()
            .entries
            .where((e) => e.value.text.isNotEmpty)
            .map((e) =>
                Option(text: e.value.text, isCorrect: _correctOptions[e.key]))
            .toList()
        : [];

    final question = Question(
      id: widget.questionToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: _questionController.text,
      type: _selectedType,
      correctAnswer: _selectedType == QuestionType.shortAnswer
          ? _answerController.text
          : '',
      options: options,
    );

    widget.onAddOrUpdate(question);
    if (widget.questionToEdit != null) {
      Navigator.pop(context); // Close dialog if editing
    } else {
      clearForm();
    }
  }

  void clearForm() {
    setState(() {
      _questionController.clear();
      _answerController.clear();
      _optionControllers = List.generate(4, (_) => TextEditingController());
      _correctOptions = List<bool>.from([false, false, false, false]);
      _selectedType = QuestionType.shortAnswer;
      editingIndex = null;
    });
  }

  void editQuestion(int index) {
    setState(() {
      editingIndex = index;
      _questionController.text = widget.questions[index].text;
      _selectedType = widget.questions[index].type;
      _answerController.text = widget.questions[index].correctAnswer;

      // Initialize options for editing
      int optionCount = widget.questions[index].options.length > 4
          ? widget.questions[index].options.length
          : 4;
      _optionControllers = List.generate(
        optionCount,
        (i) => TextEditingController(
          text: i < widget.questions[index].options.length
              ? widget.questions[index].options[i].text
              : '',
        ),
      );
      _correctOptions = List<bool>.from(
        List.generate(
          optionCount,
          (i) => i < widget.questions[index].options.length
              ? widget.questions[index].options[i].isCorrect
              : false,
        ),
      );
    });
    widget.onEdit(index);
  }

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.questionToEdit != null
                    ? 'Edit Question'
                    : 'Add Question',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                maxLength: 100,
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<QuestionType>(
                value: _selectedType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: QuestionType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type
                              .toString()
                              .split('.')
                              .last
                              .replaceAll('selectMultiple', 'Select Multiple')),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _optionControllers =
                        List.generate(4, (_) => TextEditingController());
                    _correctOptions =
                        List<bool>.from([false, false, false, false]);
                  });
                },
              ),
              SizedBox(height: 16),
              if (_selectedType == QuestionType.shortAnswer)
                TextField(
                  maxLength: 100,
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              if (_selectedType != QuestionType.shortAnswer) ...[
                Text(
                  'Options (at least 2 required)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 8),
                ...List.generate(
                  _optionControllers.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Checkbox(
                          value: _correctOptions[index],
                          onChanged: (value) {
                            setState(() {
                              _correctOptions[index] = value!;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: _optionControllers.length > 2
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: _optionControllers.length > 2
                              ? () => deleteOption(index)
                              : null,
                          tooltip: 'Delete Option',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.deepPurple),
                    onPressed: addOption,
                    tooltip: 'Add Option',
                  ),
                ),
              ],
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.questionToEdit == null)
                    ElevatedButton.icon(
                      icon: Icon(Icons.clear),
                      label: Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: clearForm,
                    ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(
                        widget.questionToEdit != null ? Icons.edit : Icons.add),
                    label: Text(widget.questionToEdit != null
                        ? 'Update Question'
                        : 'Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: addOrUpdateQuestion,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
