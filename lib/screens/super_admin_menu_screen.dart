import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'super_admin_home_screen.dart';
import 'subscription_management_screen.dart';
import 'admin/education_records_screen.dart';
import 'admin/feedback_management_screen.dart';
import 'admin/feedback_test_screen.dart';
import 'login_screen.dart';

/// スーパー管理者メニュー画面
class SuperAdminMenuScreen extends StatelessWidget {
  final User currentUser;

  const SuperAdminMenuScreen({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スーパー管理者メニュー'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await DatabaseService.clearCurrentUser();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ウェルカムメッセージ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ようこそ、${currentUser.name}さん',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'スーパー管理者',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // メインメニュー
              const Text(
                '管理メニュー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 会員企業管理
              _buildMenuCard(
                context,
                title: '会員企業管理',
                subtitle: '企業一覧、統計情報の確認',
                icon: Icons.business,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuperAdminHomeScreen(
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 契約・請求管理
              _buildMenuCard(
                context,
                title: '契約・請求管理',
                subtitle: '契約一覧、請求書管理、月次請求処理',
                icon: Icons.payment,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 売上レポート (将来実装)
              _buildMenuCard(
                context,
                title: '売上レポート',
                subtitle: '月次売上グラフ、年次推移',
                icon: Icons.analytics,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('この機能は開発中です'),
                    ),
                  );
                },
                isComingSoon: true,
              ),

              const SizedBox(height: 16),

              // 休暇申請承認（開発中）
              _buildMenuCard(
                context,
                title: '休暇申請承認',
                subtitle: '全運転手の休暇申請を承認・却下（開発中）',
                icon: Icons.approval,
                color: Colors.indigo,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('休暇申請承認機能は開発中です。次のリリースで実装予定です。'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),

              // 事故報告管理（開発中）
              _buildMenuCard(
                context,
                title: '事故報告管理',
                subtitle: '全事故報告の確認・処理（開発中）',
                icon: Icons.report_problem,
                color: Colors.red,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('事故報告管理機能は開発中です。次のリリースで実装予定です。'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),

              // 教育台帳管理（新規追加）
              _buildMenuCard(
                context,
                title: '教育台帳管理',
                subtitle: '全運転手の教育記録・監査対応',
                icon: Icons.book,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EducationRecordsScreen(currentUser: currentUser),
                    ),
                  );
                },
              ),

              // フィードバック管理（新規追加）
              _buildMenuCard(
                context,
                title: 'フィードバック管理',
                subtitle: 'ユーザーからの意見・要望を確認',
                icon: Icons.feedback,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FeedbackManagementScreen(),
                    ),
                  );
                },
              ),

              // 🔧 Firestore接続テスト（デバッグ用）
              _buildMenuCard(
                context,
                title: '🔧 Firestore接続テスト',
                subtitle: 'フィードバック機能のデバッグ',
                icon: Icons.bug_report,
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FeedbackTestScreen(),
                    ),
                  );
                },
              ),

              // システム設定 (将来実装)
              _buildMenuCard(
                context,
                title: 'システム設定',
                subtitle: 'ユーザー管理、システム設定',
                icon: Icons.settings,
                color: Colors.blueGrey,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('この機能は開発中です'),
                    ),
                  );
                },
                isComingSoon: true,
              ),

              const SizedBox(height: 32),

              // クイックアクション
              const Text(
                'クイックアクション',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: '新規企業追加',
                      icon: Icons.add_business,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SuperAdminHomeScreen(
                              currentUser: currentUser,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: '月次請求処理',
                      icon: Icons.receipt_long,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isComingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '開発中',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
