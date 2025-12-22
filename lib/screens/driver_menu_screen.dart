import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'driver_home_screen.dart';
import 'learning_history_screen.dart';
import 'medical_checkup_screen.dart';
import 'vehicle_inspection_screen.dart';
import 'inspection_history_screen.dart';
import 'welfare_screen.dart';
import 'shift_schedule_screen.dart';
import 'leave_request_screen.dart';
import 'accident_report_screen.dart';
import 'chatbot_screen.dart';
import 'personal_ai_screen.dart' show PersonalAiScreen;
import 'feedback_screen.dart';
import 'login_screen.dart';

/// 乗務員メニュー画面
/// 学習コンテンツ、学習履歴、健康診断、FAQ、パーソナルAIへのアクセス
class DriverMenuScreen extends StatefulWidget {
  final User currentUser;

  const DriverMenuScreen({super.key, required this.currentUser});

  @override
  State<DriverMenuScreen> createState() => _DriverMenuScreenState();
}

class _DriverMenuScreenState extends State<DriverMenuScreen> {
  int _completedCount = 0;
  int _totalMinutes = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final completed = await DatabaseService.getCompletedItemsCount(widget.currentUser.id);
    final minutes = await DatabaseService.getTotalLearningMinutes(widget.currentUser.id);
    final score = await DatabaseService.getAverageQuizScore(widget.currentUser.id);
    
    setState(() {
      _completedCount = completed;
      _totalMinutes = minutes;
      _averageScore = score;
    });
  }

  Future<void> _logout() async {
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

    if (confirmed == true) {
      await DatabaseService.clearCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乗務員メニュー'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ユーザー情報カード
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue,
                              child: Text(
                                widget.currentUser.name.isNotEmpty 
                                    ? widget.currentUser.name[0] 
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.currentUser.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '社員番号: ${widget.currentUser.employeeNumber}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // 学習統計サマリー
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.check_circle,
                              label: '完了',
                              value: '$_completedCount件',
                              color: Colors.green,
                            ),
                            _buildStatItem(
                              icon: Icons.access_time,
                              label: '学習時間',
                              value: '$_totalMinutes分',
                              color: Colors.blue,
                            ),
                            _buildStatItem(
                              icon: Icons.star,
                              label: '平均点',
                              value: '${_averageScore.toStringAsFixed(1)}点',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  '機能メニュー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // メインメニューカード
                _buildMenuCard(
                  title: '教育コンテンツ',
                  subtitle: '学習項目を確認・受講',
                  icon: Icons.school,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverHomeScreen(),
                      ),
                    ).then((_) => _loadStats());
                  },
                ),
                
                _buildMenuCard(
                  title: '学習履歴',
                  subtitle: '過去の学習記録を確認',
                  icon: Icons.history,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LearningHistoryScreen(),
                      ),
                    ).then((_) => _loadStats());
                  },
                ),
                
                _buildMenuCard(
                  title: '健康診断管理',
                  subtitle: '診断記録と次回予定',
                  icon: Icons.medical_services,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalCheckupScreen(user: widget.currentUser),
                      ),
                    ).then((_) => _loadStats());
                  },
                ),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildMenuCard(
                        title: '整備点検チェック',
                        subtitle: '日常点検を実施',
                        icon: Icons.build_circle,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleInspectionScreen(currentUser: widget.currentUser),
                            ),
                          ).then((_) => _loadStats());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildSmallMenuCard(
                        title: '点検履歴',
                        subtitle: '過去の点検',
                        icon: Icons.history,
                        color: Colors.blueGrey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InspectionHistoryScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                _buildMenuCard(
                  title: '福利厚生',
                  subtitle: '福利厚生制度を確認',
                  icon: Icons.favorite,
                  color: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WelfareScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
                
                _buildMenuCard(
                  title: '出番表',
                  subtitle: 'シフトスケジュール',
                  icon: Icons.calendar_month,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftScheduleScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
                
                _buildMenuCard(
                  title: '休暇申請',
                  subtitle: '有給・特別休暇など',
                  icon: Icons.beach_access,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeaveRequestScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
                
                _buildMenuCard(
                  title: '事故報告',
                  subtitle: '事故発生時の報告',
                  icon: Icons.report_problem,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccidentReportScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'サポート',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallMenuCard(
                        title: 'FAQ',
                        subtitle: 'よくある質問',
                        icon: Icons.help_outline,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatbotScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSmallMenuCard(
                        title: 'パーソナルAI',
                        subtitle: '個別相談',
                        icon: Icons.psychology,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonalAiScreen(user: widget.currentUser),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // フィードバック送信ボタン（新規追加）
                const SizedBox(height: 12),
                _buildMenuCard(
                  title: 'フィードバック',
                  subtitle: 'アプリの改善にご協力ください',
                  icon: Icons.feedback,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
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

  Widget _buildSmallMenuCard({
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
