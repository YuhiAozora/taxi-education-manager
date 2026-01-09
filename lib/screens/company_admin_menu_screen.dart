import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'admin_checkup_management_screen.dart';
import 'admin/education_records_screen.dart';
import 'admin/crew_register_screen.dart';
import 'admin/education_register_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';

/// 会社管理者メニュー画面
/// 自社の運転手管理、健康診断管理、整備点検管理
class CompanyAdminMenuScreen extends StatelessWidget {
  final User currentUser;

  const CompanyAdminMenuScreen({
    super.key,
    required this.currentUser,
  });

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('ログアウト確認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ログアウトしますか?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '次回は再度ログインが必要です',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await DatabaseService.clearCurrentUser();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会社管理者メニュー'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () {
              // 画面を再読み込み
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CompanyAdminMenuScreen(currentUser: currentUser),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _logout(context),
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
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.green,
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
                              '会社管理者',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '会社ID: ${currentUser.companyId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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

              const Text(
                '管理メニュー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // メニューカード
              _buildMenuCard(
                context: context,
                title: '従業員管理',
                subtitle: '事務員・乗務員の管理',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => _showEmployeeTypeSelection(context),
              ),

              _buildMenuCard(
                context: context,
                title: '健康診断管理',
                subtitle: '従業員の健康診断状況',
                icon: Icons.medical_services,
                color: Colors.red,
                onTap: () => _showHealthCheckTypeSelection(context),
              ),

              _buildMenuCard(
                context: context,
                title: '整備点検管理',
                subtitle: '日常点検の実施状況確認',
                icon: Icons.build,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('整備点検管理機能は今後実装予定です'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              _buildMenuCard(
                context: context,
                title: '学習進捗管理',
                subtitle: '自社運転手の学習状況確認',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('学習進捗管理機能は今後実装予定です'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // 休暇申請承認（開発中）
              _buildMenuCard(
                context: context,
                title: '休暇申請承認',
                subtitle: '従業員の休暇申請を承認・却下（開発中）',
                icon: Icons.approval,
                color: Colors.indigo,
                onTap: () => _showLeaveRequestTypeSelection(context),
              ),

              // 事故報告管理（開発中）
              _buildMenuCard(
                context: context,
                title: '事故報告管理',
                subtitle: '事故報告の確認・処理（開発中）',
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
                context: context,
                title: '教育台帳管理',
                subtitle: '運転手の教育記録・監査対応',
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

              // 乗務員台帳（PDF出力）
              _buildMenuCard(
                context: context,
                title: '乗務員台帳',
                subtitle: '乗務員情報のPDF出力',
                icon: Icons.picture_as_pdf,
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrewRegisterScreen(currentUser: currentUser),
                    ),
                  );
                },
              ),

              // 教育記録簿（PDF出力）
              _buildMenuCard(
                context: context,
                title: '教育記録簿',
                subtitle: '年度別教育実績のPDF出力',
                icon: Icons.library_books,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EducationRegisterScreen(
                        companyId: currentUser.companyId,
                      ),
                    ),
                  );
                },
              ),

              // フィードバック送信（新規追加）
              _buildMenuCard(
                context: context,
                title: 'フィードバック',
                subtitle: 'アプリの改善にご協力ください',
                icon: Icons.feedback,
                color: Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackScreen(currentUser: currentUser),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 従業員タイプ選択ダイアログ
  void _showEmployeeTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('従業員管理'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('管理する従業員タイプを選択してください'),
            const SizedBox(height: 24),
            _buildEmployeeTypeButton(
              context: context,
              title: '事務員',
              icon: Icons.business_center,
              color: Colors.blue,
              employeeType: 'office',
            ),
            const SizedBox(height: 12),
            _buildEmployeeTypeButton(
              context: context,
              title: '乗務員',
              icon: Icons.local_taxi,
              color: Colors.orange,
              employeeType: 'driver',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 健康診断タイプ選択ダイアログ
  void _showHealthCheckTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('健康診断管理'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('管理する従業員タイプを選択してください'),
            const SizedBox(height: 24),
            _buildEmployeeTypeButton(
              context: context,
              title: '事務員',
              icon: Icons.business_center,
              color: Colors.blue,
              employeeType: 'office',
              isHealthCheck: true,
            ),
            const SizedBox(height: 12),
            _buildEmployeeTypeButton(
              context: context,
              title: '乗務員',
              icon: Icons.local_taxi,
              color: Colors.orange,
              employeeType: 'driver',
              isHealthCheck: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 休暇申請タイプ選択ダイアログ
  void _showLeaveRequestTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.approval, color: Colors.indigo.shade700),
            const SizedBox(width: 8),
            const Text('休暇申請承認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('管理する従業員タイプを選択してください'),
            const SizedBox(height: 24),
            _buildEmployeeTypeButton(
              context: context,
              title: '事務員',
              icon: Icons.business_center,
              color: Colors.blue,
              employeeType: 'office',
              isLeaveRequest: true,
            ),
            const SizedBox(height: 12),
            _buildEmployeeTypeButton(
              context: context,
              title: '乗務員',
              icon: Icons.local_taxi,
              color: Colors.orange,
              employeeType: 'driver',
              isLeaveRequest: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 従業員タイプボタン
  Widget _buildEmployeeTypeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String employeeType,
    bool isHealthCheck = false,
    bool isLeaveRequest = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // ダイアログを閉じる
        
        if (isHealthCheck) {
          // 健康診断管理画面へ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCheckupManagementScreen(employeeType: employeeType),
            ),
          );
        } else if (isLeaveRequest) {
          // 休暇申請管理（開発中メッセージ）
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title の休暇申請承認機能は開発中です'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // 従業員管理（開発中メッセージ）
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title の管理機能は開発中です'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
