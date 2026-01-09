import 'package:cloud_firestore/cloud_firestore.dart';

/// 教育記録簿モデル
/// 監査・法定フォーマット用の教育実施記録
class EducationRegister {
  final String recordId;
  final String driverId;
  final String driverName;
  final DateTime date;
  final String content;
  final int durationMinutes;
  final String instructor;
  final String category;
  final String companyId;
  final String? notes;
  final DateTime createdAt;

  EducationRegister({
    required this.recordId,
    required this.driverId,
    required this.driverName,
    required this.date,
    required this.content,
    required this.durationMinutes,
    required this.instructor,
    required this.category,
    required this.companyId,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Firestore からの変換
  factory EducationRegister.fromFirestore(Map<String, dynamic> data) {
    return EducationRegister(
      recordId: data['recordId'] ?? data['record_id'] ?? data['id'] ?? '',
      driverId: data['driverId'] ?? data['driver_id'] ?? data['userId'] ?? data['user_id'] ?? '',
      driverName: data['driverName'] ?? data['driver_name'] ?? data['userName'] ?? data['user_name'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      content: data['content'] ?? '',
      durationMinutes: data['durationMinutes'] ?? data['duration_minutes'] ?? data['duration'] ?? 0,
      instructor: data['instructor'] ?? '',
      category: data['category'] ?? '',
      companyId: data['companyId'] ?? data['company_id'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 (data['created_at'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
    );
  }

  /// Firestore への変換
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'record_id': recordId,
      'driverId': driverId,
      'driver_id': driverId,
      'driverName': driverName,
      'driver_name': driverName,
      'date': Timestamp.fromDate(date),
      'content': content,
      'durationMinutes': durationMinutes,
      'duration_minutes': durationMinutes,
      'instructor': instructor,
      'category': category,
      'companyId': companyId,
      'company_id': companyId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// 教育時間を「時間:分」形式で取得
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}時間${minutes}分';
    } else {
      return '${minutes}分';
    }
  }

  /// カテゴリー日本語名取得
  static String getCategoryLabel(String category) {
    switch (category) {
      case 'law':
        return '法令知識';
      case 'safety':
        return '安全運転';
      case 'service':
        return '接客サービス';
      case 'vehicle':
        return '車両知識';
      case 'emergency':
        return '緊急時対応';
      case 'health':
        return '健康管理';
      default:
        return category;
    }
  }

  /// コピーコンストラクタ
  EducationRegister copyWith({
    String? recordId,
    String? driverId,
    String? driverName,
    DateTime? date,
    String? content,
    int? durationMinutes,
    String? instructor,
    String? category,
    String? companyId,
    String? notes,
    DateTime? createdAt,
  }) {
    return EducationRegister(
      recordId: recordId ?? this.recordId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      date: date ?? this.date,
      content: content ?? this.content,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      instructor: instructor ?? this.instructor,
      category: category ?? this.category,
      companyId: companyId ?? this.companyId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 年度別教育記録サマリー
class EducationRegisterSummary {
  final int year;
  final String companyId;
  final List<EducationRegister> records;
  final DateTime generatedAt;

  EducationRegisterSummary({
    required this.year,
    required this.companyId,
    required this.records,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// 総教育時間（分）
  int get totalDurationMinutes {
    return records.fold(0, (sum, record) => sum + record.durationMinutes);
  }

  /// 総教育時間（時間）
  double get totalDurationHours {
    return totalDurationMinutes / 60.0;
  }

  /// 教育実施回数
  int get totalSessions {
    return records.length;
  }

  /// 対象乗務員数
  int get totalDrivers {
    return records.map((r) => r.driverId).toSet().length;
  }

  /// カテゴリー別集計
  Map<String, int> get categorySummary {
    final summary = <String, int>{};
    for (var record in records) {
      final label = EducationRegister.getCategoryLabel(record.category);
      summary[label] = (summary[label] ?? 0) + 1;
    }
    return summary;
  }

  /// 乗務員別集計
  Map<String, List<EducationRegister>> get driverRecords {
    final summary = <String, List<EducationRegister>>{};
    for (var record in records) {
      if (!summary.containsKey(record.driverId)) {
        summary[record.driverId] = [];
      }
      summary[record.driverId]!.add(record);
    }
    return summary;
  }
}
