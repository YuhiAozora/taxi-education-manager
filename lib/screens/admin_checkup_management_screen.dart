import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/medical_checkup.dart';
import '../services/database_service.dart';
import 'medical_checkup_screen.dart';

/// 管理者向け - 全従業員の診断管理画面
class AdminCheckupManagementScreen extends StatefulWidget {
  final String employeeType; // 'office' or 'driver'
  
  const AdminCheckupManagementScreen({
    super.key,
    this.employeeType = 'driver',
  });

  @override
  State<AdminCheckupManagementScreen> createState() =>
      _AdminCheckupManagementScreenState();
}

class _AdminCheckupManagementScreenState
    extends State<AdminCheckupManagementScreen> {
  List<User> _employees = [];
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // βテスト用: サンプルデータを生成
    final sampleEmployees = _generateSampleEmployees();
    setState(() {
      _employees = sampleEmployees;
      _notifications = [];
    });
  }

  /// βテスト用: サンプル従業員データを生成
  List<User> _generateSampleEmployees() {
    if (widget.employeeType == 'office') {
      // 事務員のサンプルデータ
      return [
        User(
          employeeNumber: 'S001',
          name: '田中 花子',
          password: 'office2024',
          role: 'office_staff',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'S002',
          name: '佐藤 美咲',
          password: 'office2024',
          role: 'office_staff',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'S003',
          name: '鈴木 優子',
          password: 'office2024',
          role: 'office_staff',
          companyId: 'beta_company',
        ),
      ];
    } else {
      // 乗務員のサンプルデータ（βテストアカウント）
      return [
        User(
          employeeNumber: 'D101',
          name: '金子一也',
          password: 'driver2024',
          role: 'driver',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'D102',
          name: '大谷理一',
          password: 'driver2024',
          role: 'driver',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'D103',
          name: '森下久美子',
          password: 'driver2024',
          role: 'driver',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'D104',
          name: '石塚裕美子',
          password: 'driver2024',
          role: 'driver',
          companyId: 'beta_company',
        ),
        User(
          employeeNumber: 'D105',
          name: '福島舞',
          password: 'driver2024',
          role: 'driver',
          companyId: 'beta_company',
        ),
      ];
    }
  }

  Future<Map<String, int>> _getDriverStatistics(User driver) async {
    return await DatabaseService.getMedicalCheckupStatistics(driver.id);
  }

  Future<String> _exportToCSV() async {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln(
      '社員番号,氏名,診断種別,前回受診日,次回予定日,実施機関,診断書番号,ステータス',
    );

    // データ行
    for (final employee in _employees) {
      final checkups = await DatabaseService.getMedicalCheckupsByUser(employee.id);
      
      if (checkups.isEmpty) {
        buffer.writeln(
          '${employee.employeeNumber},${employee.name},未受診,-,-,-,-,未受診',
        );
        continue;
      }

      for (final checkup in checkups) {
        final status = _getCheckupStatus(checkup);
        final checkupDateStr = '${checkup.checkupDate.year}/${checkup.checkupDate.month}/${checkup.checkupDate.day}';
        final nextDueDateStr = '${checkup.nextDueDate.year}/${checkup.nextDueDate.month}/${checkup.nextDueDate.day}';
        
        buffer.writeln(
          '${employee.employeeNumber},${employee.name},${checkup.type.displayName},$checkupDateStr,$nextDueDateStr,${checkup.institution},${ checkup.certificateNumber},$status',
        );
      }
    }

    return buffer.toString();
  }

  String _getCheckupStatus(MedicalCheckup checkup) {
    final now = DateTime.now();
    final daysUntilDue = checkup.nextDueDate.difference(now).inDays;

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

  Future<void> _showExportDialog() async {
    final csvData = await _exportToCSV();
    
    if (!mounted) return;
    
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

    final String title = widget.employeeType == 'office' 
        ? '事務員 - 健康診断管理'
        : '乗務員 - 健康診断管理';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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

              // 従業員一覧
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.employeeType == 'office' 
                              ? Icons.business_center 
                              : Icons.local_taxi,
                          color: widget.employeeType == 'office' 
                              ? Colors.blue 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.employeeType == 'office' ? '事務員' : '乗務員'}一覧 (${_employees.length}名)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_employees.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '従業員データがありません',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                        
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MedicalCheckupScreen(
                                      user: employee,
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
                                        backgroundColor: widget.employeeType == 'office' 
                                            ? Colors.blue 
                                            : Colors.orange,
                                        child: Text(
                                          employee.name[0],
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
                                              employee.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '社員番号: ${employee.employeeNumber}',
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
                                  // βテスト用: サンプル統計データを表示
                                  _buildSampleStatistics(),
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

  /// βテスト用: サンプル統計データを表示
  Widget _buildSampleStatistics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatBadge('合計', '3', Colors.blue),
        _buildStatBadge('正常', '2', Colors.green),
        _buildStatBadge('要注意', '1', Colors.orange),
        _buildStatBadge('期限切れ', '0', Colors.red),
      ],
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
