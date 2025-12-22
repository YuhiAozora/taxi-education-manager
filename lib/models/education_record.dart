import 'package:cloud_firestore/cloud_firestore.dart';

/// 教育台帳モデル - 運転手の全記録を統合管理
class EducationRecord {
  final String userId; // 社員番号
  final String userName; // 氏名
  final String companyId; // 会社ID
  final DateTime joinDate; // 入社日
  final int experienceYears; // 経験年数
  final String licenseType; // 運転免許証の種類
  final DateTime? licenseExpiry; // 免許証有効期限
  
  // 教育実績
  final List<EducationHistory> educationHistory;
  
  // 健康診断記録
  final List<MedicalCheckupRecord> medicalCheckups;
  
  // 整備点検記録
  final List<VehicleInspectionRecord> vehicleInspections;
  
  // 休暇・勤怠記録
  final List<LeaveRecord> leaveRecords;
  
  // 事故報告記録
  final List<AccidentRecord> accidentRecords;
  
  // 特記事項（管理者コメント）
  final String? adminNotes;
  final DateTime? lastUpdated;

  EducationRecord({
    required this.userId,
    required this.userName,
    required this.companyId,
    required this.joinDate,
    required this.experienceYears,
    required this.licenseType,
    this.licenseExpiry,
    required this.educationHistory,
    required this.medicalCheckups,
    required this.vehicleInspections,
    required this.leaveRecords,
    required this.accidentRecords,
    this.adminNotes,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'companyId': companyId,
      'joinDate': Timestamp.fromDate(joinDate),
      'experienceYears': experienceYears,
      'licenseType': licenseType,
      'licenseExpiry': licenseExpiry != null 
          ? Timestamp.fromDate(licenseExpiry!) 
          : null,
      'educationHistory': educationHistory.map((e) => e.toJson()).toList(),
      'medicalCheckups': medicalCheckups.map((e) => e.toJson()).toList(),
      'vehicleInspections': vehicleInspections.map((e) => e.toJson()).toList(),
      'leaveRecords': leaveRecords.map((e) => e.toJson()).toList(),
      'accidentRecords': accidentRecords.map((e) => e.toJson()).toList(),
      'adminNotes': adminNotes,
      'lastUpdated': lastUpdated != null 
          ? Timestamp.fromDate(lastUpdated!) 
          : Timestamp.now(),
    };
  }

  factory EducationRecord.fromFirestore(Map<String, dynamic> data) {
    return EducationRecord(
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      experienceYears: data['experienceYears'] as int? ?? 0,
      licenseType: data['licenseType'] as String? ?? '普通二種',
      licenseExpiry: (data['licenseExpiry'] as Timestamp?)?.toDate(),
      educationHistory: (data['educationHistory'] as List<dynamic>?)
              ?.map((e) => EducationHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      medicalCheckups: (data['medicalCheckups'] as List<dynamic>?)
              ?.map((e) => MedicalCheckupRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vehicleInspections: (data['vehicleInspections'] as List<dynamic>?)
              ?.map((e) => VehicleInspectionRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      leaveRecords: (data['leaveRecords'] as List<dynamic>?)
              ?.map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      accidentRecords: (data['accidentRecords'] as List<dynamic>?)
              ?.map((e) => AccidentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      adminNotes: data['adminNotes'] as String?,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

/// 教育実績履歴
class EducationHistory {
  final DateTime completedAt;
  final String itemTitle;
  final int durationMinutes;
  final int score;
  final String category;

  EducationHistory({
    required this.completedAt,
    required this.itemTitle,
    required this.durationMinutes,
    required this.score,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'completedAt': Timestamp.fromDate(completedAt),
      'itemTitle': itemTitle,
      'durationMinutes': durationMinutes,
      'score': score,
      'category': category,
    };
  }

  factory EducationHistory.fromJson(Map<String, dynamic> json) {
    return EducationHistory(
      completedAt: (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemTitle: json['itemTitle'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      category: json['category'] as String? ?? '',
    );
  }
}

/// 健康診断記録
class MedicalCheckupRecord {
  final DateTime checkupDate;
  final String result; // '適性あり', '要注意', '不適'
  final DateTime? nextScheduled;
  final String? notes;

  MedicalCheckupRecord({
    required this.checkupDate,
    required this.result,
    this.nextScheduled,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'checkupDate': Timestamp.fromDate(checkupDate),
      'result': result,
      'nextScheduled': nextScheduled != null 
          ? Timestamp.fromDate(nextScheduled!) 
          : null,
      'notes': notes,
    };
  }

  factory MedicalCheckupRecord.fromJson(Map<String, dynamic> json) {
    return MedicalCheckupRecord(
      checkupDate: (json['checkupDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      result: json['result'] as String? ?? '適性あり',
      nextScheduled: (json['nextScheduled'] as Timestamp?)?.toDate(),
      notes: json['notes'] as String?,
    );
  }
}

/// 整備点検記録
class VehicleInspectionRecord {
  final DateTime inspectionDate;
  final int okCount;
  final int ngCount;
  final String? notes;

  VehicleInspectionRecord({
    required this.inspectionDate,
    required this.okCount,
    required this.ngCount,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'inspectionDate': Timestamp.fromDate(inspectionDate),
      'okCount': okCount,
      'ngCount': ngCount,
      'notes': notes,
    };
  }

  factory VehicleInspectionRecord.fromJson(Map<String, dynamic> json) {
    return VehicleInspectionRecord(
      inspectionDate: (json['inspectionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      okCount: json['okCount'] as int? ?? 0,
      ngCount: json['ngCount'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

/// 休暇記録
class LeaveRecord {
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType; // '有給休暇', '特別休暇', '欠勤届', '代休届'
  final String status; // '承認済み', '却下', '承認待ち'
  final String? approver;
  final DateTime? approvedAt;

  LeaveRecord({
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.status,
    this.approver,
    this.approvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'leaveType': leaveType,
      'status': status,
      'approver': approver,
      'approvedAt': approvedAt != null 
          ? Timestamp.fromDate(approvedAt!) 
          : null,
    };
  }

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leaveType: json['leaveType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      approver: json['approver'] as String?,
      approvedAt: (json['approvedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// 事故記録
class AccidentRecord {
  final DateTime accidentDate;
  final String location;
  final String type; // '物損事故', '人身事故', 'ニアミス', etc.
  final String severity; // '軽微', '通常', '重大', '極めて重大'
  final String status; // '報告済み', '処理中', '完了'
  final String? processingNotes;

  AccidentRecord({
    required this.accidentDate,
    required this.location,
    required this.type,
    required this.severity,
    required this.status,
    this.processingNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'accidentDate': Timestamp.fromDate(accidentDate),
      'location': location,
      'type': type,
      'severity': severity,
      'status': status,
      'processingNotes': processingNotes,
    };
  }

  factory AccidentRecord.fromJson(Map<String, dynamic> json) {
    return AccidentRecord(
      accidentDate: (json['accidentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: json['location'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      status: json['status'] as String? ?? '',
      processingNotes: json['processingNotes'] as String?,
    );
  }
}
