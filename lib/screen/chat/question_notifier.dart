import 'package:flutter/foundation.dart';

class QuestionsProvider with ChangeNotifier {
  final List<String> _questions = [];
  final Map<String, List<String>> _multipleChoiceQuestions = {};
  final Map<String, String?> _selectedAnswers = {};
  final Set<String> _confirmedAnswers = {};

  List<String> get questions => _questions;
  Map<String, List<String>> get multipleChoiceQuestions =>
      _multipleChoiceQuestions;
  Map<String, String?> get selectedAnswers => _selectedAnswers;
  Set<String> get confirmedAnswers => _confirmedAnswers;

  void addQuestion(String question) {
    _questions.add(question);
    notifyListeners();
  }

  void addMultipleChoiceQuestion(String question, List<String> options) {
    _multipleChoiceQuestions[question] = options;
    notifyListeners();
  }

  void removeQuestion(String question) {
    _questions.remove(question);
    _multipleChoiceQuestions.remove(question);
    _selectedAnswers.remove(question);
    _confirmedAnswers.remove(question);
    notifyListeners();
  }

  void selectAnswer(String question, String? answer) {
    _selectedAnswers[question] = answer;
    if (answer != null) {
      _confirmedAnswers.add(question);
    }
    notifyListeners();
  }

  void clearAll() {
    _questions.clear();
    _multipleChoiceQuestions.clear();
    _selectedAnswers.clear();
    _confirmedAnswers.clear();
    notifyListeners();
  }
}
