// AI会話履歴モデル
class AiConversation {
  final String id;              // 会話ID
  final String userId;          // ユーザーID（社員番号）
  final String companyId;       // 会社ID（データ隔離用）
  final String userMessage;     // ユーザーの質問
  final String aiResponse;      // AIの回答
  final DateTime timestamp;     // 会話日時
  final String category;        // カテゴリ（事故防止/メンタルケア/その他）

  AiConversation({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.userMessage,
    required this.aiResponse,
    required this.timestamp,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'companyId': companyId,
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
      };

  factory AiConversation.fromJson(Map<String, dynamic> json, String id) =>
      AiConversation(
        id: id,
        userId: json['userId'] as String,
        companyId: json['companyId'] as String,
        userMessage: json['userMessage'] as String,
        aiResponse: json['aiResponse'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String,
      );
}

// パーソナライズ用のユーザーコンテキスト
class UserContext {
  final String name;                    // 名前
  final int completedEducationCount;    // 完了した教育項目数
  final int totalEducationCount;        // 総教育項目数
  final double learningProgressRate;    // 学習進捗率
  final bool hasCompletedCheckup;       // 健康診断受診済みか
  final DateTime? lastCheckupDate;      // 最新の健康診断日
  final int experienceYears;            // 経験年数（年齢から推定）
  final DateTime lastLoginDate;         // 最終ログイン日

  UserContext({
    required this.name,
    required this.completedEducationCount,
    required this.totalEducationCount,
    required this.learningProgressRate,
    required this.hasCompletedCheckup,
    this.lastCheckupDate,
    required this.experienceYears,
    required this.lastLoginDate,
  });

  // AIプロンプト用の文章生成
  String toPromptContext() {
    final buffer = StringBuffer();
    
    buffer.writeln('【運転者のプロフィール】');
    buffer.writeln('・名前: ${name}さん');
    buffer.writeln('・経験年数: 約${experienceYears}年');
    
    buffer.writeln('\n【学習状況】');
    buffer.writeln('・完了した教育項目: $completedEducationCount/$totalEducationCount');
    buffer.writeln('・進捗率: ${learningProgressRate.toStringAsFixed(1)}%');
    
    buffer.writeln('\n【健康管理】');
    if (hasCompletedCheckup && lastCheckupDate != null) {
      final daysSinceCheckup = DateTime.now().difference(lastCheckupDate!).inDays;
      buffer.writeln('・健康診断: 受診済み（${daysSinceCheckup}日前）');
    } else {
      buffer.writeln('・健康診断: 未受診または期限切れ');
    }
    
    buffer.writeln('\n【アプリ利用状況】');
    final daysSinceLogin = DateTime.now().difference(lastLoginDate).inDays;
    if (daysSinceLogin == 0) {
      buffer.writeln('・本日もログイン（積極的に利用中）');
    } else {
      buffer.writeln('・前回のログイン: ${daysSinceLogin}日前');
    }
    
    return buffer.toString();
  }
}
