class EducationItem {
  String id;
  String title;
  String description;
  String category;
  int durationMinutes;
  bool isRequired;
  int order;

  EducationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.isRequired,
    required this.order,
  });
  
  // Compatibility getters
  String get content => description;
  List<String> get keyPoints => [];
  List<QuizQuestion> get quizQuestions => [];
  int get estimatedMinutes => durationMinutes;
  int get orderIndex => order;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'durationMinutes': durationMinutes,
      'isRequired': isRequired,
      'order': order,
    };
  }

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      description: json['description'] ?? json['content'] ?? '',
      durationMinutes: json['durationMinutes'] ?? json['estimatedMinutes'] ?? 15,
      isRequired: json['isRequired'] ?? false,
      order: json['order'] ?? json['orderIndex'] ?? 0,
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
