/// 国土交通省による各種診断の記録モデル
class MedicalCheckup {
  String id;
  String userId;
  MedicalCheckupType type;
  DateTime checkupDate;
  DateTime nextDueDate;
  String institution;
  String certificateNumber;
  String notes;

  MedicalCheckup({
    this.id = '',
    required this.userId,
    required this.type,
    required this.checkupDate,
    required this.nextDueDate,
    this.institution = '',
    this.certificateNumber = '',
    this.notes = '',
  });
  
  // Compatibility getters
  bool get notificationSent => false;
  DateTime get createdAt => checkupDate;
  DateTime get updatedAt => checkupDate;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'checkupDate': checkupDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'institution': institution,
      'certificateNumber': certificateNumber,
      'notes': notes,
    };
  }

  factory MedicalCheckup.fromJson(Map<String, dynamic> json) {
    final checkupDate = DateTime.parse(json['checkupDate']);
    final type = MedicalCheckupType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MedicalCheckupType.tekireishindan,
    );
    
    return MedicalCheckup(
      id: json['id'] ?? '',
      userId: json['userId'],
      type: type,
      checkupDate: checkupDate,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'])
          : type.calculateNextDueDate(checkupDate),
      institution: json['institution'] ?? '',
      certificateNumber: json['certificateNumber'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  MedicalCheckup copyWith({
    String? id,
    String? userId,
    MedicalCheckupType? type,
    DateTime? checkupDate,
    DateTime? nextDueDate,
    String? institution,
    String? certificateNumber,
    String? notes,
  }) {
    return MedicalCheckup(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      checkupDate: checkupDate ?? this.checkupDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      institution: institution ?? this.institution,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      notes: notes ?? this.notes,
    );
  }
}

/// 国土交通省による各種診断の種類
enum MedicalCheckupType {
  tekireishindan, // 適齢診断 (65歳以上の運転者)
  shoninshindan, // 初任診断 (新規採用運転者)
  tekiseishindan, // 適性診断 (全運転者対象)
  jikojakkiuntensha, // 事故惹起運転者診断
  tokutei1, // 特定診断Ⅰ (65歳以上で初めて運転者となる場合)
  tokutei2, // 特定診断Ⅱ (高齢運転者の適性診断)
}

extension MedicalCheckupTypeExtension on MedicalCheckupType {
  String get displayName {
    switch (this) {
      case MedicalCheckupType.tekireishindan:
        return '適齢診断';
      case MedicalCheckupType.shoninshindan:
        return '初任診断';
      case MedicalCheckupType.tekiseishindan:
        return '適性診断';
      case MedicalCheckupType.jikojakkiuntensha:
        return '事故惹起運転者診断';
      case MedicalCheckupType.tokutei1:
        return '特定診断Ⅰ';
      case MedicalCheckupType.tokutei2:
        return '特定診断Ⅱ';
    }
  }

  String get description {
    switch (this) {
      case MedicalCheckupType.tekireishindan:
        return '65歳以上の運転者が対象\n適齢診断は65歳到達時から3年ごとに受診';
      case MedicalCheckupType.shoninshindan:
        return '新規採用運転者が対象\n採用後1年以内に受診が義務';
      case MedicalCheckupType.tekiseishindan:
        return '全運転者が対象\n一般診断として定期的に受診';
      case MedicalCheckupType.jikojakkiuntensha:
        return '死亡・重傷事故を起こした運転者が対象\n事故後速やかに受診が義務';
      case MedicalCheckupType.tokutei1:
        return '65歳以上で初めて運転者となる場合が対象\n採用前または採用後1ヶ月以内に受診';
      case MedicalCheckupType.tokutei2:
        return '高齢運転者の特別な適性診断\n75歳以上の運転者が対象';
    }
  }

  /// 次回診断予定日を計算 (診断種別ごとの推奨期間)
  DateTime calculateNextDueDate(DateTime checkupDate) {
    switch (this) {
      case MedicalCheckupType.tekireishindan:
        // 適齢診断: 3年ごと
        return DateTime(
          checkupDate.year + 3,
          checkupDate.month,
          checkupDate.day,
        );
      case MedicalCheckupType.shoninshindan:
        // 初任診断: 1回のみ (次回なし)
        return DateTime(
          checkupDate.year + 10,
          checkupDate.month,
          checkupDate.day,
        );
      case MedicalCheckupType.tekiseishindan:
        // 適性診断: 推奨は年1回
        return DateTime(
          checkupDate.year + 1,
          checkupDate.month,
          checkupDate.day,
        );
      case MedicalCheckupType.jikojakkiuntensha:
        // 事故惹起運転者診断: 事故ごとに1回 (次回なし)
        return DateTime(
          checkupDate.year + 10,
          checkupDate.month,
          checkupDate.day,
        );
      case MedicalCheckupType.tokutei1:
        // 特定診断Ⅰ: 1回のみ (次回なし)
        return DateTime(
          checkupDate.year + 10,
          checkupDate.month,
          checkupDate.day,
        );
      case MedicalCheckupType.tokutei2:
        // 特定診断Ⅱ: 2年ごと
        return DateTime(
          checkupDate.year + 2,
          checkupDate.month,
          checkupDate.day,
        );
    }
  }

  /// 義務診断かどうか
  bool get isMandatory {
    switch (this) {
      case MedicalCheckupType.tekireishindan:
        return true; // 65歳以上は義務
      case MedicalCheckupType.shoninshindan:
        return true; // 新規採用は義務
      case MedicalCheckupType.jikojakkiuntensha:
        return true; // 事故後は義務
      case MedicalCheckupType.tokutei1:
        return true; // 65歳以上の新規は義務
      case MedicalCheckupType.tokutei2:
        return true; // 75歳以上は義務
      case MedicalCheckupType.tekiseishindan:
        return false; // 推奨だが義務ではない
    }
  }

  /// 通知する日数 (診断予定日の何日前に通知するか)
  int get notificationDaysBefore {
    switch (this) {
      case MedicalCheckupType.tekireishindan:
        return 60; // 2ヶ月前
      case MedicalCheckupType.shoninshindan:
        return 30; // 1ヶ月前
      case MedicalCheckupType.tekiseishindan:
        return 30; // 1ヶ月前
      case MedicalCheckupType.jikojakkiuntensha:
        return 7; // 1週間前
      case MedicalCheckupType.tokutei1:
        return 30; // 1ヶ月前
      case MedicalCheckupType.tokutei2:
        return 60; // 2ヶ月前
    }
  }
}
