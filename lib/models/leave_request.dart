import 'package:cloud_firestore/cloud_firestore.dart';

/// 休暇申請
class LeaveRequest {
  final String id;
  final String userId;           // 申請者の社員番号
  final String companyId;        // 所属会社ID
  final LeaveType type;          // 休暇種別
  final DateTime startDate;      // 開始日
  final DateTime endDate;        // 終了日
  final String reason;           // 理由
  final LeaveStatus status;      // 承認状態
  final DateTime createdAt;      // 申請日時
  final String? approverComment; // 承認者コメント
  final DateTime? approvedAt;    // 承認日時

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    DateTime? createdAt,
    this.approverComment,
    this.approvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 申請から開始日までの日数
  int get daysUntilStart {
    return startDate.difference(createdAt).inDays;
  }

  /// 休暇日数
  int get leaveDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Firestore への保存用（DateTime は Timestamp に変換）
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'companyId': companyId,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approverComment': approverComment,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  /// Firestore からの取得用（Timestamp は DateTime に変換）
  factory LeaveRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return LeaveRequest(
      id: id,
      userId: data['userId'] as String,
      companyId: data['companyId'] as String,
      type: LeaveType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => LeaveType.paidLeave,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] as String,
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LeaveStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approverComment: data['approverComment'] as String?,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @Deprecated('Use toFirestore() instead')
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  @Deprecated('Use fromFirestore() instead')
  factory LeaveRequest.fromJson(Map<String, dynamic> json, String id) {
    return LeaveRequest.fromFirestore(json, id);
  }
}

/// 休暇種別
enum LeaveType {
  paidLeave,      // 有給休暇
  specialLeave,   // 特別休暇
  absence,        // 欠勤届
  compensatory,   // 代休届
}

extension LeaveTypeExtension on LeaveType {
  String get displayName {
    switch (this) {
      case LeaveType.paidLeave:
        return '有給休暇';
      case LeaveType.specialLeave:
        return '特別休暇';
      case LeaveType.absence:
        return '欠勤届';
      case LeaveType.compensatory:
        return '代休届';
    }
  }

  /// 最低申請日数（何日前までに申請が必要か）
  int get minimumDaysBeforeStart {
    switch (this) {
      case LeaveType.paidLeave:
        return 14; // 14日前まで
      case LeaveType.specialLeave:
        return 7;  // 7日前まで
      case LeaveType.absence:
        return 0;  // 当日可
      case LeaveType.compensatory:
        return 3;  // 3日前まで
    }
  }
}

/// 承認状態
enum LeaveStatus {
  pending,   // 承認待ち
  approved,  // 承認済み
  rejected,  // 却下
  cancelled, // 取り消し
}

extension LeaveStatusExtension on LeaveStatus {
  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return '承認待ち';
      case LeaveStatus.approved:
        return '承認済み';
      case LeaveStatus.rejected:
        return '却下';
      case LeaveStatus.cancelled:
        return '取り消し';
    }
  }
}
