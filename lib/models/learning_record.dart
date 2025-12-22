class LearningRecord {
  String id;
  String userId;
  String educationItemId;
  DateTime completedAt;
  int durationMinutes;
  String notes;

  LearningRecord({
    this.id = '',
    required this.userId,
    required this.educationItemId,
    required this.completedAt,
    required this.durationMinutes,
    this.notes = '',
  });
  
  // Compatibility getters
  String get educationTitle => '';
  String get category => '';
  DateTime get startTime => completedAt;
  DateTime get endTime => completedAt.add(Duration(minutes: durationMinutes));
  bool get completed => true;
  int? get quizScore => null;
  int? get totalQuestions => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'educationItemId': educationItemId,
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  factory LearningRecord.fromJson(Map<String, dynamic> json) {
    return LearningRecord(
      id: json['id'] ?? '',
      userId: json['userId'],
      educationItemId: json['educationItemId'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : (json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now()),
      durationMinutes: json['durationMinutes'] ?? 0,
      notes: json['notes'] ?? '',
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
