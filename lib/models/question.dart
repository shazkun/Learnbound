enum QuestionType { shortAnswer, multipleChoice, selectMultiple }

class Option {
  final String text;
  final bool isCorrect;

  Option({required this.text, required this.isCorrect});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isCorrect': isCorrect,
      };

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        text: json['text']?.toString() ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final String correctAnswer;
  final List<Option> options;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.correctAnswer = '',
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type.toString().split('.').last,
        'correctAnswer': correctAnswer,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    // Handle type parsing more safely
    String typeString = json['type']?.toString() ?? 'shortAnswer';
    QuestionType questionType;
    try {
      questionType = QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => QuestionType.shortAnswer,
      );
    } catch (e) {
      print('Error parsing question type "$typeString": $e');
      questionType = QuestionType.shortAnswer; // Fallback
    }

    return Question(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? '',
      type: questionType,
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => Option.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
