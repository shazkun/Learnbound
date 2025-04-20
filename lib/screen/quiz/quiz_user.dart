import 'package:learnbound/screen/quiz/question_model.dart';
import 'package:learnbound/screen/quiz/stats_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class QuizTakingScreen extends StatefulWidget {
  final List<Question> questions;

  const QuizTakingScreen({
    super.key,
    required this.questions,
  });

  @override
  _QuizTakingScreenState createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int currentQuestionIndex = 0;
  int? selectedOption;
  List<bool> selectedOptions = [];
  bool showFeedback = false;
  bool isCorrect = false;
  int score = 0;
  bool isReviewMode = false;
  String? errorMessage;

  List<bool> answeredCorrectly = [];
  List<Map<String, dynamic>> userAnswers = [];

  final TextEditingController shortAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userAnswers = List.generate(widget.questions.length, (_) => {});
    answeredCorrectly = List.filled(widget.questions.length, false);
    resetAnswer(); // Initialize selectedOptions based on the first question
  }

  @override
  void dispose() {
    shortAnswerController.dispose();
    super.dispose();
  }

  void resetAnswer() {
    final question = widget.questions[currentQuestionIndex];
    shortAnswerController.clear();
    selectedOption = null;
    selectedOptions = List.filled(question.options.length, false);
    showFeedback = false;
    isCorrect = false;
    errorMessage = null;
  }

  bool hasAnswered() {
    final question = widget.questions[currentQuestionIndex];
    if (question.type == QuestionType.shortAnswer) {
      return shortAnswerController.text.trim().isNotEmpty;
    } else if (question.type == QuestionType.multipleChoice) {
      return selectedOption != null;
    } else {
      return selectedOptions.any((selected) => selected);
    }
  }

  void submitAnswer() {
    if (!hasAnswered()) {
      setState(
          () => errorMessage = 'Please provide an answer before submitting.');
      return;
    }

    final question = widget.questions[currentQuestionIndex];
    setState(() {
      errorMessage = null;
      showFeedback = true;

      if (question.type == QuestionType.shortAnswer) {
        final userInput = shortAnswerController.text.trim().toLowerCase();
        isCorrect = userInput == question.correctAnswer.trim().toLowerCase();
        userAnswers[currentQuestionIndex] = {
          'answer': shortAnswerController.text
        };
      } else if (question.type == QuestionType.multipleChoice) {
        isCorrect = selectedOption != null &&
            question.options[selectedOption!].isCorrect;
        userAnswers[currentQuestionIndex] = {'selectedOption': selectedOption};
      } else {
        isCorrect = question.options.asMap().entries.every(
            (entry) => entry.value.isCorrect == selectedOptions[entry.key]);
        userAnswers[currentQuestionIndex] = {
          'selectedOptions': List.from(selectedOptions),
        };
      }

      if (isCorrect && !answeredCorrectly[currentQuestionIndex]) {
        score++;
        answeredCorrectly[currentQuestionIndex] = true;
      }
    });
  }

  void nextQuestion() {
    if (!isReviewMode && !showFeedback && !hasAnswered()) {
      setState(
          () => errorMessage = 'Please submit an answer before proceeding.');
      return;
    }

    if (isReviewMode) {
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          loadUserAnswer();
        });
      } else {
        goToStatisticsScreen();
      }
    } else {
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetAnswer();
        });
      } else {
        enterReviewMode();
      }
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        if (isReviewMode) {
          loadUserAnswer();
        } else {
          resetAnswer();
        }
      });
    }
  }

  void enterReviewMode() {
    setState(() {
      isReviewMode = true;
      currentQuestionIndex = 0;
      loadUserAnswer();
    });
  }

  void loadUserAnswer() {
    final question = widget.questions[currentQuestionIndex];
    final answer = userAnswers[currentQuestionIndex];
    shortAnswerController.text = answer['answer'] ?? '';
    selectedOption = answer['selectedOption'] as int?;
    selectedOptions = answer['selectedOptions'] != null
        ? List<bool>.from(answer['selectedOptions'])
        : List.filled(question.options.length, false);

    setState(() {
      showFeedback = true;
      if (question.type == QuestionType.shortAnswer) {
        isCorrect = shortAnswerController.text.trim().toLowerCase() ==
            question.correctAnswer.trim().toLowerCase();
      } else if (question.type == QuestionType.multipleChoice) {
        isCorrect = selectedOption != null &&
            question.options[selectedOption!].isCorrect;
      } else {
        isCorrect = question.options.asMap().entries.every(
            (entry) => entry.value.isCorrect == selectedOptions[entry.key]);
      }
    });
  }

  void goToStatisticsScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          score: score,
          totalQuestions: widget.questions.length,
          timeTaken: 'No timer mode',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = widget.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isReviewMode ? 'Review Answers' : 'Assessment'),
        backgroundColor: const Color(0xFFD7C19C),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isReviewMode) ...[
              FadeInDown(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${currentQuestionIndex + 1}/${widget.questions.length}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.text,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (question.type == QuestionType.shortAnswer)
                          TextField(
                            controller: shortAnswerController,
                            enabled: !(showFeedback || isReviewMode),
                            decoration: const InputDecoration(
                              labelText: 'Your Answer',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        if (question.type == QuestionType.multipleChoice)
                          ...question.options.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            return RadioListTile<int>(
                              title: Text(option.text),
                              value: index,
                              groupValue: selectedOption,
                              onChanged: (showFeedback || isReviewMode)
                                  ? null
                                  : (value) {
                                      setState(() {
                                        selectedOption = value;
                                        errorMessage = null;
                                      });
                                    },
                            );
                          }),
                        if (question.type == QuestionType.selectMultiple)
                          ...question.options.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            return CheckboxListTile(
                              title: Text(option.text),
                              value: selectedOptions[index],
                              onChanged: (showFeedback || isReviewMode)
                                  ? null
                                  : (value) {
                                      setState(() {
                                        selectedOptions[index] = value!;
                                        errorMessage = null;
                                      });
                                    },
                            );
                          }),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (showFeedback) ...[
                          Text(
                            isCorrect ? 'Correct!' : 'Incorrect',
                            style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (!isCorrect &&
                              question.type == QuestionType.shortAnswer)
                            Text('Correct Answer: ${question.correctAnswer}'),
                          if (question.type != QuestionType.shortAnswer)
                            Text(
                              'Correct Options: ${question.options.where((o) => o.isCorrect).map((o) => o.text).join(", ")}',
                            ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: isReviewMode || showFeedback
                                  ? nextQuestion
                                  : submitAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(211, 172, 112, 1.0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                              child: Text(
                                isReviewMode
                                    ? (currentQuestionIndex <
                                            widget.questions.length - 1
                                        ? 'Next'
                                        : 'Finish')
                                    : (showFeedback
                                        ? (currentQuestionIndex <
                                                widget.questions.length - 1
                                            ? 'Next'
                                            : 'Review')
                                        : 'Submit'),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  final answer = userAnswers[index];
                  final isAnsweredCorrectly = answeredCorrectly[index] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${index + 1}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAnsweredCorrectly ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              color: isAnsweredCorrectly
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (question.type == QuestionType.shortAnswer)
                            Text(
                                'Your answer: ${answer['answer'] ?? 'No answer provided'}'),
                          if (question.type == QuestionType.multipleChoice)
                            Text(
                                'Your answer: ${answer['selectedOption'] != null ? question.options[answer['selectedOption']].text : 'No answer selected'}'),
                          if (question.type == QuestionType.selectMultiple)
                            Text(
                                'Your options: ${answer['selectedOptions'] != null ? List.generate(question.options.length, (i) => answer['selectedOptions'][i] ? question.options[i].text : '').where((text) => text.isNotEmpty).join(", ") : 'No options selected'}'),
                          if (question.type == QuestionType.shortAnswer &&
                              !isAnsweredCorrectly)
                            Text('Correct answer: ${question.correctAnswer}'),
                          if (question.type != QuestionType.shortAnswer &&
                              !isAnsweredCorrectly)
                            Text(
                              'Correct options: ${question.options.where((o) => o.isCorrect).map((o) => o.text).join(", ")}',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: goToStatisticsScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child:
                    const Text('Finish', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
