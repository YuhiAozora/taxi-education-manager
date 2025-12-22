import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/vehicle_inspection.dart';
import '../services/database_service.dart';

/// 整備点検チェック画面
class VehicleInspectionScreen extends StatefulWidget {
  final User currentUser;

  const VehicleInspectionScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<VehicleInspectionScreen> createState() => _VehicleInspectionScreenState();
}

class _VehicleInspectionScreenState extends State<VehicleInspectionScreen> {
  late Map<String, InspectionItem> _items;
  final Map<String, TextEditingController> _noteControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = VehicleInspection.createTemplate();
    
    // 各項目の備考欄コントローラーを初期化
    for (var key in _items.keys) {
      _noteControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// カテゴリ別に項目を取得
  List<MapEntry<String, InspectionItem>> _getItemsByCategory(String category) {
    return _items.entries
        .where((entry) => entry.value.category == category)
        .toList()
      ..sort((a, b) => a.value.order.compareTo(b.value.order));
  }

  /// すべてチェック済みか確認
  bool _isAllChecked() {
    return _items.values.every((item) => item.isOk != null);
  }

  /// 良/否のカウント
  Map<String, int> _getCounts() {
    int okCount = 0;
    int ngCount = 0;

    for (var item in _items.values) {
      if (item.isOk == true) {
        okCount++;
      } else if (item.isOk == false) {
        ngCount++;
      }
    }

    return {'ok': okCount, 'ng': ngCount};
  }

  /// 点検完了処理
  Future<void> _submitInspection() async {
    if (!_isAllChecked()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべての項目をチェックしてください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final counts = _getCounts();
      final inspection = VehicleInspection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUser.employeeNumber,
        companyId: widget.currentUser.companyId,
        inspectionDate: DateTime.now(),
        items: _items,
        isCompleted: true,
        okCount: counts['ok']!,
        ngCount: counts['ng']!,
      );

      // データ保存（Web版ではローカルストレージ、モバイル版ではFirestore）
      await DatabaseService.saveVehicleInspection(inspection);

      if (!mounted) return;

      // 否項目がある場合は警告
      if (counts['ng']! > 0) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('点検完了'),
              ],
            ),
            content: Text(
              '点検が完了しました。\n\n'
              '否項目が ${counts['ng']} 件あります。\n'
              '管理者に報告し、速やかに整備を行ってください。',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('確認'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('点検が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 前の画面に戻る
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = _getCounts();
    final totalChecked = counts['ok']! + counts['ng']!;
    final progress = totalChecked / _items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('整備点検チェック表'),
        actions: [
          // 進捗表示
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$totalChecked/${_items.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // プログレスバー
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),

          // ヘッダー情報
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '運転者: ${widget.currentUser.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '点検日: ${DateFormat('yyyy年MM月dd日 HH:mm').format(DateTime.now())}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountChip('良', counts['ok']!, Colors.green),
                    _buildCountChip('否', counts['ng']!, Colors.red),
                    _buildCountChip('未', _items.length - totalChecked, Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          // 点検項目リスト
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection('運転者席'),
                  const SizedBox(height: 24),
                  _buildCategorySection('前部'),
                  const SizedBox(height: 24),
                  _buildCategorySection('後部'),
                  const SizedBox(height: 24),
                  _buildCategorySection('その他'),
                  const SizedBox(height: 80), // ボタン分のスペース
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAllChecked() ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isAllChecked() ? '点検完了' : 'すべての項目をチェックしてください',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final items = _getItemsByCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリヘッダー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 点検項目
        ...items.map((entry) => _buildInspectionItem(entry.key, entry.value)),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '運転者席':
        return Icons.airline_seat_recline_normal;
      case '前部':
        return Icons.directions_car;
      case '後部':
        return Icons.car_repair;
      case 'その他':
        return Icons.build;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildInspectionItem(String key, InspectionItem item) {
    final isChecked = item.isOk != null;
    final isNg = item.isOk == false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isChecked ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 項目名
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.detail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isChecked)
                  Icon(
                    item.isOk! ? Icons.check_circle : Icons.cancel,
                    color: item.isOk! ? Colors.green : Colors.red,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 良/否 ラジオボタン
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('良'),
                    value: true,
                    groupValue: item.isOk,
                    onChanged: (value) {
                      setState(() {
                        _items[key] = item.copyWith(isOk: value, note: null);
                        _noteControllers[key]?.clear();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('否'),
                    value: false,
                    groupValue: item.isOk,
                    onChanged: (value) {
                      setState(() {
                        _items[key] = item.copyWith(isOk: value);
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),

            // 備考欄（否の場合のみ表示）
            if (isNg) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _noteControllers[key],
                decoration: const InputDecoration(
                  labelText: '備考（詳細を入力してください）',
                  border: OutlineInputBorder(),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 2,
                onChanged: (value) {
                  setState(() {
                    _items[key] = item.copyWith(note: value);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
