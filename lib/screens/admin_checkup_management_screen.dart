import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/medical_checkup.dart';
import '../services/database_service.dart';
import 'medical_checkup_screen.dart';

/// 管理者向け - 全運転者の診断管理画面
class AdminCheckupManagementScreen extends StatefulWidget {
  const AdminCheckupManagementScreen({super.key});

  @override
  State<AdminCheckupManagementScreen> createState() =>
      _AdminCheckupManagementScreenState();
}

class _AdminCheckupManagementScreenState
    extends State<AdminCheckupManagementScreen> {
  List<User> _drivers = [];
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _drivers = DatabaseService.getAllDrivers();
      _notifications = DatabaseService.getUpcomingCheckupNotifications();
    });
  }

  Map<String, dynamic> _getDriverStatistics(User driver) {
    return DatabaseService.getMedicalCheckupStatistics(driver.id);
  }

  String _exportToCSV() {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln(
      '社員番号,氏名,診断種別,前回受診日,次回予定日,実施機関,診断書番号,ステータス',
    );

    // データ行
    for (final driver in _drivers) {
      final checkups = DatabaseService.getMedicalCheckupsByUser(driver.id);
      
      if (checkups.isEmpty) {
        buffer.writeln(
          '${driver.employeeNumber},${driver.name},未受診,-,-,-,-,未受診',
        );
        continue;
      }

      for (final checkup in checkups) {
        final status = _getCheckupStatus(checkup);
        final checkupDateStr = '${checkup.checkupDate.year}/${checkup.checkupDate.month}/${checkup.checkupDate.day}';
        final nextDueDateStr = checkup.nextDueDate != null
            ? '${checkup.nextDueDate!.year}/${checkup.nextDueDate!.month}/${checkup.nextDueDate!.day}'
            : '-';
        
        buffer.writeln(
          '${driver.employeeNumber},${driver.name},${checkup.type.displayName},$checkupDateStr,$nextDueDateStr,${checkup.institution ?? '-'},${checkup.certificateNumber ?? '-'},$status',
        );
      }
    }

    return buffer.toString();
  }

  String _getCheckupStatus(MedicalCheckup checkup) {
    if (checkup.nextDueDate == null) {
      return '受診済';
    }

    final now = DateTime.now();
    final daysUntilDue = checkup.nextDueDate!.difference(now).inDays;

    if (daysUntilDue < 0) {
      return '期限切れ';
    } else if (daysUntilDue <= checkup.type.notificationDaysBefore) {
      return 'もうすぐ期限';
    } else {
      return '正常';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '期限切れ':
        return Colors.red;
      case 'もうすぐ期限':
        return Colors.orange;
      case '正常':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showExportDialog() {
    final csvData = _exportToCSV();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV出力'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('診断台帳データをCSV形式で出力しました。'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    csvData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 期限切れと要注意の通知をカウント
    final overdueCount = _notifications.where((n) => n['isOverdue'] == true).length;
    final upcomingCount = _notifications.where((n) => n['isOverdue'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('診断管理台帳'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'CSV出力',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 通知サマリー
              if (_notifications.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            '要注意項目',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (overdueCount > 0)
                        Text(
                          '⚠️ 期限切れ: $overdueCount件',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      if (upcomingCount > 0)
                        Text(
                          '📅 もうすぐ期限: $upcomingCount件',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ...(_notifications.map((notification) {
                        final user = notification['user'] as User;
                        final checkup = notification['checkup'] as MedicalCheckup;
                        final isOverdue = notification['isOverdue'] as bool;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              isOverdue ? Icons.error : Icons.warning,
                              color: isOverdue ? Colors.red : Colors.orange,
                            ),
                            title: Text(
                              '${user.name} (${user.employeeNumber})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${checkup.type.displayName}\n'
                              '${isOverdue ? "${notification['daysOverdue']}日 期限超過" : "あと${notification['daysRemaining']}日"}',
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicalCheckupScreen(
                                    user: user,
                                  ),
                                ),
                              );
                              _loadData();
                            },
                          ),
                        );
                      })),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // 運転者一覧
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '運転者一覧 (${_drivers.length}名)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _drivers.length,
                      itemBuilder: (context, index) {
                        final driver = _drivers[index];
                        final stats = _getDriverStatistics(driver);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicalCheckupScreen(
                                    user: driver,
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          driver.name[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              driver.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '社員番号: ${driver.employeeNumber}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatBadge(
                                        '合計',
                                        stats['total'].toString(),
                                        Colors.blue,
                                      ),
                                      _buildStatBadge(
                                        '正常',
                                        stats['upToDate'].toString(),
                                        Colors.green,
                                      ),
                                      _buildStatBadge(
                                        '要注意',
                                        stats['upcoming'].toString(),
                                        Colors.orange,
                                      ),
                                      _buildStatBadge(
                                        '期限切れ',
                                        stats['overdue'].toString(),
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
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
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
