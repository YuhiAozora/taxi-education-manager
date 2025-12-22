import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/leave_request.dart';
import '../../services/database_service.dart';

/// 休暇申請承認画面（管理者用）
class LeaveApprovalScreen extends StatefulWidget {
  final User currentUser;

  const LeaveApprovalScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaveRequest> _pendingRequests = [];
  List<LeaveRequest> _processedRequests = [];
  bool _isLoading = true;
  String? _error;
  final dateFormatter = DateFormat('yyyy年MM月dd日');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 管理者の会社IDに基づいて休暇申請を取得
      final allRequests = await DatabaseService.getAllLeaveRequests('COMPANY001');
      
      setState(() {
        _pendingRequests = allRequests
            .where((r) => r.status == LeaveStatus.pending)
            .toList();
        _processedRequests = allRequests
            .where((r) => r.status != LeaveStatus.pending)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '休暇申請の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(LeaveRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('休暇申請を承認'),
        content: Text('${request.employeeName}さんの休暇申請を承認しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('承認'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.updateLeaveRequestStatus(
          request.id,
          LeaveStatus.approved,
          widget.currentUser.name,
          null,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('休暇申請を承認しました'),
            backgroundColor: Colors.green,
          ),
        );

        // 教育台帳を更新
        await DatabaseService.updateEducationRecord(request.employeeNumber);

        // リロード
        _loadLeaveRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('承認に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(LeaveRequest request) async {
    final commentController = TextEditingController();

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('休暇申請を却下'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.employeeName}さんの休暇申請を却下します。'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '却下理由（必須）',
                hintText: '却下理由を入力してください',
                border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('却下'),
          ),
        ],
      ),
    );

    if (comment != null && comment.isNotEmpty) {
      try {
        await DatabaseService.updateLeaveRequestStatus(
          request.id,
          LeaveStatus.rejected,
          widget.currentUser.name,
          comment,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('休暇申請を却下しました'),
            backgroundColor: Colors.red,
          ),
        );

        // 教育台帳を更新
        await DatabaseService.updateEducationRecord(request.employeeNumber);

        // リロード
        _loadLeaveRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('却下処理に失敗しました: $e'),
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
        title: const Text('休暇申請管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: '承認待ち (${_pendingRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: '処理済み (${_processedRequests.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaveRequests,
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
                        onPressed: _loadLeaveRequests,
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
                  ],
                ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '承認待ちの申請はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildLeaveRequestCard(request, isPending: true);
      },
    );
  }

  Widget _buildProcessedList() {
    if (_processedRequests.isEmpty) {
      return const Center(
        child: Text(
          '処理済みの申請はありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _processedRequests.length,
      itemBuilder: (context, index) {
        final request = _processedRequests[index];
        return _buildLeaveRequestCard(request, isPending: false);
      },
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request, {required bool isPending}) {
    final leaveTypeColor = _getLeaveTypeColor(request.type);
    final statusColor = _getStatusColor(request.status);

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
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    request.employeeName.isNotEmpty
                        ? request.employeeName[0]
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '社員番号: ${request.employeeNumber}',
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
                    _getLeaveTypeLabel(request.type),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: leaveTypeColor,
                ),
              ],
            ),
            const Divider(height: 24),

            // 申請内容
            _buildInfoRow('期間', 
                '${dateFormatter.format(request.startDate)} ～ ${dateFormatter.format(request.endDate)}'),
            _buildInfoRow('理由', request.reason),
            _buildInfoRow('申請日時', 
                DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt)),
            
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
                          request.status == LeaveStatus.approved
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(request.status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (request.approverComment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'コメント: ${request.approverComment}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (request.approvedAt != null)
                      Text(
                        '処理日時: ${DateFormat('yyyy/MM/dd HH:mm').format(request.approvedAt!)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],

            // アクションボタン（承認待ちの場合のみ）
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('却下'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('承認'),
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
            width: 80,
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

  Color _getLeaveTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.paidLeave:
        return Colors.green;
      case LeaveType.specialLeave:
        return Colors.blue;
      case LeaveType.absence:
        return Colors.orange;
      case LeaveType.compensatory:
        return Colors.purple;
    }
  }

  String _getLeaveTypeLabel(LeaveType type) {
    switch (type) {
      case LeaveType.paidLeave:
        return '有給休暇';
      case LeaveType.specialLeave:
        return '特別休暇';
      case LeaveType.absence:
        return '欠勤届';
      case LeaveType.compensatory:
        return '代休届';
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return '承認待ち';
      case LeaveStatus.approved:
        return '承認済み';
      case LeaveStatus.rejected:
        return '却下';
      case LeaveStatus.cancelled:
        return '取り消し';
    }
  }
}
