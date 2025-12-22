import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/accident_report.dart';
import '../../services/database_service.dart';

/// 事故報告管理画面（管理者用）
class AccidentManagementScreen extends StatefulWidget {
  final User currentUser;

  const AccidentManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AccidentManagementScreen> createState() => _AccidentManagementScreenState();
}

class _AccidentManagementScreenState extends State<AccidentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AccidentReport> _pendingReports = [];
  List<AccidentReport> _processedReports = [];
  bool _isLoading = true;
  String? _error;
  final dateTimeFormatter = DateFormat('yyyy/MM/dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAccidentReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccidentReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 管理者の会社IDに基づいて事故報告を取得
      final allReports = await DatabaseService.getAllAccidentReports('COMPANY001');
      
      setState(() {
        _pendingReports = allReports
            .where((r) => r.status == AccidentStatus.pending)
            .toList();
        _processedReports = allReports
            .where((r) => r.status != AccidentStatus.pending)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '事故報告の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processReport(AccidentReport report, AccidentStatus newStatus) async {
    final commentController = TextEditingController();
    final statusLabel = _getStatusLabel(newStatus);

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('事故報告を$statusLabelに変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('この事故報告を$statusLabelに変更します。'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '処理メモ（任意）',
                hintText: '対応内容や指示事項を入力',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, commentController.text),
            child: Text('変更'),
          ),
        ],
      ),
    );

    if (comment != null) {
      try {
        await DatabaseService.updateAccidentReportStatus(
          report.id,
          newStatus.toString().split('.').last,
          adminComment: comment.isNotEmpty ? comment : null,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('事故報告を${statusLabel}に変更しました'),
            backgroundColor: Colors.green,
          ),
        );

        // 教育台帳を更新
        await DatabaseService.updateEducationRecord(report.driverId);

        // リロード
        _loadAccidentReports();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事故報告管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending),
              text: '未処理 (${_pendingReports.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: '処理済み (${_processedReports.length})',
            ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: '統計',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccidentReports,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAccidentReports,
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingList(),
                    _buildProcessedList(),
                    _buildStatistics(),
                  ],
                ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '未処理の事故報告はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReports.length,
      itemBuilder: (context, index) {
        final report = _pendingReports[index];
        return _buildAccidentReportCard(report, isPending: true);
      },
    );
  }

  Widget _buildProcessedList() {
    if (_processedReports.isEmpty) {
      return const Center(
        child: Text(
          '処理済みの事故報告はありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _processedReports.length,
      itemBuilder: (context, index) {
        final report = _processedReports[index];
        return _buildAccidentReportCard(report, isPending: false);
      },
    );
  }

  Widget _buildStatistics() {
    final allReports = [..._pendingReports, ..._processedReports];
    
    if (allReports.isEmpty) {
      return const Center(
        child: Text(
          '事故報告データがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 統計計算
    final typeCount = <String, int>{};
    final severityCount = <String, int>{};
    for (final report in allReports) {
      typeCount[report.type] = (typeCount[report.type] ?? 0) + 1;
      severityCount[report.severity] = (severityCount[report.severity] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '事故統計',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildStatCard(
            '総報告件数',
            '${allReports.length}件',
            Icons.description,
            Colors.blue,
          ),
          
          const SizedBox(height: 24),
          const Text(
            '事故種別',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...typeCount.entries.map((e) => _buildStatItem(e.key, e.value, allReports.length)),
          
          const SizedBox(height: 24),
          const Text(
            '重大度',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...severityCount.entries.map((e) => _buildStatItem(e.key, e.value, allReports.length)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, int total) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '$count件 ($percentage%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccidentReportCard(AccidentReport report, {required bool isPending}) {
    final severityColor = _getSeverityColor(report.severity);
    final statusColor = _getStatusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: severityColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(report.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '運転手: ${report.driverId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    _getSeverityLabel(report.severity),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: severityColor,
                ),
              ],
            ),
            const Divider(height: 24),

            // 事故詳細
            _buildInfoRow('発生日時', dateTimeFormatter.format(report.accidentDate)),
            _buildInfoRow('場所', report.location),
            _buildInfoRow('状況', report.description),
            if (report.otherPartyInfo != null)
              _buildInfoRow('相手方', report.otherPartyInfo!),
            if (report.damageDescription != null)
              _buildInfoRow('被害状況', report.damageDescription!),
            if (report.policeReport != null)
              _buildInfoRow('警察届出番号', report.policeReport!),
            
            _buildInfoRow('報告日時', dateTimeFormatter.format(report.createdAt)),

            if (!isPending) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(report.status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(report.status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (report.adminComment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '処理メモ: ${report.adminComment}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // アクションボタン（未処理の場合のみ）
            if (isPending) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _processReport(report, AccidentStatus.processing),
                    icon: const Icon(Icons.build, size: 18),
                    label: const Text('処理中'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _processReport(report, AccidentStatus.completed),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('処理完了'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AccidentSeverity severity) {
    switch (severity) {
      case AccidentSeverity.minor:
        return Colors.yellow.shade700;
      case AccidentSeverity.moderate:
        return Colors.orange;
      case AccidentSeverity.serious:
        return Colors.red;
      case AccidentSeverity.critical:
        return Colors.red.shade900;
    }
  }

  Color _getStatusColor(AccidentStatus status) {
    switch (status) {
      case AccidentStatus.pending:
        return Colors.orange;
      case AccidentStatus.processing:
        return Colors.blue;
      case AccidentStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(AccidentStatus status) {
    switch (status) {
      case AccidentStatus.pending:
        return Icons.pending;
      case AccidentStatus.processing:
        return Icons.build;
      case AccidentStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getStatusLabel(AccidentStatus status) {
    switch (status) {
      case AccidentStatus.pending:
        return '報告済み';
      case AccidentStatus.processing:
        return '処理中';
      case AccidentStatus.completed:
        return '完了';
    }
  }
  
  String _getTypeLabel(AccidentType type) {
    switch (type) {
      case AccidentType.collision:
        return '接触事故';
      case AccidentType.personal:
        return '人身事故';
      case AccidentType.property:
        return '物損事故';
      case AccidentType.selfAccident:
        return '自損事故';
      case AccidentType.parking:
        return '駐車場内事故';
      case AccidentType.nearMiss:
        return 'ニアミス';
      case AccidentType.other:
        return 'その他';
    }
  }
  
  String _getSeverityLabel(AccidentSeverity severity) {
    switch (severity) {
      case AccidentSeverity.minor:
        return '軽微';
      case AccidentSeverity.moderate:
        return '通常';
      case AccidentSeverity.serious:
        return '重大';
      case AccidentSeverity.critical:
        return '極めて重大';
    }
  }
}
