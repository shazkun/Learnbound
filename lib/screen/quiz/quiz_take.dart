import 'package:animate_do/animate_do.dart';

import 'package:flutter/material.dart';
import 'package:learnbound/models/question.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/screen/quiz/audio_handler.dart';
import 'package:learnbound/screen/quiz/quiz_stats.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/design/appbar.dart';

class QuizTakingScreen extends StatefulWidget {
  final List<Question> questions;

  const QuizTakingScreen({
    super.key,
    required this.questions,
  });

  @override
  _QuizTakingScreenState createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen>
    with WidgetsBindingObserver {
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
  final AudioService _audioService = AudioService(); // Initialize AudioService

  String reviewFilter = 'all';

  @override
  void initState() {
    super.initState();

    if (widget.questions.isEmpty) return;

    WidgetsBinding.instance.addObserver(this);

    userAnswers = List.generate(widget.questions.length, (_) => {});
    answeredCorrectly = List.filled(widget.questions.length, false);
    resetAnswer();

    Future.delayed(Duration(seconds: 1), () {
      _audioService.playBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _audioService.dispose(); // Dispose audio service
    shortAnswerController.dispose();
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> submitAnswer() async {
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

    if (_audioService.isSoundEnabled) {
      await _audioService.pauseBackgroundMusic();

      if (isCorrect) {
        await _audioService.playSfx('assets/audio/correct.mp3');
      } else {
        await _audioService.playSfx('assets/audio/incorrect.mp3');
      }

      await Future.delayed(const Duration(milliseconds: 700));
      await _audioService.resumeBackgroundMusic();
    }
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
    // _audioService.playBackgroundMusic(); // Update music for review mode
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
    _audioService.stopBackgroundMusic();
    // _audioService.playSfx("assets/audio/finish.mp3");
    Navigator.push(
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

  void toggleSound() {
    setState(() {
      _audioService.toggleSound();
    }); // Update UI to reflect sound state
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBarCustom(
          titleText: "Assessment",
          showBackButton: true,
          onBackPressed: () async {
            return CustomExitDialog.show(context,
                usePushReplacement: true, targetPage: HomeScreen());
          },
        ),
        body: const Center(
          child: Text(
            'No questions available.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final question = widget.questions[currentQuestionIndex];
    final filteredIndexes =
        List.generate(widget.questions.length, (i) => i).where((i) {
      if (reviewFilter == 'correct') return answeredCorrectly[i];
      if (reviewFilter == 'wrong') return !answeredCorrectly[i];
      return true; // 'all'
    }).toList();

    return WillPopScope(
      onWillPop: () async {
        _audioService.stopBackgroundMusic();
        return CustomExitDialog.show(context);
      },
      child: Scaffold(
        appBar: AppBarCustom(
          showBackButton: false,
          onBackPressed: () {
            return CustomExitDialog.show(context, targetPage: HomeScreen());
          },
          titleText: isReviewMode ? 'Review Answers' : 'Assessment',
          backgroundColor: const Color(0xFFD7C19C),
          titleColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(
                _audioService.isSoundEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.black,
              ),
              onPressed: toggleSound,
              tooltip:
                  _audioService.isSoundEnabled ? 'Mute Sound' : 'Unmute Sound',
            ),
          ],
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
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
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
                ToggleButtons(
                  borderRadius: BorderRadius.circular(20), // round edges here
                  isSelected: [
                    reviewFilter == 'all',
                    reviewFilter == 'correct',
                    reviewFilter == 'wrong'
                  ],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0)
                        reviewFilter = 'all';
                      else if (index == 1)
                        reviewFilter = 'correct';
                      else
                        reviewFilter = 'wrong';
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('All'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Correct'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Wrong'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // itemCount: widget.questions.length,
                  // itemBuilder: (context, index) {
                  //   final question = widget.questions[index];
                  //   final answer = userAnswers[index];
                  //   final isAnsweredCorrectly = answeredCorrectly[index];
                  itemCount: filteredIndexes.length,
                  itemBuilder: (context, index) {
                    final actualIndex = filteredIndexes[index];
                    final question = widget.questions[actualIndex];
                    final answer = userAnswers[actualIndex];
                    final isAnsweredCorrectly = answeredCorrectly[actualIndex];

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
              ],
            ],
          ),
        ),

        floatingActionButton: isReviewMode
            ? FloatingActionButton(
                onPressed: goToStatisticsScreen,
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                heroTag: 'finishButton',
                tooltip: 'Result',
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.black,
                ),
              )
            : null, // Don't show anything if condition is false

        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
