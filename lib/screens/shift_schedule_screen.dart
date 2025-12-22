import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'leave_request_screen.dart';

/// 出番表（シフト表）画面
class ShiftScheduleScreen extends StatefulWidget {
  final User currentUser;

  const ShiftScheduleScreen({super.key, required this.currentUser});

  @override
  State<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends State<ShiftScheduleScreen> {
  DateTime _selectedMonth = DateTime.now();

  // ダミーのシフトデータ
  Map<DateTime, ShiftType> _generateDemoShifts() {
    final shifts = <DateTime, ShiftType>{};
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      // パターン: 2日勤務 → 1日休み
      final dayOfMonth = date.day;
      if (dayOfMonth % 3 == 0) {
        shifts[date] = ShiftType.dayOff;
      } else if (dayOfMonth % 7 == 0) {
        shifts[date] = ShiftType.nightShift;
      } else {
        shifts[date] = ShiftType.dayShift;
      }
    }

    return shifts;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shifts = _generateDemoShifts();
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // 統計計算
    int workDays = 0;
    int dayShifts = 0;
    int nightShifts = 0;
    int dayOffs = 0;

    shifts.forEach((date, type) {
      switch (type) {
        case ShiftType.dayShift:
          workDays++;
          dayShifts++;
          break;
        case ShiftType.nightShift:
          workDays++;
          nightShifts++;
          break;
        case ShiftType.dayOff:
          dayOffs++;
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('出番表'),
      ),
      body: Column(
        children: [
          // 月選択ヘッダー
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('yyyy年MM月').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // 統計情報
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('出勤', workDays, Colors.blue),
                _buildStatChip('日勤', dayShifts, Colors.green),
                _buildStatChip('夜勤', nightShifts, Colors.orange),
                _buildStatChip('休日', dayOffs, Colors.red),
              ],
            ),
          ),

          const Divider(),

          // シフト一覧
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: endDate.day,
              itemBuilder: (context, index) {
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, index + 1);
                final shift = shifts[date] ?? ShiftType.dayOff;
                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return _buildShiftCard(date, shift, isToday);
              },
            ),
          ),
          
          // 休暇申請ボタン
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeaveRequestScreen(currentUser: widget.currentUser),
                  ),
                );
              },
              icon: const Icon(Icons.event_note),
              label: const Text('休暇申請'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count日',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(DateTime date, ShiftType type, bool isToday) {
    final weekdayName = ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
    final color = _getShiftColor(type);
    final icon = _getShiftIcon(type);
    final label = _getShiftLabel(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isToday ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                weekdayName,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '今日',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(_getShiftTime(type)),
      ),
    );
  }

  Color _getShiftColor(ShiftType type) {
    switch (type) {
      case ShiftType.dayShift:
        return Colors.green;
      case ShiftType.nightShift:
        return Colors.orange;
      case ShiftType.dayOff:
        return Colors.red;
    }
  }

  IconData _getShiftIcon(ShiftType type) {
    switch (type) {
      case ShiftType.dayShift:
        return Icons.wb_sunny;
      case ShiftType.nightShift:
        return Icons.nights_stay;
      case ShiftType.dayOff:
        return Icons.event_busy;
    }
  }

  String _getShiftLabel(ShiftType type) {
    switch (type) {
      case ShiftType.dayShift:
        return '日勤';
      case ShiftType.nightShift:
        return '夜勤';
      case ShiftType.dayOff:
        return '休日';
    }
  }

  String _getShiftTime(ShiftType type) {
    switch (type) {
      case ShiftType.dayShift:
        return '08:00 - 17:00';
      case ShiftType.nightShift:
        return '22:00 - 翌07:00';
      case ShiftType.dayOff:
        return '-';
    }
  }
}

enum ShiftType {
  dayShift,
  nightShift,
  dayOff,
}
