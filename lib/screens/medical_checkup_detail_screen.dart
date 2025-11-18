import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medical_checkup.dart';
import '../services/database_service.dart';

/// 診断記録の詳細編集画面
class MedicalCheckupDetailScreen extends StatefulWidget {
  final String userId;
  final MedicalCheckupType checkupType;
  final MedicalCheckup? existingCheckup;

  const MedicalCheckupDetailScreen({
    super.key,
    required this.userId,
    required this.checkupType,
    this.existingCheckup,
  });

  @override
  State<MedicalCheckupDetailScreen> createState() =>
      _MedicalCheckupDetailScreenState();
}

class _MedicalCheckupDetailScreenState
    extends State<MedicalCheckupDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _certificateNumberController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _checkupDate;
  late DateTime _nextDueDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingCheckup != null;

    if (_isEditing) {
      final checkup = widget.existingCheckup!;
      _checkupDate = checkup.checkupDate;
      _nextDueDate = checkup.nextDueDate ?? DateTime.now();
      _institutionController.text = checkup.institution ?? '';
      _certificateNumberController.text = checkup.certificateNumber ?? '';
      _notesController.text = checkup.notes ?? '';
    } else {
      _checkupDate = DateTime.now();
      _nextDueDate = widget.checkupType.calculateNextDueDate(_checkupDate);
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _certificateNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkupDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
    );

    if (picked != null) {
      setState(() {
        _checkupDate = picked;
        _nextDueDate = widget.checkupType.calculateNextDueDate(_checkupDate);
      });
    }
  }

  Future<void> _selectNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: _checkupDate,
      lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );

    if (picked != null) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  Future<void> _saveCheckup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final checkup = MedicalCheckup(
      id: _isEditing ? widget.existingCheckup!.id : const Uuid().v4(),
      userId: widget.userId,
      type: widget.checkupType,
      checkupDate: _checkupDate,
      institution: _institutionController.text.trim().isEmpty
          ? null
          : _institutionController.text.trim(),
      certificateNumber: _certificateNumberController.text.trim().isEmpty
          ? null
          : _certificateNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      nextDueDate: _nextDueDate,
      notificationSent: false,
      createdAt: _isEditing
          ? widget.existingCheckup!.createdAt
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMedicalCheckup(checkup);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '診断記録を更新しました' : '診断記録を追加しました'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? '${widget.checkupType.displayName}の編集'
              : '${widget.checkupType.displayName}の追加',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 診断情報カード
                  Card(
                    color: Colors.blue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.checkupType.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.checkupType.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (widget.checkupType.isMandatory) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'この診断は法令で義務付けられています。\n期限内に必ず受診してください。',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 24),

                  // 受診日
                  const Text(
                    '受診日',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectCheckupDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 16),
                          Text(
                            '${_checkupDate.year}年${_checkupDate.month}月${_checkupDate.day}日',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 次回予定日
                  const Text(
                    '次回診断予定日',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectNextDueDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_nextDueDate.year}年${_nextDueDate.month}月${_nextDueDate.day}日',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.checkupType.notificationDaysBefore}日前に通知します',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 実施機関
                  const Text(
                    '実施機関',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _institutionController,
                    decoration: const InputDecoration(
                      hintText: '例: ○○適性診断センター',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 診断書番号
                  const Text(
                    '診断書番号',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _certificateNumberController,
                    decoration: const InputDecoration(
                      hintText: '例: 診第1234号',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 備考
                  const Text(
                    '備考',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: '診断結果や特記事項など',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveCheckup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isEditing ? '更新' : '保存',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
