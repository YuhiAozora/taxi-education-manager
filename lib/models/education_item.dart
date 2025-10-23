class EducationItem {
  String id;
  String title;
  String category;
  String content;
  List<String> keyPoints;
  List<QuizQuestion> quizQuestions;
  int estimatedMinutes;
  int orderIndex;

  EducationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.keyPoints,
    required this.quizQuestions,
    this.estimatedMinutes = 15,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'content': content,
      'keyPoints': keyPoints,
      'quizQuestions': quizQuestions.map((q) => q.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'orderIndex': orderIndex,
    };
  }

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      content: json['content'],
      keyPoints: List<String>.from(json['keyPoints']),
      quizQuestions: (json['quizQuestions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      estimatedMinutes: json['estimatedMinutes'] ?? 15,
      orderIndex: json['orderIndex'] ?? 0,
    );
  }
}

class QuizQuestion {
  String question;
  List<String> options;
  int correctAnswerIndex;
  String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      explanation: json['explanation'],
    );
  }
}
