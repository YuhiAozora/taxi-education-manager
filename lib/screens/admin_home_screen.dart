import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<User> _drivers = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _drivers = DatabaseService.getAllDrivers();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _selectedIndex == 0 ? _buildOverviewTab() : _buildDriverDetailsTab(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: '全体概要',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: '乗務員詳細',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final allRecords = DatabaseService.getAllLearningRecords();
    final educationItems = DatabaseService.getAllEducationItems();
    
    int totalLearningMinutes = 0;
    double totalAverageScore = 0.0;

    for (final driver in _drivers) {
      totalLearningMinutes += DatabaseService.getTotalLearningMinutes(driver.id);
      totalAverageScore += DatabaseService.getAverageQuizScore(driver.id);
    }

    final averageScore = _drivers.isEmpty ? 0.0 : totalAverageScore / _drivers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全体統計',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '登録乗務員',
                  '${_drivers.length}名',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '教育項目',
                  '${educationItems.length}件',
                  Icons.book,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '総学習時間',
                  '$totalLearningMinutes分',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '平均得点率',
                  '${averageScore.toStringAsFixed(0)}%',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近の学習活動',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('詳細を見る'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (allRecords.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_edu,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '学習記録がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...allRecords.take(10).map((record) {
              final user = DatabaseService.getUser(record.userId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user?.name[0] ?? '?',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                  title: Text(
                    record.educationTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${user?.name ?? '不明'} • ${record.formattedDate} ${record.formattedTime}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        record.scoreDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        '${record.durationMinutes}分',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDriverDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '乗務員一覧',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportLearningData,
                icon: const Icon(Icons.download),
                label: const Text('CSV出力'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_drivers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '登録された乗務員がいません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            )
          else
            ..._drivers.map((driver) => _buildDriverCard(driver)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
        ),
      ),
    );
  }

  Widget _buildDriverCard(User driver) {
    final records = DatabaseService.getLearningRecordsByUser(driver.id);
    final completedCount = DatabaseService.getCompletedItemsCount(driver.id);
    final totalMinutes = DatabaseService.getTotalLearningMinutes(driver.id);
    final averageScore = DatabaseService.getAverageQuizScore(driver.id);
    final totalItems = DatabaseService.getAllEducationItems().length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            driver.name[0],
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          driver.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('社員番号: ${driver.employeeNumber}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDriverStat(
                        '完了項目',
                        '$completedCount/$totalItems',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildDriverStat(
                        '学習時間',
                        '$totalMinutes分',
                        Icons.timer,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildDriverStat(
                        '平均得点',
                        '${averageScore.toStringAsFixed(0)}%',
                        Icons.emoji_events,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (records.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '最近の学習履歴',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...records.take(3).map((record) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.educationTitle,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${record.formattedDate} ${record.formattedTime}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          record.scoreDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '学習記録がありません',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  void _exportLearningData() {
    final allRecords = DatabaseService.getAllLearningRecords();
    
    if (allRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('エクスポートするデータがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate CSV data
    final buffer = StringBuffer();
    buffer.writeln('社員番号,氏名,教育項目,カテゴリ,学習日,開始時刻,終了時刻,学習時間(分),クイズ得点,合計問題数');
    
    for (final record in allRecords) {
      final user = DatabaseService.getUser(record.userId);
      if (user != null) {
        buffer.writeln(
          '${user.employeeNumber},'
          '${user.name},'
          '${record.educationTitle},'
          '${record.category},'
          '${DateFormat('yyyy/MM/dd').format(record.startTime)},'
          '${DateFormat('HH:mm').format(record.startTime)},'
          '${DateFormat('HH:mm').format(record.endTime)},'
          '${record.durationMinutes},'
          '${record.quizScore ?? ""},'
          '${record.totalQuestions ?? ""}'
        );
      }
    }

    if (kDebugMode) {
      debugPrint('CSV Data:');
      debugPrint(buffer.toString());
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 8),
            Text('データエクスポート'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${allRecords.length}件の学習記録をエクスポートしました。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '※ 実際のアプリではCSVファイルとして\nダウンロードされます',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // In real app, would download CSV file
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSVエクスポート機能はデモ版では無効です'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('ダウンロード'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
