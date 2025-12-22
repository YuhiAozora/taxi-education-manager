import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/ai_conversation.dart';

// Gemini AI サービス
class GeminiService {
  // ⚠️ 本番環境では環境変数またはFirebase Functionsで管理してください
  // 現在は開発用のダミー実装です
  static const String _apiKey = 'AIzaSyCmXjU5PRhjSCbY7HHafpl5dL_TVR7h4l0';
  // Gemini 1.5 Pro を試す（最新バージョン）
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';

  // パーソナライズされたAI回答を生成
  static Future<String> generatePersonalizedResponse({
    required String userMessage,
    required UserContext userContext,
    List<AiConversation>? conversationHistory,
  }) async {
    try {
      // システムプロンプト（AIの役割定義）
      final systemPrompt = _buildSystemPrompt(userContext);

      // 会話履歴の構築
      final conversationContext = _buildConversationHistory(conversationHistory);

      // 完全なプロンプトの構築
      final fullPrompt = '''
あなたはタクシー運転者専門のAIサポートアシスタントです。

【運転者情報】
名前: ${userContext.name}
学習進捗: ${userContext.completedEducationCount}/${userContext.totalEducationCount}項目完了（${userContext.learningProgressRate.toStringAsFixed(0)}%）
健康診断: ${userContext.hasCompletedCheckup ? '受診済み' : '未受診'}

【質問】
$userMessage

【回答ルール】
1. 必ず${userContext.name}さんの質問に直接答えてください
2. 親しみやすく、具体的なアドバイスを提供してください
3. 事故防止やメンタルケアの観点から回答してください
4. 200-400文字程度で簡潔にまとめてください
5. 励ましの言葉を含めてください

上記の質問に対して、今すぐ具体的な回答をしてください。
''';

      if (kDebugMode) {
        print('🤖 Gemini API呼び出し開始');
        print('プロンプト:\n$fullPrompt');
      }

      // Web版の場合はダミー回答を返す（開発用）
      if (kIsWeb && _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _generateDummyResponse(userMessage, userContext);
      }

      // Gemini API呼び出し（v1エンドポイント）
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 800,
            'topP': 0.95,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        if (kDebugMode) {
          print('✅ AI回答生成成功');
        }

        return aiResponse;
      } else {
        if (kDebugMode) {
          print('❌ API Error: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        // Web版ではエラーの詳細を含むダミー回答を返す
        if (kIsWeb) {
          return '''
${userContext.name}さん、申し訳ございません。

現在、AI機能で技術的な問題が発生しています。
エラーコード: ${response.statusCode}

一時的にダミー回答モードで動作しています。
${_generateDummyResponse(userMessage, userContext)}

【開発者向け情報】
ブラウザのコンソール（F12）でエラー詳細を確認してください。
''';
        }
        throw Exception('AI回答の生成に失敗しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemini Service Error: $e');
      }
      // Web版ではエラー情報を含むダミー回答を返す
      if (kIsWeb) {
        return '''
${userContext.name}さん、申し訳ございません。

AI接続でエラーが発生しました。
エラー内容: $e

一時的にダミー回答モードで動作しています。
${_generateDummyResponse(userMessage, userContext)}

【開発者向け情報】
・APIキーが正しく設定されているか確認してください
・Gemini APIの利用制限を確認してください
・ブラウザのコンソール（F12）でエラー詳細を確認してください
''';
      }
      // エラー時はダミー回答を返す
      return _generateDummyResponse(userMessage, userContext);
    }
  }

  // システムプロンプトの構築
  static String _buildSystemPrompt(UserContext userContext) {
    return '''
あなたはタクシー運転者の安全運転とメンタルケアをサポートする専門AIアシスタントです。

【あなたの役割】
1. 事故防止のための具体的なアドバイス
2. 運転者の心身の健康をサポート
3. 励ましと共感を持った対応
4. 実践しやすい具体的な提案

${userContext.toPromptContext()}

【重要な注意事項】
・個人情報は厳重に扱ってください
・医療行為に該当するアドバイスは避けてください
・深刻な問題の場合は管理者への相談を勧めてください
・常に前向きで建設的な回答を心がけてください
''';
  }

  // 会話履歴の構築
  static String _buildConversationHistory(
      List<AiConversation>? conversationHistory) {
    if (conversationHistory == null || conversationHistory.isEmpty) {
      return '【会話履歴】\nこれが最初の会話です。';
    }

    final buffer = StringBuffer();
    buffer.writeln('【最近の会話履歴】');

    // 直近3件の会話を含める
    final recentConversations = conversationHistory.take(3);
    for (final conversation in recentConversations) {
      final date = conversation.timestamp;
      buffer.writeln(
          '\n${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
      buffer.writeln('運転者: ${conversation.userMessage}');
      buffer.writeln('AI: ${conversation.aiResponse}');
    }

    return buffer.toString();
  }

  // ダミー回答生成（開発用・APIキー未設定時）
  static String _generateDummyResponse(
      String userMessage, UserContext userContext) {
    final name = userContext.name;

    // キーワードベースの簡易回答
    if (userMessage.contains('雨') || userMessage.contains('天気')) {
      return '''
${name}さん、お疲れ様です。雨の日の運転ですね。

【今日のアドバイス】
1. 🚗 車間距離を普段の1.5倍に保ちましょう
2. 💡 早めのライト点灯で視認性を確保してください
3. ⚠️ 路面が滑りやすいので、急ブレーキは避けましょう

あなたの学習進捗は${userContext.learningProgressRate.toStringAsFixed(0)}%です。
「雨天時の運転」教育項目で詳しく学べますよ。

安全運転で頑張ってください！💪
''';
    } else if (userMessage.contains('疲れ') ||
        userMessage.contains('眠い') ||
        userMessage.contains('つらい')) {
      return '''
${name}さん、お疲れのようですね。無理は禁物ですよ。

【メンタルケアのアドバイス】
1. 😴 十分な睡眠時間を確保していますか？（最低7時間）
2. ☕ こまめな休憩を取りましょう（2時間に1回15分）
3. 🚶 軽いストレッチで体をほぐしてください

${userContext.hasCompletedCheckup ? '健康診断は受診済みですね。' : '健康診断の予約もお忘れなく。'}

深刻な疲労の場合は、管理者に相談することも大切です。
あなたの安全が最優先ですからね。

お大事にしてください🙏
''';
    } else if (userMessage.contains('教育') || userMessage.contains('学習')) {
      return '''
${name}さん、学習について気になることがあるんですね。

【現在の状況】
・完了済み: ${userContext.completedEducationCount}/${userContext.totalEducationCount}項目
・進捗率: ${userContext.learningProgressRate.toStringAsFixed(0)}%

${userContext.learningProgressRate >= 60 ? '順調に進んでいますね！素晴らしいです👏' : 'マイペースで大丈夫ですよ。焦らず進めましょう。'}

【おすすめ】
ホーム画面から「教育コンテンツ」を選んで、
興味のある項目から始めてみてください。

何か分からないことがあれば、いつでも聞いてくださいね！
''';
    } else {
      return '''
${name}さん、ご質問ありがとうございます。

【あなたの状況】
・学習進捗: ${userContext.completedEducationCount}/${userContext.totalEducationCount}項目完了
・健康診断: ${userContext.hasCompletedCheckup ? '受診済み✅' : '要受診📋'}

具体的にどんなことでお困りですか？
例えば...
・安全運転のコツを知りたい
・疲れやストレスについて相談したい
・教育項目の進め方を聞きたい

どんな小さなことでも大丈夫です。
一緒に考えましょう！😊
''';
    }
  }

  // カテゴリ自動判定
  static String detectCategory(String userMessage) {
    if (userMessage.contains('事故') ||
        userMessage.contains('安全') ||
        userMessage.contains('運転') ||
        userMessage.contains('雨') ||
        userMessage.contains('天気')) {
      return '事故防止';
    } else if (userMessage.contains('疲れ') ||
        userMessage.contains('眠い') ||
        userMessage.contains('ストレス') ||
        userMessage.contains('不安') ||
        userMessage.contains('つらい')) {
      return 'メンタルケア';
    } else {
      return 'その他';
    }
  }
}
