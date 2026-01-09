import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/education_record.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';

/// 教育台帳管理画面（管理者用）
class EducationRecordsScreen extends StatefulWidget {
  final User currentUser;

  const EducationRecordsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EducationRecordsScreen> createState() => _EducationRecordsScreenState();
}

class _EducationRecordsScreenState extends State<EducationRecordsScreen> {
  List<EducationRecord> _records = [];
  bool _isLoading = true;
  String? _error;
  final dateFormatter = DateFormat('yyyy年MM月dd日');

  @override
  void initState() {
    super.initState();
    _loadEducationRecords();
  }

  Future<void> _loadEducationRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<EducationRecord> records;
      
      // ユーザーの役割に応じて取得
      if (widget.currentUser.role == 'super_admin') {
        // スーパー管理者：全記録を取得
        records = await DatabaseService.getAllEducationRecords();
      } else {
        // 会社管理者：自社の記録のみ
        final companyId = 'COMPANY001'; // TODO: ユーザーの会社IDを取得
        records = await DatabaseService.getEducationRecordsByCompany(companyId);
      }

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '教育台帳の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePdf(EducationRecord record) async {
    try {
      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // PDF生成
      // TODO: 教育記録簿PDF生成機能は今後実装予定
      // final pdfData = await PdfService.generateEducationRecordPdf(record);
      // final fileName = '教育台帳_${record.userName}_${dateFormatter.format(DateTime.now())}.pdf';
      // await PdfService.previewPdf(pdfData, fileName);
      
      // ローディング非表示
      if (!mounted) return;
      Navigator.of(context).pop();

      // エラーメッセージ表示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('教育記録簿PDF生成機能は今後実装予定です'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // ローディング非表示
      if (!mounted) return;
      Navigator.of(context).pop();
      
      // エラー表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF生成に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editNotes(EducationRecord record) async {
    final notesController = TextEditingController(text: record.adminNotes ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('管理者コメント編集'),
          content: TextField(
            controller: notesController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '特記事項・管理者コメントを入力',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(notesController.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await DatabaseService.updateEducationRecordNotes(record.userId, result);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを保存しました')),
        );
        
        // リロード
        _loadEducationRecords();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
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
        title: const Text('教育台帳管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEducationRecords,
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
                        onPressed: _loadEducationRecords,
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : _records.isEmpty
                  ? const Center(
                      child: Text(
                        '教育台帳がありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildRecordCard(record);
                      },
                    ),
    );
  }

  Widget _buildRecordCard(EducationRecord record) {
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
                    record.userName.isNotEmpty ? record.userName[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '社員番号: ${record.userId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 統計サマリー
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  Icons.school,
                  '教育',
                  '${record.educationHistory.length}回',
                  Colors.blue,
                ),
                _buildStatChip(
                  Icons.health_and_safety,
                  '健康診断',
                  '${record.medicalCheckups.length}回',
                  Colors.green,
                ),
                _buildStatChip(
                  Icons.build,
                  '整備点検',
                  '${record.vehicleInspections.length}回',
                  Colors.orange,
                ),
                _buildStatChip(
                  Icons.event_busy,
                  '休暇',
                  '${record.leaveRecords.length}件',
                  Colors.purple,
                ),
                _buildStatChip(
                  Icons.warning,
                  '事故',
                  '${record.accidentRecords.length}件',
                  record.accidentRecords.isEmpty ? Colors.green : Colors.red,
                ),
              ],
            ),

            // 基本情報
            const SizedBox(height: 16),
            _buildInfoRow('入社日', dateFormatter.format(record.joinDate)),
            _buildInfoRow('経験年数', '${record.experienceYears}年'),
            _buildInfoRow('運転免許', record.licenseType),
            if (record.licenseExpiry != null)
              _buildInfoRow(
                '免許有効期限',
                dateFormatter.format(record.licenseExpiry!),
              ),
            if (record.lastUpdated != null)
              _buildInfoRow(
                '最終更新',
                DateFormat('yyyy/MM/dd HH:mm').format(record.lastUpdated!),
              ),

            // 管理者コメント
            if (record.adminNotes != null && record.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '管理者コメント',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.adminNotes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // アクションボタン
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editNotes(record),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('コメント編集'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _generatePdf(record),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF出力'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
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
}
