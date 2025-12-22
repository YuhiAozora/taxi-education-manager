import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/vehicle_inspection.dart';
import '../services/database_service.dart';

/// 整備点検履歴画面
class InspectionHistoryScreen extends StatefulWidget {
  final User currentUser;

  const InspectionHistoryScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<InspectionHistoryScreen> createState() => _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  List<VehicleInspection> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _isLoading = true);

    try {
      final inspections = await DatabaseService.getVehicleInspections(
        widget.currentUser.employeeNumber,
      );

      setState(() {
        _inspections = inspections.cast<VehicleInspection>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
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
        title: const Text('点検履歴'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inspections.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInspections,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inspections.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(_inspections[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '点検履歴がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '日常点検を実施すると履歴が表示されます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(VehicleInspection inspection) {
    final hasNgItems = inspection.ngCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showInspectionDetail(inspection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日時とステータス
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(inspection.inspectionDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasNgItems
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasNgItems ? Colors.orange : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasNgItems ? Icons.warning : Icons.check_circle,
                          size: 16,
                          color: hasNgItems ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasNgItems ? '要確認' : '全て良好',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasNgItems ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 統計情報
              Row(
                children: [
                  _buildStatBadge('良', inspection.okCount, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatBadge('否', inspection.ngCount, Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '/ ${inspection.items.length}項目',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // 否項目の詳細
              if (hasNgItems) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getNgItemsPreview(inspection),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getNgItemsPreview(VehicleInspection inspection) {
    final ngItems = inspection.items.entries
        .where((entry) => entry.value.isOk == false)
        .map((entry) => entry.value.itemName)
        .take(3)
        .toList();

    if (ngItems.isEmpty) return '';

    final preview = ngItems.join('、');
    if (inspection.ngCount > 3) {
      return '$preview 他${inspection.ngCount - 3}件';
    }
    return preview;
  }

  void _showInspectionDetail(VehicleInspection inspection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '点検詳細',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(inspection.inspectionDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 詳細リスト
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailSection(inspection, '運転者席'),
                    _buildDetailSection(inspection, '前部'),
                    _buildDetailSection(inspection, '後部'),
                    _buildDetailSection(inspection, 'その他'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(VehicleInspection inspection, String category) {
    final items = inspection.items.entries
        .where((entry) => entry.value.category == category)
        .toList()
      ..sort((a, b) => a.value.order.compareTo(b.value.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...items.map((entry) {
          final item = entry.value;
          final isOk = item.isOk ?? true;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOk
                  ? Colors.green.withOpacity(0.05)
                  : Colors.red.withOpacity(0.05),
              border: Border.all(
                color: isOk
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isOk ? Icons.check_circle : Icons.cancel,
                  color: isOk ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.detail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (!isOk && item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '備考: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.note!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
