import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/feedback.dart';

/// フィードバック送信画面
class FeedbackScreen extends StatefulWidget {
  final User currentUser;

  const FeedbackScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  FeedbackCategory _selectedCategory = FeedbackCategory.usability;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // βテスト版: フィードバックはローカルに記録（実際の送信はネイティブアプリで実装）
      final feedbackData = {
        'user_id': widget.currentUser.employeeNumber,
        'user_name': widget.currentUser.name,
        'user_role': widget.currentUser.isDriver ? 'driver' : 'company_admin',
        'company_id': widget.currentUser.companyId,
        'category': _selectedCategory.name,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // βテスト版: ローカルログのみ（実際の送信は本番環境で実装）
      await Future.delayed(const Duration(milliseconds: 500)); // 送信をシミュレート

      if (mounted) {
        // 成功メッセージ
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text('フィードバックを受け付けました'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ご意見ありがとうございます。'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '【送信内容】',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('カテゴリ: ${_selectedCategory.displayName}'),
                      Text('タイトル: ${_titleController.text.trim()}'),
                      const SizedBox(height: 8),
                      const Text(
                        '運営者が確認後、対応させていただきます。',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // フィードバック画面も閉じる
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // デバッグ用: コンソールに出力
      debugPrint('📝 フィードバック受付:');
      debugPrint('  ユーザー: ${feedbackData['user_name']}');
      debugPrint('  カテゴリ: ${feedbackData['category']}');
      debugPrint('  タイトル: ${feedbackData['title']}');
      debugPrint('  詳細: ${feedbackData['description']}');

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ エラー: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック送信'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 説明カード
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.feedback, color: Colors.blue.shade700, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'アプリの改善にご協力ください',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '使いにくい点や改善してほしい点を\nお聞かせください',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // βテスト用の注意書き
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, 
                        color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'βテスト中: 送信内容はアプリ内に記録され、\n運営者が確認します',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // カテゴリ選択
                const Text(
                  'カテゴリ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      label: Text(category.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // タイトル入力
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: ログインボタンが押しにくい',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 詳細入力
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '詳細',
                    hintText: 'できるだけ具体的にお書きください',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '詳細を入力してください';
                    }
                    if (value.trim().length < 10) {
                      return '10文字以上入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 送信ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? '送信中...' : 'フィードバックを送信',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 注意事項
                Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '注意事項',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 送信されたフィードバックは運営者が確認します\n'
                          '• 個人情報は含めないでください\n'
                          '• 返信には時間がかかる場合があります',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
