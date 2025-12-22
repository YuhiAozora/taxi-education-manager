import 'package:flutter/material.dart';
import '../models/faq.dart';

/// チャットボット画面
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // 最初の挨拶メッセージ
    _addBotMessage(
      'こんにちは！タクシー教育管理システムのサポートボットです。🤖\n\n'
      'どのようなことでお困りですか？\n\n'
      '例：「教育項目はどこで確認できますか？」\n'
      '「健康診断の期限を知りたい」など'
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ユーザーメッセージを追加
  void _addUserMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ));
    });

    _scrollToBottom();
    _handleUserInput(text);
  }

  /// ボットメッセージを追加
  void _addBotMessage(String text, {String? relatedFaqId}) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: false,
        relatedFaqId: relatedFaqId,
      ));
    });

    _scrollToBottom();
  }

  /// ユーザー入力を処理
  void _handleUserInput(String input) {
    setState(() {
      _isTyping = true;
    });

    // 少し遅延を入れてボットが考えている感じを出す
    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _searchFAQ(input);

      setState(() {
        _isTyping = false;
      });

      if (response != null) {
        _addBotMessage(response.answer, relatedFaqId: response.id);
      } else {
        _addBotMessage(
          '申し訳ございません。その質問に対する回答が見つかりませんでした。😔\n\n'
          '以下のような質問をお試しください：\n'
          '• 教育項目の確認方法\n'
          '• 健康診断の種類\n'
          '• ログアウト方法\n\n'
          'または、管理者にお問い合わせください。'
        );
      }
    });
  }

  /// FAQ検索エンジン
  FAQ? _searchFAQ(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    // キーワードマッチング
    FAQ? bestMatch;
    int bestScore = 0;

    for (final faq in FAQData.defaultFAQs) {
      int score = 0;

      // 質問文に完全一致
      if (faq.question.toLowerCase().contains(normalizedQuery)) {
        score += 100;
      }

      // キーワードマッチング
      for (final keyword in faq.keywords) {
        if (normalizedQuery.contains(keyword.toLowerCase())) {
          score += 10 + faq.priority;
        }
      }

      // カテゴリマッチング
      if (normalizedQuery.contains(faq.category)) {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    // スコアが一定以上なら返す
    return bestScore >= 10 ? bestMatch : null;
  }

  /// 一番下までスクロール
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ・サポート'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog();
            },
            tooltip: 'このボットについて',
          ),
        ],
      ),
      body: Column(
        children: [
          // よくある質問ショートカット
          _buildQuickAccessBar(),

          // メッセージリスト
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 入力欄
          _buildInputArea(),
        ],
      ),
    );
  }

  /// よくある質問ショートカットバー
  Widget _buildQuickAccessBar() {
    final categories = ['教育', '健康診断', 'システム'];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final faq = FAQData.defaultFAQs.firstWhere(
            (f) => f.category == category,
            orElse: () => FAQData.defaultFAQs.first,
          );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Text(
                faq.categoryIcon,
                style: const TextStyle(fontSize: 18),
              ),
              label: Text(category),
              onPressed: () {
                _showCategoryQuestions(category);
              },
            ),
          );
        },
      ),
    );
  }

  /// メッセージバブル
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[500] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  /// 入力中インジケーター
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('考え中...', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 入力エリア
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '質問を入力してください...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (text) {
                    _addUserMessage(text);
                    _textController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  _addUserMessage(_textController.text);
                  _textController.clear();
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// カテゴリ別の質問を表示
  void _showCategoryQuestions(String category) {
    final faqs = FAQData.defaultFAQs
        .where((faq) => faq.category == category)
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '$category のよくある質問',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return ListTile(
                      leading: Text(
                        faq.categoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(faq.question),
                      onTap: () {
                        Navigator.pop(context);
                        _addUserMessage(faq.question);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// このボットについてダイアログ
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ヘルプボットについて'),
          content: const Text(
            'このボットは、タクシー教育管理システムの使い方や'
            'よくある質問に自動で回答します。\n\n'
            'キーワードで検索して、関連する回答を表示します。\n\n'
            '回答が見つからない場合は、管理者にお問い合わせください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}
