import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/learning_record.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  List<LearningRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    final currentUser = DatabaseService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _records = DatabaseService.getLearningRecordsByUser(currentUser.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習履歴'),
      ),
      body: SafeArea(
        child: _records.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '学習履歴がありません',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '教育コンテンツを学習すると\nここに履歴が表示されます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  record.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '完了',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            record.educationTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.timer,
                                '${record.durationMinutes}分',
                              ),
                              const SizedBox(width: 8),
                              if (record.quizScore != null && record.totalQuestions != null)
                                _buildInfoChip(
                                  Icons.emoji_events,
                                  '${record.quizScore}/${record.totalQuestions}問正解',
                                  color: _getScoreColor(record),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(LearningRecord record) {
    if (record.quizScore == null || record.totalQuestions == null) {
      return Colors.grey;
    }
    final percentage = record.quizScore! / record.totalQuestions!;
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.blue;
    return Colors.orange;
  }
}
