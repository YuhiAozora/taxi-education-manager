import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/user.dart';
import '../models/ai_conversation.dart';
import '../models/education_item.dart';
import '../models/medical_checkup.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';

// パーソナルAI画面
class PersonalAiScreen extends StatefulWidget {
  final User user;

  const PersonalAiScreen({super.key, required this.user});

  @override
  State<PersonalAiScreen> createState() => _PersonalAiScreenState();
}

class _PersonalAiScreenState extends State<PersonalAiScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiConversation> _conversations = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 会話履歴の読み込み
  Future<void> _loadConversationHistory() async {
    setState(() => _isLoading = true);

    try {
      // Web版: localStorageから読み込み（プライバシー保護）
      if (kIsWeb) {
        final storageKey = 'ai_conversations_${widget.user.employeeNumber}';
        final jsonString = html.window.localStorage[storageKey];
        
        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          final history = jsonList
              .map((json) => AiConversation.fromJson(json, json['id']))
              .toList();
          
          setState(() {
            _conversations.clear();
            _conversations.addAll(history);
          });
          
          if (kDebugMode) {
            print('✅ 会話履歴を読み込みました: ${history.length}件');
          }
        }
        
        setState(() => _isLoading = false);
        return;
      }

      // モバイル版: Firestoreから会話履歴を取得（暗号化済み）
      // TODO: 本番実装時に追加
      // final history = await DatabaseService.getEncryptedAiConversations(widget.user.id);
      // setState(() {
      //   _conversations.clear();
      //   _conversations.addAll(history);
      // });
    } catch (e) {
      if (kDebugMode) {
        print('❌ 会話履歴の読み込みエラー: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ユーザーコンテキストの構築
  Future<UserContext> _buildUserContext() async {
    try {
      // 教育項目の取得
      final educationItems = await DatabaseService.getAllEducationItems();
      
      // 完了した教育項目数を取得（LearningRecordから）
      final completedCount = await DatabaseService.getCompletedItemsCount(
          widget.user.employeeNumber);

      // 健康診断の取得
      final checkups = await DatabaseService.getMedicalCheckupsByUser(
          widget.user.employeeNumber);
      final hasCompletedCheckup = checkups.isNotEmpty;
      final lastCheckupDate =
          checkups.isNotEmpty ? checkups.first.checkupDate : null;

      // 経験年数の推定（簡易実装: デフォルト5年）
      const int experienceYears = 5;

      return UserContext(
        name: widget.user.name,
        completedEducationCount: completedCount,
        totalEducationCount: educationItems.length,
        learningProgressRate: educationItems.isEmpty
            ? 0.0
            : (completedCount / educationItems.length) * 100,
        hasCompletedCheckup: hasCompletedCheckup,
        lastCheckupDate: lastCheckupDate,
        experienceYears: experienceYears,
        lastLoginDate: DateTime.now(), // 簡易実装
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ユーザーコンテキスト構築エラー: $e');
      }
      // エラー時はデフォルト値
      return UserContext(
        name: widget.user.name,
        completedEducationCount: 0,
        totalEducationCount: 0,
        learningProgressRate: 0.0,
        hasCompletedCheckup: false,
        experienceYears: 5,
        lastLoginDate: DateTime.now(),
      );
    }
  }

  // メッセージ送信
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    try {
      // ユーザーコンテキストの構築
      final userContext = await _buildUserContext();

      // AI回答の生成
      final aiResponse = await GeminiService.generatePersonalizedResponse(
        userMessage: message,
        userContext: userContext,
        conversationHistory: _conversations,
      );

      // カテゴリの自動判定
      final category = GeminiService.detectCategory(message);

      // 会話履歴に追加
      final conversation = AiConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.user.employeeNumber,
        companyId: widget.user.companyId ?? 'default',
        userMessage: message,
        aiResponse: aiResponse,
        timestamp: DateTime.now(),
        category: category,
      );

      setState(() {
        _conversations.insert(0, conversation);
      });

      // Web版: localStorageに保存（プライバシー保護）
      if (kIsWeb) {
        _saveToLocalStorage();
      }
      // モバイル版: 暗号化してFirestoreに保存（本番実装時）
      // else {
      //   await DatabaseService.saveEncryptedAiConversation(conversation);
      // }

      // 自動スクロール
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ メッセージ送信エラー: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メッセージの送信に失敗しました')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Web版: localStorageに保存（プライバシー保護）
  void _saveToLocalStorage() {
    if (!kIsWeb) return;
    
    try {
      final storageKey = 'ai_conversations_${widget.user.employeeNumber}';
      final jsonList = _conversations.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      html.window.localStorage[storageKey] = jsonString;
      
      if (kDebugMode) {
        print('✅ 会話履歴を保存しました: ${_conversations.length}件');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 会話履歴の保存エラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 パーソナルAIサポート'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー情報
            _buildHeader(),

            // 会話エリア
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationList(),
            ),

            // 入力エリア
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ヘッダー情報
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.teal.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'こんにちは、${widget.user.name}さん 👋',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '事故防止とメンタルケアのサポートをします。\nどんな小さなことでもお気軽にご相談ください。',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 空の状態
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 80, color: Colors.teal.shade300),
            const SizedBox(height: 24),
            const Text(
              '何でも聞いてください',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '例えば...\n・雨の日の運転で気をつけることは？\n・最近疲れが取れない...\n・教育項目の進め方を教えて',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // 会話リスト
  Widget _buildConversationList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return Column(
          children: [
            _buildUserMessage(conversation),
            const SizedBox(height: 8),
            _buildAiMessage(conversation),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ユーザーメッセージ
  Widget _buildUserMessage(AiConversation conversation) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              conversation.userMessage,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${conversation.timestamp.hour}:${conversation.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // AIメッセージ
  Widget _buildAiMessage(AiConversation conversation) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🤖 ', style: TextStyle(fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(conversation.category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    conversation.category,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              conversation.aiResponse,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${conversation.timestamp.hour}:${conversation.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // カテゴリ色
  Color _getCategoryColor(String category) {
    switch (category) {
      case '事故防止':
        return Colors.orange;
      case 'メンタルケア':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 入力エリア
  Widget _buildInputArea() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
