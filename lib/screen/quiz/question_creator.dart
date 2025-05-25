import 'package:flutter/material.dart';
import 'package:learnbound/models/question.dart';
import 'package:learnbound/util/design/colors.dart';
import 'package:learnbound/util/design/snackbar.dart';

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

class _QuestionFormState extends State<QuestionForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  List<bool> _correctOptions = List<bool>.filled(4, false);
  int? editingIndex;
  QuestionType _selectedType = QuestionType.shortAnswer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    if (widget.questionToEdit != null) {
      _questionController.text = widget.questionToEdit!.text;
      _selectedType = widget.questionToEdit!.type;
      _answerController.text = widget.questionToEdit!.correctAnswer;
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
      _correctOptions = List.generate(
        optionCount,
        (i) => i < widget.questionToEdit!.options.length
            ? widget.questionToEdit!.options[i].isCorrect
            : false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
      _correctOptions.add(false);
      _animationController.forward(from: 0);
    });
  }

  void _deleteOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _correctOptions.removeAt(index);
      _animationController.forward(from: 0);
    });
  }

  void _addOrUpdateQuestion() {
    if (_questionController.text.isEmpty) {
      _showSnackBar('Question text is required', false);
      return;
    }

    if (_selectedType == QuestionType.shortAnswer &&
        _answerController.text.isEmpty) {
      _showSnackBar('Correct answer is required for short answer', false);
      return;
    }

    if (_selectedType != QuestionType.shortAnswer) {
      int optionCount =
          _optionControllers.where((c) => c.text.isNotEmpty).length;
      int correctCount = _correctOptions.where((c) => c).length;
      if (optionCount < 2) {
        _showSnackBar('Please provide at least 2 options', false);
        return;
      }
      if (_selectedType == QuestionType.selectMultiple && correctCount < 2) {
        _showSnackBar(
            'Select at least 2 correct answers for select multiple', false);
        return;
      }
      if (_selectedType == QuestionType.multipleChoice && correctCount != 1) {
        _showSnackBar(
            'Select exactly one correct answer for multiple choice', false);
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
      Navigator.pop(context);
    } else {
      _clearForm();
    }
  }

  void _clearForm() {
    setState(() {
      _questionController.clear();
      _answerController.clear();
      _optionControllers = List.generate(4, (_) => TextEditingController());
      _correctOptions = List<bool>.filled(4, false);
      _selectedType = QuestionType.shortAnswer;
      editingIndex = null;
      _animationController.forward(from: 0);
    });
  }

  void _showSnackBar(String message, bool isSuccess) {
    CustomSnackBar.show(context, message,
        isSuccess: isSuccess, backgroundColor: AppColors.info);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.questionToEdit != null
                    ? 'Edit Question'
                    : 'Add Question',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300, // Adjust width to control characters per line
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    counterText: '',
                  ),
                  maxLines: 2,
                  maxLength: 100, // total characters allowed
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QuestionType>(
                value: _selectedType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // ← rounder edges
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12), // ← apply to enabled state
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12), // ← apply to focused state
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                ),
                items: QuestionType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.toString().split('.').last.replaceAll(
                                'selectMultiple', 'Select Multiple'),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _optionControllers =
                        List.generate(4, (_) => TextEditingController());
                    _correctOptions = List<bool>.filled(4, false);
                    _animationController.forward(from: 0);
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == QuestionType.shortAnswer)
                SizedBox(
                  width: 300, // Adjust width to control characters per line
                  child: TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      labelText: 'Correct Answer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      counterText: '',
                    ),
                    maxLines: 2,
                    maxLength: 100, // total characters allowed
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              if (_selectedType != QuestionType.shortAnswer) ...[
                Text(
                  'Options (at least 2 required)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _optionControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                          ),
                          onPressed: _optionControllers.length > 2
                              ? () => _deleteOption(index)
                              : null,
                          tooltip: 'Delete Option',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: _addOption,
                    tooltip: 'Add Option',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.questionToEdit == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _clearForm,
                    ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(
                        widget.questionToEdit != null ? Icons.edit : Icons.add),
                    label: Text(widget.questionToEdit != null
                        ? 'Update Question'
                        : 'Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _addOrUpdateQuestion,
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
