import 'package:cloud_firestore/cloud_firestore.dart';

/// 事故報告
class AccidentReport {
  final String id;
  final String driverId;           // 報告者の社員番号
  final String driverName;         // 報告者氏名
  final String companyId;          // 所属会社ID
  final DateTime accidentDate;     // 事故発生日時
  final String location;           // 事故発生場所
  final AccidentType type;         // 事故種別
  final AccidentSeverity severity; // 事故の重大度
  final String description;        // 事故状況の詳細
  final String? otherPartyInfo;    // 相手方情報
  final String? damageDescription; // 被害状況
  final String? policeReport;      // 警察への届出番号
  final AccidentStatus status;     // 処理状態
  final DateTime createdAt;        // 報告日時
  final String? adminComment;      // 管理者コメント
  final DateTime? processedAt;     // 処理日時

  AccidentReport({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.companyId,
    required this.accidentDate,
    required this.location,
    required this.type,
    required this.severity,
    required this.description,
    this.otherPartyInfo,
    this.damageDescription,
    this.policeReport,
    required this.status,
    DateTime? createdAt,
    this.adminComment,
    this.processedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Firestore への保存用（DateTime は Timestamp に変換）
  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'companyId': companyId,
      'accidentDate': Timestamp.fromDate(accidentDate),
      'location': location,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'otherPartyInfo': otherPartyInfo,
      'damageDescription': damageDescription,
      'policeReport': policeReport,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminComment': adminComment,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  /// Firestore からの取得用（Timestamp は DateTime に変換）
  factory AccidentReport.fromFirestore(Map<String, dynamic> data, String id) {
    return AccidentReport(
      id: id,
      driverId: data['driverId'] as String,
      driverName: data['driverName'] as String,
      companyId: data['companyId'] as String,
      accidentDate: (data['accidentDate'] as Timestamp).toDate(),
      location: data['location'] as String,
      type: AccidentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AccidentType.collision,
      ),
      severity: AccidentSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => AccidentSeverity.minor,
      ),
      description: data['description'] as String,
      otherPartyInfo: data['otherPartyInfo'] as String?,
      damageDescription: data['damageDescription'] as String?,
      policeReport: data['policeReport'] as String?,
      status: AccidentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AccidentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      adminComment: data['adminComment'] as String?,
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @Deprecated('Use toFirestore() instead')
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  @Deprecated('Use fromFirestore() instead')
  factory AccidentReport.fromJson(Map<String, dynamic> json, String id) {
    return AccidentReport.fromFirestore(json, id);
  }
}

/// 事故種別
enum AccidentType {
  collision,      // 接触事故
  personal,       // 人身事故
  property,       // 物損事故
  selfAccident,   // 自損事故
  parking,        // 駐車場内事故
  other,          // その他
}

extension AccidentTypeExtension on AccidentType {
  String get displayName {
    switch (this) {
      case AccidentType.collision:
        return '接触事故';
      case AccidentType.personal:
        return '人身事故';
      case AccidentType.property:
        return '物損事故';
      case AccidentType.selfAccident:
        return '自損事故';
      case AccidentType.parking:
        return '駐車場内事故';
      case AccidentType.other:
        return 'その他';
    }
  }
}

/// 事故の重大度
enum AccidentSeverity {
  minor,     // 軽微
  moderate,  // 中程度
  serious,   // 重大
  critical,  // 最重大
}

extension AccidentSeverityExtension on AccidentSeverity {
  String get displayName {
    switch (this) {
      case AccidentSeverity.minor:
        return '軽微';
      case AccidentSeverity.moderate:
        return '中程度';
      case AccidentSeverity.serious:
        return '重大';
      case AccidentSeverity.critical:
        return '最重大';
    }
  }
}

/// 処理状態
enum AccidentStatus {
  pending,      // 未処理
  processing,   // 処理中
  completed,    // 完了
}

extension AccidentStatusExtension on AccidentStatus {
  String get displayName {
    switch (this) {
      case AccidentStatus.pending:
        return '未処理';
      case AccidentStatus.processing:
        return '処理中';
      case AccidentStatus.completed:
        return '完了';
    }
  }
}
