import '../models/user.dart';
import '../models/medical_checkup.dart';

/// 乗務員台帳（Crew Register）
/// 監査・法定保存用の乗務員情報を集約したモデル
class CrewRegister {
  // 基本情報（usersコレクションから）
  final User user;
  
  // 健康診断記録（medical_checkupsコレクションから）
  final List<MedicalCheckup> medicalCheckups;
  
  // 免許情報（今後追加予定）
  final LicenseInfo? licenseInfo;
  
  // 教育履歴サマリー
  final EducationSummary educationSummary;
  
  // 事故履歴サマリー
  final AccidentSummary accidentSummary;
  
  // 作成日時
  final DateTime generatedAt;

  CrewRegister({
    required this.user,
    required this.medicalCheckups,
    this.licenseInfo,
    required this.educationSummary,
    required this.accidentSummary,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

/// 免許情報
class LicenseInfo {
  final String licenseNumber;      // 免許証番号
  final DateTime issueDate;        // 交付年月日
  final DateTime expiryDate;       // 有効期限
  final List<String> categories;   // 免許種別（普通、大型、第二種など）
  final String conditions;         // 条件等
  final DateTime lastRenewal;      // 最終更新日

  LicenseInfo({
    required this.licenseNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.categories,
    required this.conditions,
    required this.lastRenewal,
  });
}

/// 教育履歴サマリー
class EducationSummary {
  final int totalCompletedItems;   // 総受講項目数
  final int totalMinutes;          // 総受講時間（分）
  final double averageScore;       // 平均点
  final DateTime? lastLearningDate; // 最終受講日
  final int itemsThisYear;         // 今年度受講項目数
  final int minutesThisYear;       // 今年度受講時間（分）

  EducationSummary({
    required this.totalCompletedItems,
    required this.totalMinutes,
    required this.averageScore,
    this.lastLearningDate,
    required this.itemsThisYear,
    required this.minutesThisYear,
  });
}

/// 事故履歴サマリー
class AccidentSummary {
  final int totalAccidents;        // 総事故件数
  final int minorAccidents;        // 軽微な事故
  final int moderateAccidents;     // 中程度の事故
  final int seriousAccidents;      // 重大な事故
  final DateTime? lastAccidentDate; // 最終事故日
  final int accidentsThisYear;     // 今年度事故件数

  AccidentSummary({
    required this.totalAccidents,
    required this.minorAccidents,
    required this.moderateAccidents,
    required this.seriousAccidents,
    this.lastAccidentDate,
    required this.accidentsThisYear,
  });
}
