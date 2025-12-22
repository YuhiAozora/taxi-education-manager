import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/feedback.dart';

/// スーパー管理者向け - フィードバック管理画面
class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  FeedbackStatus? _filterStatus;
  FeedbackCategory? _filterCategory;

  /// βテスト用: サンプルフィードバックデータを生成
  List<AppFeedback> _generateSampleFeedbacks() {
    final now = DateTime.now();
    var feedbacks = [
      AppFeedback(
        id: 'sample_1',
        userId: 'D101',
        userName: '金子一也',
        userRole: 'driver',
        companyId: 'beta_company',
        category: FeedbackCategory.feature,
        title: '学習コンテンツの動画再生機能',
        description: '学習コンテンツに動画を追加してほしいです。文字だけだと理解しづらい内容もあるので、動画での解説があると助かります。',
        status: FeedbackStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppFeedback(
        id: 'sample_2',
        userId: 'D102',
        userName: '大谷理一',
        userRole: 'driver',
        companyId: 'beta_company',
        category: FeedbackCategory.bug,
        title: '健康診断の日付が正しく表示されない',
        description: '健康診断画面で次回診断日が正しく表示されないことがあります。何度か画面を開き直すと正しく表示されます。',
        status: FeedbackStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      AppFeedback(
        id: 'sample_3',
        userId: 'D103',
        userName: '森下久美子',
        userRole: 'driver',
        companyId: 'beta_company',
        category: FeedbackCategory.feature,
        title: 'シフト表のカレンダー表示',
        description: 'シフト表を月単位のカレンダー形式で見られるようにしてほしいです。今のリスト表示だと見づらいです。',
        status: FeedbackStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppFeedback(
        id: 'sample_4',
        userId: 'M101',
        userName: '諸星健二',
        userRole: 'company_admin',
        companyId: 'beta_company',
        category: FeedbackCategory.improvement,
        title: '教育台帳のエクスポート機能',
        description: '教育台帳をExcel形式でもエクスポートできるようにしてほしいです。PDF以外の形式があると便利です。',
        status: FeedbackStatus.resolved,
        createdAt: now.subtract(const Duration(days: 7)),
        resolvedAt: now.subtract(const Duration(hours: 12)),
      ),
      AppFeedback(
        id: 'sample_5',
        userId: 'M102',
        userName: '鈴木雅之',
        userRole: 'company_admin',
        companyId: 'beta_company',
        category: FeedbackCategory.feature,
        title: '健康診断の一括登録機能',
        description: '複数の従業員の健康診断結果を一括で登録できる機能がほしいです。一人ずつ入力するのは時間がかかります。',
        status: FeedbackStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      AppFeedback(
        id: 'sample_6',
        userId: 'D104',
        userName: '石塚裕美子',
        userRole: 'driver',
        companyId: 'beta_company',
        category: FeedbackCategory.other,
        title: 'アプリの使い方が分かりやすい',
        description: 'アプリの使い方がとても分かりやすく、初めてでもスムーズに使えました。ありがとうございます。',
        status: FeedbackStatus.closed,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    // フィルター適用
    if (_filterStatus != null) {
      feedbacks = feedbacks.where((f) => f.status == _filterStatus).toList();
    }
    if (_filterCategory != null) {
      feedbacks = feedbacks.where((f) => f.category == _filterCategory).toList();
    }

    return feedbacks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック管理'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          // フィルター選択
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'フィルター',
            onSelected: (value) {
              setState(() {
                if (value.startsWith('status_')) {
                  final statusName = value.substring(7);
                  _filterStatus = statusName == 'all' 
                      ? null 
                      : FeedbackStatus.values.firstWhere((e) => e.name == statusName);
                } else if (value.startsWith('category_')) {
                  final categoryName = value.substring(9);
                  _filterCategory = categoryName == 'all'
                      ? null
                      : FeedbackCategory.values.firstWhere((e) => e.name == categoryName);
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                enabled: false,
                child: Text('ステータスでフィルター', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'status_all',
                child: Text('すべて'),
              ),
              ...FeedbackStatus.values.map((status) => PopupMenuItem(
                value: 'status_${status.name}',
                child: Text(status.displayName),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'category',
                enabled: false,
                child: Text('カテゴリでフィルター',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'category_all',
                child: Text('すべて'),
              ),
              ...FeedbackCategory.values.map((category) => PopupMenuItem(
                value: 'category_${category.name}',
                child: Text(category.displayName),
              )),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // βテスト用: サンプルデータを表示
            final feedbacks = _generateSampleFeedbacks();

            // データが0件の場合
            if (feedbacks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('フィードバックがありません',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      )),
                    const SizedBox(height: 8),
                    Text('運転手または管理者からのフィードバックがまだありません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      )),
                  ],
                ),
              );
            }

            // 統計情報
            final totalCount = feedbacks.length;
            final pendingCount = feedbacks.where((f) => f.status == FeedbackStatus.pending).length;
            final inProgressCount = feedbacks.where((f) => f.status == FeedbackStatus.inProgress).length;

            return Column(
              children: [
                // 統計サマリー
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('全体', totalCount, Colors.blue),
                      _buildStatCard('未対応', pendingCount, Colors.orange),
                      _buildStatCard('対応中', inProgressCount, Colors.purple),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // フィルター表示
                if (_filterStatus != null || _filterCategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 8),
                        const Text('フィルター: '),
                        if (_filterStatus != null) ...[
                          Chip(
                            label: Text(_filterStatus!.displayName),
                            onDeleted: () {
                              setState(() {
                                _filterStatus = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_filterCategory != null)
                          Chip(
                            label: Text(_filterCategory!.displayName),
                            onDeleted: () {
                              setState(() {
                                _filterCategory = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                // フィードバックリスト
                Expanded(
                  child: feedbacks.isEmpty
                      ? Center(
                          child: Text(
                            'フィルター条件に一致するフィードバックがありません',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];
                            return _buildFeedbackCard(feedback);
                          },
                        ),
                ),
              ],
            );
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
          Icon(Icons.feedback_outlined, 
            size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'フィードバックはまだありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(AppFeedback feedback) {
    Color statusColor;
    IconData statusIcon;
    
    switch (feedback.status) {
      case FeedbackStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case FeedbackStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.work;
        break;
      case FeedbackStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case FeedbackStatus.closed:
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFeedbackDetail(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  // カテゴリアイコン
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.category, color: Colors.blue.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // タイトル
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ステータスバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          feedback.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 詳細
              Text(
                feedback.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              // フッター
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${feedback.userName} (${feedback.userRole == 'driver' ? '乗務員' : '管理者'})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(feedback.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  void _showFeedbackDetail(AppFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.feedback, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('フィードバック詳細'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('カテゴリ', feedback.category.displayName),
              _buildDetailRow('ステータス', feedback.status.displayName),
              _buildDetailRow('送信者', feedback.userName),
              _buildDetailRow('役割', feedback.userRole == 'driver' ? '乗務員' : '管理者'),
              _buildDetailRow('送信日時', '${feedback.createdAt.year}/${feedback.createdAt.month}/${feedback.createdAt.day} ${feedback.createdAt.hour}:${feedback.createdAt.minute.toString().padLeft(2, '0')}'),
              const Divider(height: 24),
              const Text(
                'タイトル',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(feedback.title),
              const SizedBox(height: 16),
              const Text(
                '詳細',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(feedback.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(feedback);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('ステータス変更'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(AppFeedback feedback) async {
    final newStatus = await showDialog<FeedbackStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ステータスを変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FeedbackStatus.values.map((status) {
            return ListTile(
              title: Text(status.displayName),
              leading: Radio<FeedbackStatus>(
                value: status,
                groupValue: feedback.status,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              onTap: () {
                Navigator.pop(context, status);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != feedback.status) {
      // βテスト版: ステータス変更はサンプルデータのため実際には反映されない
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ステータスを「${newStatus.displayName}」に変更しました（βテスト版）'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 画面を更新
        setState(() {});
      }
    }
  }
}
