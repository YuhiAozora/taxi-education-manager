import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/medical_checkup.dart';
import '../services/database_service.dart';
import 'medical_checkup_detail_screen.dart';

/// 運転者の診断記録管理画面
class MedicalCheckupScreen extends StatefulWidget {
  final User user;

  const MedicalCheckupScreen({super.key, required this.user});

  @override
  State<MedicalCheckupScreen> createState() => _MedicalCheckupScreenState();
}

class _MedicalCheckupScreenState extends State<MedicalCheckupScreen> {
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadCheckups();
  }

  Future<void> _loadCheckups() async {
    final stats = await DatabaseService.getMedicalCheckupStatistics(widget.user.id);
    setState(() {
      _statistics = stats.map((key, value) => MapEntry(key, value as dynamic));
    });
  }

  Future<void> _addNewCheckup(MedicalCheckupType type) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalCheckupDetailScreen(
          userId: widget.user.id,
          checkupType: type,
        ),
      ),
    );

    if (result == true) {
      _loadCheckups();
    }
  }

  Future<void> _editCheckup(MedicalCheckup checkup) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalCheckupDetailScreen(
          userId: widget.user.id,
          checkupType: checkup.type,
          existingCheckup: checkup,
        ),
      ),
    );

    if (result == true) {
      _loadCheckups();
    }
  }

  Future<void> _deleteCheckup(MedicalCheckup checkup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('診断記録の削除'),
        content: Text('${checkup.type.displayName}の記録を削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteMedicalCheckup(checkup.id);
      _loadCheckups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('診断記録を削除しました')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadCheckupCardData(MedicalCheckupType type) async {
    final latest = await DatabaseService.getLatestCheckupByType(widget.user.id, type);
    final statusColor = await _getStatusColor(type);
    final statusText = await _getStatusText(type);
    
    return {
      'latest': latest,
      'statusColor': statusColor,
      'statusText': statusText,
    };
  }

  Future<Color> _getStatusColor(MedicalCheckupType type) async {
    final latest = await DatabaseService.getLatestCheckupByType(widget.user.id, type);
    
    if (latest == null) {
      return Colors.grey;
    }

    final now = DateTime.now();
    final daysUntilDue = latest.nextDueDate.difference(now).inDays;

    if (daysUntilDue < 0) {
      return Colors.red; // 期限切れ
    } else if (daysUntilDue <= type.notificationDaysBefore) {
      return Colors.orange; // もうすぐ期限
    } else {
      return Colors.green; // 正常
    }
  }

  Future<String> _getStatusText(MedicalCheckupType type) async {
    final latest = await DatabaseService.getLatestCheckupByType(widget.user.id, type);
    
    if (latest == null) {
      return '未受診';
    }

    final now = DateTime.now();
    final daysUntilDue = latest.nextDueDate.difference(now).inDays;

    if (daysUntilDue < 0) {
      return '期限切れ (${-daysUntilDue}日経過)';
    } else if (daysUntilDue == 0) {
      return '本日が期限';
    } else if (daysUntilDue <= type.notificationDaysBefore) {
      return 'あと${daysUntilDue}日';
    } else {
      return '正常';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name} - 診断管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 統計情報カード
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    const Text(
                      '診断状況サマリー',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          '合計',
                          _statistics['total']?.toString() ?? '0',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          '正常',
                          _statistics['upToDate']?.toString() ?? '0',
                          Colors.green,
                        ),
                        _buildStatCard(
                          '要注意',
                          _statistics['upcoming']?.toString() ?? '0',
                          Colors.orange,
                        ),
                        _buildStatCard(
                          '期限切れ',
                          _statistics['overdue']?.toString() ?? '0',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 各診断タイプのカード
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MedicalCheckupType.values.length,
                itemBuilder: (context, index) {
                  final type = MedicalCheckupType.values[index];
                  
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _loadCheckupCardData(type),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      
                      final data = snapshot.data!;
                      final latest = data['latest'] as MedicalCheckup?;
                      final statusColor = data['statusColor'] as Color;
                      final statusText = data['statusText'] as String;
                      
                      return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        if (latest != null) {
                          _editCheckup(latest);
                        } else {
                          _addNewCheckup(type);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    type.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (type.isMandatory) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '⚠️ 義務診断',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (latest != null) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '前回受診日',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${latest.checkupDate.year}年${latest.checkupDate.month}月${latest.checkupDate.day}日',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '次回予定日',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${latest.nextDueDate.year}年${latest.nextDueDate.month}月${latest.nextDueDate.day}日',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (latest.institution.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '実施機関: ${latest.institution}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editCheckup(latest),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('編集'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _deleteCheckup(latest),
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('削除'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _addNewCheckup(type),
                                  icon: const Icon(Icons.add),
                                  label: const Text('診断記録を追加'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
