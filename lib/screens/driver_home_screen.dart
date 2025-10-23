import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/education_item.dart';
import 'education_detail_screen.dart';
import 'learning_history_screen.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _currentUser = DatabaseService.getCurrentUser();
      _educationItems = DatabaseService.getAllEducationItems();
      
      if (_currentUser != null) {
        _completedCount = DatabaseService.getCompletedItemsCount(_currentUser!.id);
        _totalMinutes = DatabaseService.getTotalLearningMinutes(_currentUser!.id);
        _averageScore = DatabaseService.getAverageQuizScore(_currentUser!.id);
      }
    });
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

    final categoryMap = DatabaseService.getEducationItemsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('教育コンテンツ'),
        actions: [
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
    final records = DatabaseService.getLearningRecordsByUser(_currentUser!.id);
    final isCompleted = records.any((r) => r.educationItemId == item.id && r.completed);
    
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
