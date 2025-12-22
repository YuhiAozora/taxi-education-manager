import 'package:cloud_firestore/cloud_firestore.dart';

/// 契約状態
enum SubscriptionStatus {
  trial,      // 試用中（無料期間）
  active,     // 有効（支払い済み）
  suspended,  // 停止中（支払い遅延）
  cancelled,  // 解約済み
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get displayName {
    switch (this) {
      case SubscriptionStatus.trial:
        return '試用中';
      case SubscriptionStatus.active:
        return '有効';
      case SubscriptionStatus.suspended:
        return '停止中';
      case SubscriptionStatus.cancelled:
        return '解約済み';
    }
  }
  
  String get displayColor {
    switch (this) {
      case SubscriptionStatus.trial:
        return '#FFA726'; // オレンジ
      case SubscriptionStatus.active:
        return '#66BB6A'; // 緑
      case SubscriptionStatus.suspended:
        return '#EF5350'; // 赤
      case SubscriptionStatus.cancelled:
        return '#9E9E9E'; // グレー
    }
  }
  
  bool get isUsable {
    return this == SubscriptionStatus.trial || 
           this == SubscriptionStatus.active;
  }
}

/// 契約情報モデル
class Subscription {
  String id;                      // 契約ID
  String companyId;               // 会社ID
  SubscriptionStatus status;      // 契約状態
  DateTime startDate;             // 契約開始日
  DateTime? endDate;              // 契約終了日（nullの場合は継続中）
  DateTime? trialEndDate;         // 試用期間終了日
  int contractedDriverCount;      // 契約運転者数
  double monthlyFee;              // 月額料金
  DateTime? lastPaymentDate;      // 最終支払日
  DateTime? nextPaymentDate;      // 次回支払予定日
  String? notes;                  // 備考
  DateTime createdAt;             // 作成日時
  DateTime updatedAt;             // 更新日時

  Subscription({
    this.id = '',
    required this.companyId,
    this.status = SubscriptionStatus.trial,
    DateTime? startDate,
    this.endDate,
    this.trialEndDate,
    this.contractedDriverCount = 0,
    this.monthlyFee = 0,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : startDate = startDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 試用期間が終了しているか
  bool get isTrialExpired {
    if (status != SubscriptionStatus.trial) return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }
  
  /// 試用期間の残り日数
  int get trialDaysRemaining {
    if (trialEndDate == null) return 0;
    final remaining = trialEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  /// 契約が有効かどうか
  bool get isValid {
    return status.isUsable && !isTrialExpired;
  }
  
  /// 支払い遅延かどうか
  bool get isPaymentOverdue {
    if (nextPaymentDate == null) return false;
    return DateTime.now().isAfter(nextPaymentDate!) && 
           status == SubscriptionStatus.active;
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'trialEndDate': trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'contractedDriverCount': contractedDriverCount,
      'monthlyFee': monthlyFee,
      'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json, String documentId) {
    return Subscription(
      id: documentId,
      companyId: json['companyId'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SubscriptionStatus.trial,
      ),
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      trialEndDate: (json['trialEndDate'] as Timestamp?)?.toDate(),
      contractedDriverCount: json['contractedDriverCount'] ?? 0,
      monthlyFee: (json['monthlyFee'] ?? 0).toDouble(),
      lastPaymentDate: (json['lastPaymentDate'] as Timestamp?)?.toDate(),
      nextPaymentDate: (json['nextPaymentDate'] as Timestamp?)?.toDate(),
      notes: json['notes'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Subscription copyWith({
    String? id,
    String? companyId,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    int? contractedDriverCount,
    double? monthlyFee,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      contractedDriverCount: contractedDriverCount ?? this.contractedDriverCount,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
