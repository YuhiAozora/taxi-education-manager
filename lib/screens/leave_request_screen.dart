import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/leave_request.dart';
import '../services/database_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  final User currentUser;

  const LeaveRequestScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  LeaveType _selectedLeaveType = LeaveType.paidLeave;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  List<LeaveRequest> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    try {
      final requests = await DatabaseService.getLeaveRequestsByEmployee(
        widget.currentUser.employeeNumber,
      );
      if (mounted) {
        setState(() {
          _myRequests = requests.cast<LeaveRequest>();
        });
      }
    } catch (e) {
      // エラー時はサンプルデータを表示
      if (mounted) {
        setState(() {
          _myRequests = _getSampleRequests();
        });
      }
    }
  }

  List<LeaveRequest> _getSampleRequests() {
    return [
      LeaveRequest(
        id: 'sample_1',
        userId: widget.currentUser.employeeNumber,
        companyId: widget.currentUser.companyId ?? '',
        type: LeaveType.paidLeave,
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 22)),
        reason: '家族旅行のため',
        status: LeaveStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      LeaveRequest(
        id: 'sample_2',
        userId: widget.currentUser.employeeNumber,
        companyId: widget.currentUser.companyId ?? '',
        type: LeaveType.specialLeave,
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        reason: '結婚式参列のため',
        status: LeaveStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // locale: const Locale('ja', 'JP'), // Webでのエラー防止のためコメントアウト
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // 開始日が終了日より後の場合、終了日を開始日に合わせる
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
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

  String _validateRequest() {
    // 理由が入力されているか確認
    if (_reasonController.text.trim().isEmpty) {
      return '理由を入力してください';
    }

    // 有給休暇の場合は14日前までのルール
    if (_selectedLeaveType == LeaveType.paidLeave) {
      final daysUntilLeave = _startDate.difference(DateTime.now()).inDays;
      if (daysUntilLeave < 14) {
        return '有給休暇は14日前までに申請してください\n（あと${14 - daysUntilLeave}日必要です）';
      }
    }

    // 開始日が終了日より後でないか確認
    if (_startDate.isAfter(_endDate)) {
      return '開始日は終了日より前に設定してください';
    }

    return '';
  }

  Future<void> _submitRequest() async {
    final validationError = _validateRequest();
    if (validationError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUser.employeeNumber,
        companyId: widget.currentUser.companyId ?? '',
        type: _selectedLeaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveLeaveRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 申請を送信しました'),
            backgroundColor: Colors.green,
          ),
        );

        // フォームをリセット
        setState(() {
          _reasonController.clear();
          _startDate = DateTime.now();
          _endDate = DateTime.now();
          _selectedLeaveType = LeaveType.paidLeave;
        });

        // 申請履歴を再読み込み
        await _loadMyRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('申請の送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('休暇申請'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.primary,
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: '新規申請'),
                  Tab(text: '申請履歴'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNewRequestTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewRequestTab() {
    final theme = Theme.of(context);
    final validationError = _validateRequest();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '申請種類',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeaveType.values.map((type) {
                      final isSelected = _selectedLeaveType == type;
                      return ChoiceChip(
                        label: Text(_getLeaveTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLeaveType = type;
                          });
                        },
                        selectedColor: _getLeaveTypeColor(type).withOpacity(0.3),
                        backgroundColor: Colors.grey.shade200,
                        avatar: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: _getLeaveTypeColor(type),
                                size: 20,
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                  if (_selectedLeaveType == LeaveType.paidLeave) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '有給休暇は14日前までに申請してください',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '期間',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('開始日'),
                    subtitle: Text(
                      DateFormat('yyyy年M月d日（E）').format(_startDate),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDate(context, true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('終了日'),
                    subtitle: Text(
                      DateFormat('yyyy年M月d日（E）').format(_endDate),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDate(context, false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '期間: ${_endDate.difference(_startDate).inDays + 1}日間',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '理由',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '休暇の理由を入力してください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (validationError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      validationError,
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading || validationError.isNotEmpty ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '申請する',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '申請履歴がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final request = _myRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: _getLeaveTypeColor(request.type).withOpacity(0.2),
                child: Icon(
                  _getLeaveTypeIcon(request.type),
                  color: _getLeaveTypeColor(request.type),
                ),
              ),
              title: Text(
                _getLeaveTypeLabel(request.type),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('M/d').format(request.startDate)} 〜 ${DateFormat('M/d').format(request.endDate)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '申請日: ${DateFormat('yyyy/M/d').format(request.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(request.status),
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getLeaveTypeIcon(LeaveType type) {
    switch (type) {
      case LeaveType.paidLeave:
        return Icons.beach_access;
      case LeaveType.specialLeave:
        return Icons.star;
      case LeaveType.absence:
        return Icons.event_busy;
      case LeaveType.compensatory:
        return Icons.swap_horiz;
    }
  }
}
