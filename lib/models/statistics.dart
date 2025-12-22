import 'package:cloud_firestore/cloud_firestore.dart';

/// 統計データモデル（匿名化された業界全体のデータ）
/// 
/// 個人情報を一切含まない、集計済みの統計データのみを扱います。
/// 法令遵守のため、個人が特定できる情報は保存しません。
class AnonymousStatistics {
  final String id;                    // 統計ID
  final DateTime periodStart;         // 集計期間（開始）
  final DateTime periodEnd;           // 集計期間（終了）
  final String statisticsType;        // 統計種別（monthly/quarterly/yearly）
  
  // 学習統計（匿名化）
  final int totalCompanies;           // 集計対象企業数
  final int totalDrivers;             // 集計対象運転者数
  final double avgLearningHours;      // 平均学習時間（時間）
  final double totalLearningHours;    // 総学習時間（時間）
  final int totalEducationItems;      // 総教育項目数
  final double avgCompletionRate;     // 平均完了率（%）
  
  // 健康診断統計（匿名化）
  final double medicalCheckupRate;    // 健康診断受診率（%）
  final int totalMedicalCheckups;     // 総健康診断実施数
  final double overdueMedicalRate;    // 期限切れ率（%）
  
  // 満足度統計（匿名化）
  final double avgSatisfactionScore;  // 平均満足度スコア（1-5）
  final int totalSurveyResponses;     // 総アンケート回答数
  final Map<String, int> satisfactionDistribution; // 満足度分布
  
  final DateTime createdAt;           // 作成日時

  AnonymousStatistics({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.statisticsType,
    required this.totalCompanies,
    required this.totalDrivers,
    required this.avgLearningHours,
    required this.totalLearningHours,
    required this.totalEducationItems,
    required this.avgCompletionRate,
    required this.medicalCheckupRate,
    required this.totalMedicalCheckups,
    required this.overdueMedicalRate,
    required this.avgSatisfactionScore,
    required this.totalSurveyResponses,
    required this.satisfactionDistribution,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'statisticsType': statisticsType,
      'totalCompanies': totalCompanies,
      'totalDrivers': totalDrivers,
      'avgLearningHours': avgLearningHours,
      'totalLearningHours': totalLearningHours,
      'totalEducationItems': totalEducationItems,
      'avgCompletionRate': avgCompletionRate,
      'medicalCheckupRate': medicalCheckupRate,
      'totalMedicalCheckups': totalMedicalCheckups,
      'overdueMedicalRate': overdueMedicalRate,
      'avgSatisfactionScore': avgSatisfactionScore,
      'totalSurveyResponses': totalSurveyResponses,
      'satisfactionDistribution': satisfactionDistribution,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AnonymousStatistics.fromJson(Map<String, dynamic> json, String documentId) {
    return AnonymousStatistics(
      id: documentId,
      periodStart: (json['periodStart'] as Timestamp).toDate(),
      periodEnd: (json['periodEnd'] as Timestamp).toDate(),
      statisticsType: json['statisticsType'] ?? 'monthly',
      totalCompanies: json['totalCompanies'] ?? 0,
      totalDrivers: json['totalDrivers'] ?? 0,
      avgLearningHours: (json['avgLearningHours'] ?? 0).toDouble(),
      totalLearningHours: (json['totalLearningHours'] ?? 0).toDouble(),
      totalEducationItems: json['totalEducationItems'] ?? 0,
      avgCompletionRate: (json['avgCompletionRate'] ?? 0).toDouble(),
      medicalCheckupRate: (json['medicalCheckupRate'] ?? 0).toDouble(),
      totalMedicalCheckups: json['totalMedicalCheckups'] ?? 0,
      overdueMedicalRate: (json['overdueMedicalRate'] ?? 0).toDouble(),
      avgSatisfactionScore: (json['avgSatisfactionScore'] ?? 0).toDouble(),
      totalSurveyResponses: json['totalSurveyResponses'] ?? 0,
      satisfactionDistribution: Map<String, int>.from(json['satisfactionDistribution'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// 満足度調査モデル
class SatisfactionSurvey {
  final String id;                  // アンケートID
  final String userId;              // 回答者ID（統計時に匿名化）
  final String companyId;           // 会社ID（統計時に除外）
  final int satisfactionScore;      // 満足度スコア（1-5）
  final String? feedback;           // フィードバック（任意）
  final String category;            // カテゴリ（education/checkup/system）
  final DateTime createdAt;         // 回答日時

  SatisfactionSurvey({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.satisfactionScore,
    this.feedback,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'companyId': companyId,
      'satisfactionScore': satisfactionScore,
      'feedback': feedback,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SatisfactionSurvey.fromJson(Map<String, dynamic> json, String documentId) {
    return SatisfactionSurvey(
      id: documentId,
      userId: json['userId'] ?? '',
      companyId: json['companyId'] ?? '',
      satisfactionScore: json['satisfactionScore'] ?? 3,
      feedback: json['feedback'],
      category: json['category'] ?? 'system',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
