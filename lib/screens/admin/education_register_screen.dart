import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/education_register.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';

/// 教育記録簿PDF出力画面（管理者専用）
class EducationRegisterScreen extends StatefulWidget {
  final String companyId;

  const EducationRegisterScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<EducationRegisterScreen> createState() => _EducationRegisterScreenState();
}

class _EducationRegisterScreenState extends State<EducationRegisterScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  EducationRegisterSummary? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEducationData();
  }

  /// 教育データを読み込み
  Future<void> _loadEducationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DatabaseService.getEducationRegisterData(
        companyId: widget.companyId,
        year: _selectedYear,
      );

      final records = data.map((d) => EducationRegister.fromFirestore(d)).toList();
      
      // 日付順にソート
      records.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _summary = EducationRegisterSummary(
          year: _selectedYear,
          companyId: widget.companyId,
          records: records,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '教育データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  /// PDF出力
  Future<void> _generatePdf() async {
    if (_summary == null || _summary!.records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('教育記録がありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pdfBytes = await PdfService.generateEducationRegisterPdf(_summary!);
      
      await PdfService.previewPdf(
        pdfBytes,
        '教育記録簿_${_selectedYear}年度.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF出力が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PDF生成エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教育記録簿'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_summary != null && _summary!.records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _isLoading ? null : _generatePdf,
              tooltip: 'PDF出力',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEducationData,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年度選択
          _buildYearSelector(),
          const SizedBox(height: 24),

          // サマリーカード
          if (_summary != null) ...[
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // カテゴリー別集計
            _buildCategorySummary(),
            const SizedBox(height: 24),

            // 教育記録一覧
            _buildRecordsList(),
          ],

          // データなしの場合
          if (_summary == null || _summary!.records.isEmpty) ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '選択した年度の教育記録がありません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 年度選択
  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.green),
            const SizedBox(width: 12),
            const Text(
              '対象年度:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _selectedYear,
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year年度'),
                );
              }).toList(),
              onChanged: (year) {
                if (year != null) {
                  setState(() {
                    _selectedYear = year;
                  });
                  _loadEducationData();
                }
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadEducationData,
              icon: const Icon(Icons.refresh),
              label: const Text('更新'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// サマリーカード
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  '教育実績サマリー ($_selectedYear年度)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  '対象乗務員',
                  '${_summary!.totalDrivers}',
                  '名',
                  Colors.blue,
                ),
                _buildSummaryItem(
                  '実施回数',
                  '${_summary!.totalSessions}',
                  '回',
                  Colors.orange,
                ),
                _buildSummaryItem(
                  '総教育時間',
                  _summary!.totalDurationHours.toStringAsFixed(1),
                  '時間',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// カテゴリー別集計
  Widget _buildCategorySummary() {
    final categorySummary = _summary!.categorySummary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'カテゴリー別実績',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categorySummary.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}回'),
                  backgroundColor: Colors.green.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 教育記録一覧
  Widget _buildRecordsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '教育記録一覧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _summary!.records.length,
              itemBuilder: (context, index) {
                final record = _summary!.records[index];
                return _buildRecordItem(record, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(EducationRegister record, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'No.$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${record.date.year}年${record.date.month}月${record.date.day}日',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  EducationRegister.getCategoryLabel(record.category),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.green.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.content,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${record.driverName} (${record.driverId})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                record.formattedDuration,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.school, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                record.instructor,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          if (record.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.notes!,
                      style: const TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
