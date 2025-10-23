class LearningRecord {
  String id;
  String userId;
  String educationItemId;
  String educationTitle;
  String category;
  DateTime startTime;
  DateTime endTime;
  int durationMinutes;
  bool completed;
  int? quizScore;
  int? totalQuestions;

  LearningRecord({
    required this.id,
    required this.userId,
    required this.educationItemId,
    required this.educationTitle,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.completed = true,
    this.quizScore,
    this.totalQuestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'educationItemId': educationItemId,
      'educationTitle': educationTitle,
      'category': category,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
      'quizScore': quizScore,
      'totalQuestions': totalQuestions,
    };
  }

  factory LearningRecord.fromJson(Map<String, dynamic> json) {
    return LearningRecord(
      id: json['id'],
      userId: json['userId'],
      educationItemId: json['educationItemId'],
      educationTitle: json['educationTitle'],
      category: json['category'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      durationMinutes: json['durationMinutes'],
      completed: json['completed'] ?? true,
      quizScore: json['quizScore'],
      totalQuestions: json['totalQuestions'],
    );
  }

  String get formattedDate {
    return '${startTime.year}年${startTime.month}月${startTime.day}日';
  }

  String get formattedTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get scoreDisplay {
    if (quizScore != null && totalQuestions != null) {
      return '$quizScore/$totalQuestions';
    }
    return '-';
  }
}
