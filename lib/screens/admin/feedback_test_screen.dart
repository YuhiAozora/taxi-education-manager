import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// フィードバック機能テスト画面（デバッグ用）
class FeedbackTestScreen extends StatefulWidget {
  const FeedbackTestScreen({super.key});

  @override
  State<FeedbackTestScreen> createState() => _FeedbackTestScreenState();
}

class _FeedbackTestScreenState extends State<FeedbackTestScreen> {
  String _status = '初期化中...';
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _testFirestoreConnection();
  }

  Future<void> _testFirestoreConnection() async {
    setState(() {
      _status = 'Firestore接続テスト開始...';
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Firestore接続テスト開始');

      // Step 1: Firestoreインスタンス取得
      setState(() {
        _status = 'Step 1: Firestoreインスタンス取得中...';
      });
      final firestore = FirebaseFirestore.instance;
      debugPrint('✅ Firestoreインスタンス取得成功');

      // Step 2: コレクションへのアクセス
      setState(() {
        _status = 'Step 2: feedbacksコレクションにアクセス中...';
      });
      final collection = firestore.collection('feedbacks');
      debugPrint('✅ feedbacksコレクション取得成功');

      // Step 3: データ取得
      setState(() {
        _status = 'Step 3: データ取得中...';
      });
      final snapshot = await collection.get();
      debugPrint('✅ データ取得成功: ${snapshot.docs.length}件');

      // Step 4: データ解析
      setState(() {
        _status = 'Step 4: データ解析中...';
      });
      final feedbacks = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'タイトルなし',
          'status': data['status'] ?? 'unknown',
          'user_name': data['user_name'] ?? '不明',
        };
      }).toList();
      debugPrint('✅ データ解析成功: ${feedbacks.length}件');

      setState(() {
        _feedbacks = feedbacks;
        _status = '✅ テスト完了！${feedbacks.length}件のフィードバックを取得';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ エラー発生: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _status = '❌ エラー発生';
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore接続テスト'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ステータス表示
              Card(
                color: _isLoading
                    ? Colors.blue.shade50
                    : _errorMessage != null
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_errorMessage != null)
                            Icon(Icons.error, color: Colors.red.shade700)
                          else
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isLoading
                                    ? Colors.blue.shade900
                                    : _errorMessage != null
                                        ? Colors.red.shade900
                                        : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'エラー詳細:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 再試行ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testFirestoreConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // データ一覧
              if (_feedbacks.isNotEmpty) ...[
                Text(
                  'フィードバックデータ (${_feedbacks.length}件)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._feedbacks.map((feedback) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: Icon(Icons.feedback,
                            color: Colors.purple.shade700, size: 20),
                      ),
                      title: Text(
                        feedback['title'] ?? 'タイトルなし',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${feedback['user_name']} - ${feedback['status']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        'ID: ${feedback['id'].toString().substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
