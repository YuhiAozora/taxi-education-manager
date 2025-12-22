import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/education_item.dart';
import '../models/medical_checkup.dart';
import 'education_detail_screen.dart';
import 'learning_history_screen.dart';
import 'login_screen.dart';
import 'medical_checkup_screen.dart';
import 'chatbot_screen.dart';
import 'personal_ai_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  User? _currentUser;
  List<EducationItem> _educationItems = [];
  int _completedCount = 0;
  int _totalMinutes = 0;
  double _averageScore = 0.0;
  Set<String> _completedItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    // ログイン後に診断通知をチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMedicalCheckupNotifications();
    });
  }

  Future<void> _loadData() async {
    final user = DatabaseService.getCurrentUser();
    final items = await DatabaseService.getAllEducationItems();
    
    if (user != null) {
      final completed = await DatabaseService.getCompletedItemsCount(user.id);
      final minutes = await DatabaseService.getTotalLearningMinutes(user.id);
      final score = await DatabaseService.getAverageQuizScore(user.id);
      final records = await DatabaseService.getLearningRecordsByUser(user.id);
      final completedIds = records.map((r) => r.educationItemId).toSet();
      
      setState(() {
        _currentUser = user;
        _educationItems = items;
        _completedCount = completed;
        _totalMinutes = minutes;
        _averageScore = score;
        _completedItemIds = completedIds;
      });
    } else {
      setState(() {
        _currentUser = user;
        _educationItems = items;
      });
    }
  }

  Future<void> _checkMedicalCheckupNotifications() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    final checkups = await DatabaseService.getMedicalCheckupsByUser(_currentUser!.id);
    
    final overdueCheckups = <Map<String, dynamic>>[];
    final upcomingCheckups = <Map<String, dynamic>>[];

    for (final checkup in checkups) {
      final daysUntilDue = checkup.nextDueDate.difference(now).inDays;
      final notificationDate = checkup.nextDueDate.subtract(
        Duration(days: checkup.type.notificationDaysBefore),
      );

      if (daysUntilDue < 0) {
        // 期限切れ
        overdueCheckups.add({
          'checkup': checkup,
          'daysOverdue': -daysUntilDue,
        });
      } else if (now.isAfter(notificationDate)) {
        // もうすぐ期限
        upcomingCheckups.add({
          'checkup': checkup,
          'daysRemaining': daysUntilDue,
        });
      }
    }

    // 通知があれば表示
    if (overdueCheckups.isNotEmpty || upcomingCheckups.isNotEmpty) {
      _showCheckupNotificationDialog(overdueCheckups, upcomingCheckups);
    }
  }

  void _showCheckupNotificationDialog(
    List<Map<String, dynamic>> overdueCheckups,
    List<Map<String, dynamic>> upcomingCheckups,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              overdueCheckups.isNotEmpty ? Icons.error : Icons.warning,
              color: overdueCheckups.isNotEmpty ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('診断のお知らせ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overdueCheckups.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '⚠️ 期限切れの診断があります',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...overdueCheckups.map((item) {
                        final checkup = item['checkup'] as MedicalCheckup;
                        final daysOverdue = item['daysOverdue'] as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• ${checkup.type.displayName}\n  期限から${daysOverdue}日経過',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (upcomingCheckups.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '📅 もうすぐ期限の診断があります',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...upcomingCheckups.map((item) {
                        final checkup = item['checkup'] as MedicalCheckup;
                        final daysRemaining = item['daysRemaining'] as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• ${checkup.type.displayName}\n  残り${daysRemaining}日',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '診断管理画面で詳細を確認してください。',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('後で確認'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalCheckupScreen(user: _currentUser!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('診断管理へ'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Group items by category
    final categoryMap = <String, List<EducationItem>>{};
    for (var item in _educationItems) {
      if (!categoryMap.containsKey(item.category)) {
        categoryMap[item.category] = [];
      }
      categoryMap[item.category]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('教育コンテンツ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'ヘルプ・サポート',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatbotScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: '診断管理',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalCheckupScreen(user: _currentUser!),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '学習履歴',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LearningHistoryScreen(),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade700,
                                child: Text(
                                  _currentUser!.name[0],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser!.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      '社員番号: ${_currentUser!.employeeNumber}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.check_circle,
                                label: '完了',
                                value: '$_completedCount/${_educationItems.length}',
                                color: Colors.green,
                              ),
                              _buildStatItem(
                                icon: Icons.timer,
                                label: '学習時間',
                                value: '$_totalMinutes分',
                                color: Colors.blue,
                              ),
                              _buildStatItem(
                                icon: Icons.emoji_events,
                                label: '平均点',
                                value: '${_averageScore.toStringAsFixed(0)}%',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FAQ と パーソナルAI ボタン
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceButton(
                          context: context,
                          icon: Icons.help_outline,
                          title: 'よくある質問',
                          subtitle: 'FAQ・使い方',
                          color: Colors.blue,
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
                        child: _buildServiceButton(
                          context: context,
                          icon: Icons.psychology,
                          title: 'パーソナルサポート',
                          subtitle: 'AI相談',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PersonalAiScreen(user: _currentUser!),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Education items by category
                  ...categoryMap.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(entry.key),
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((item) => _buildEducationCard(item)),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
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
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEducationCard(EducationItem item) {
    // Check if item is completed based on locally cached _completedCount
    final isCompleted = _completedItemIds.contains(item.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationDetailScreen(educationItem: item),
            ),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? Colors.green : Colors.blue.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '約${item.estimatedMinutes}分',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.quiz,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'クイズ${item.quizQuestions.length}問',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // サービスボタン（FAQ/パーソナルAI）
  Widget _buildServiceButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
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
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '基本的事項':
        return Icons.home;
      case '法令・実務':
        return Icons.gavel;
      case '安全運転':
        return Icons.security;
      case '接客':
        return Icons.people;
      case '事故対応':
        return Icons.warning;
      case '健康管理':
        return Icons.favorite;
      default:
        return Icons.book;
    }
  }
}
