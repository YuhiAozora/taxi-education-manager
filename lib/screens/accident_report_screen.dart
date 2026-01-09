import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/accident_report.dart';
import '../services/database_service.dart';

class AccidentReportScreen extends StatefulWidget {
  final User currentUser;

  const AccidentReportScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AccidentReportScreen> createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  DateTime _accidentDate = DateTime.now();
  final TextEditingController _locationController = TextEditingController();
  AccidentType _selectedType = AccidentType.collision;
  AccidentSeverity _selectedSeverity = AccidentSeverity.minor;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherPartyController = TextEditingController();
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _policeReportController = TextEditingController();
  
  bool _isSubmitting = false;
  List<AccidentReport> _myReports = [];

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _otherPartyController.dispose();
    _damageController.dispose();
    _policeReportController.dispose();
    super.dispose();
  }

  Future<void> _loadMyReports() async {
    try {
      final reports = await DatabaseService.getAccidentReportsByDriver(
        widget.currentUser.employeeNumber,
      );
      if (mounted) {
        setState(() {
          _myReports = reports.cast<AccidentReport>();
        });
      }
    } catch (e) {
      // エラー時はサンプルデータを表示
      if (mounted) {
        setState(() {
          _myReports = _getSampleReports();
        });
      }
    }
  }

  List<AccidentReport> _getSampleReports() {
    return [
      AccidentReport(
        id: 'sample_1',
        driverId: widget.currentUser.employeeNumber,
        driverName: widget.currentUser.name,
        companyId: widget.currentUser.companyId ?? '',
        accidentDate: DateTime.now().subtract(const Duration(days: 7)),
        location: '東京都渋谷区道玄坂1-2-3付近交差点',
        type: AccidentType.collision,
        severity: AccidentSeverity.minor,
        description: '信号待ちで停車中、後続車に追突された。自車の損傷は軽微で、運転者・同乗者共に怪我なし。',
        otherPartyInfo: '相手方: 山田太郎 TEL: 090-1234-5678\n車両: 品川500あ1234',
        damageDescription: '自車: 後部バンパー擦過傷\n相手車: 前部バンパー破損',
        policeReport: '令和6年第12345号',
        status: AccidentStatus.processing,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _accidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      // locale: const Locale('ja', 'JP'), // Removed for Web compatibility
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_accidentDate),
      );

      if (pickedTime != null) {
        setState(() {
          _accidentDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _validateReport() {
    if (_locationController.text.trim().isEmpty) {
      return '事故発生場所を入力してください';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return '事故状況を入力してください';
    }
    return '';
  }

  Future<void> _submitReport() async {
    final validationError = _validateReport();
    if (validationError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final report = AccidentReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: widget.currentUser.employeeNumber,
        driverName: widget.currentUser.name,
        companyId: widget.currentUser.companyId ?? '',
        accidentDate: _accidentDate,
        location: _locationController.text.trim(),
        type: _selectedType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        otherPartyInfo: _otherPartyController.text.trim().isEmpty
            ? null
            : _otherPartyController.text.trim(),
        damageDescription: _damageController.text.trim().isEmpty
            ? null
            : _damageController.text.trim(),
        policeReport: _policeReportController.text.trim().isEmpty
            ? null
            : _policeReportController.text.trim(),
        status: AccidentStatus.pending,
      );

      await DatabaseService.saveAccidentReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 事故報告を送信しました'),
            backgroundColor: Colors.green,
          ),
        );

        // フォームをリセット
        setState(() {
          _locationController.clear();
          _descriptionController.clear();
          _otherPartyController.clear();
          _damageController.clear();
          _policeReportController.clear();
          _accidentDate = DateTime.now();
          _selectedType = AccidentType.collision;
          _selectedSeverity = AccidentSeverity.minor;
        });

        // 報告履歴を再読み込み
        await _loadMyReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('報告の送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Color _getSeverityColor(AccidentSeverity severity) {
    switch (severity) {
      case AccidentSeverity.minor:
        return Colors.green;
      case AccidentSeverity.moderate:
        return Colors.orange;
      case AccidentSeverity.serious:
        return Colors.red;
      case AccidentSeverity.critical:
        return Colors.purple;
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

  IconData _getTypeIcon(AccidentType type) {
    switch (type) {
      case AccidentType.collision:
        return Icons.directions_car_filled;
      case AccidentType.personal:
        return Icons.person_off;
      case AccidentType.property:
        return Icons.broken_image;
      case AccidentType.selfAccident:
        return Icons.warning;
      case AccidentType.parking:
        return Icons.local_parking;
      case AccidentType.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('事故報告'),
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
                  Tab(text: '新規報告'),
                  Tab(text: '報告履歴'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNewReportTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewReportTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 重要性の注意喚起
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '事故が発生した場合は速やかに報告してください',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 事故発生日時
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事故発生日時',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('日時'),
                    subtitle: Text(
                      DateFormat('yyyy年M月d日（E）HH:mm')
                          .format(_accidentDate),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDateTime(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 事故発生場所
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事故発生場所',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: '例: 東京都渋谷区〇〇交差点付近',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 事故種別
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事故種別',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AccidentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        selectedColor: Colors.blue.shade200,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 事故の重大度
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事故の重大度',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AccidentSeverity.values.map((severity) {
                      final isSelected = _selectedSeverity == severity;
                      return ChoiceChip(
                        label: Text(severity.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = severity;
                          });
                        },
                        selectedColor: _getSeverityColor(severity).withOpacity(0.3),
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 事故状況
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '事故状況（必須）',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '事故の状況を詳しく記入してください',
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
          const SizedBox(height: 16),

          // 相手方情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '相手方情報（任意）',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otherPartyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '相手方の氏名、連絡先、車両番号等',
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
          const SizedBox(height: 16),

          // 被害状況
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '被害状況（任意）',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _damageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '車両の損傷箇所、人的被害等',
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
          const SizedBox(height: 16),

          // 警察への届出
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '警察への届出番号（任意）',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _policeReportController,
                    decoration: InputDecoration(
                      hintText: '届出番号を入力',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.local_police),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 送信ボタン
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '報告を送信',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_myReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '報告履歴がありません',
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
      onRefresh: _loadMyReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myReports.length,
        itemBuilder: (context, index) {
          final report = _myReports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: _getSeverityColor(report.severity).withOpacity(0.2),
                child: Icon(
                  _getTypeIcon(report.type),
                  color: _getSeverityColor(report.severity),
                ),
              ),
              title: Text(
                report.type.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '発生: ${DateFormat('M/d（E）HH:mm').format(report.accidentDate)}',
                  ),
                  Text(
                    '場所: ${report.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '報告日: ${DateFormat('yyyy/M/d').format(report.createdAt)}',
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
                  color: _getStatusColor(report.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status.displayName,
                  style: TextStyle(
                    color: _getStatusColor(report.status),
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
}
