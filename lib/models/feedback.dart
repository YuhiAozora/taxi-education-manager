import 'package:cloud_firestore/cloud_firestore.dart';

/// フィードバックカテゴリ
enum FeedbackCategory {
  usability('使いやすさ'),
  bug('不具合・エラー'),
  improvement('改善要望'),
  feature('新機能リクエスト'),
  other('その他');

  final String displayName;
  const FeedbackCategory(this.displayName);
}

/// フィードバックステータス
enum FeedbackStatus {
  pending('未対応'),
  inProgress('対応中'),
  resolved('対応済み'),
  closed('完了');

  final String displayName;
  const FeedbackStatus(this.displayName);
}

/// アプリフィードバックモデル
class AppFeedback {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'driver' or 'company_admin'
  final String companyId;
  final FeedbackCategory category;
  final String title;
  final String description;
  final FeedbackStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminResponse;
  final String? screenshotUrl;

  AppFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.companyId,
    required this.category,
    required this.title,
    required this.description,
    this.status = FeedbackStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.adminResponse,
    this.screenshotUrl,
  });

  /// Firestoreから読み込み
  factory AppFeedback.fromFirestore(Map<String, dynamic> data, String id) {
    return AppFeedback(
      id: id,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String,
      userRole: data['user_role'] as String,
      companyId: data['company_id'] as String,
      category: FeedbackCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => FeedbackCategory.other,
      ),
      title: data['title'] as String,
      description: data['description'] as String,
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      resolvedAt: data['resolved_at'] != null
          ? (data['resolved_at'] as Timestamp).toDate()
          : null,
      adminResponse: data['admin_response'] as String?,
      screenshotUrl: data['screenshot_url'] as String?,
    );
  }

  /// Firestoreへ保存
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'company_id': companyId,
      'category': category.name,
      'title': title,
      'description': description,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'resolved_at': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'admin_response': adminResponse,
      'screenshot_url': screenshotUrl,
    };
  }

  /// ステータス更新用コピー
  AppFeedback copyWith({
    FeedbackStatus? status,
    DateTime? resolvedAt,
    String? adminResponse,
  }) {
    return AppFeedback(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      companyId: companyId,
      category: category,
      title: title,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      screenshotUrl: screenshotUrl,
    );
  }
}
