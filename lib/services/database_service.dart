import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/education_item.dart';
import '../models/learning_record.dart';
import '../models/medical_checkup.dart';

class DatabaseService {
  static const String _usersBox = 'users';
  static const String _educationItemsBox = 'education_items';
  static const String _learningRecordsBox = 'learning_records';
  static const String _currentUserBox = 'current_user';
  static const String _medicalCheckupsBox = 'medical_checkups';

  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('🔧 Initializing Hive...');
    }
    
    await Hive.initFlutter();
    
    if (kDebugMode) {
      debugPrint('✅ Hive initialized');
      debugPrint('📦 Opening boxes...');
    }

    // Open boxes
    await Hive.openBox(_usersBox);
    await Hive.openBox(_educationItemsBox);
    await Hive.openBox(_learningRecordsBox);
    await Hive.openBox(_currentUserBox);
    await Hive.openBox(_medicalCheckupsBox);

    if (kDebugMode) {
      debugPrint('✅ All boxes opened');
      debugPrint('📊 Users box size: ${Hive.box(_usersBox).length}');
    }

    // Force re-initialize to fix password issue
    // Delete old data and create new
    await Hive.box(_usersBox).clear();
    await Hive.box(_educationItemsBox).clear();
    await Hive.box(_learningRecordsBox).clear();
    await Hive.box(_medicalCheckupsBox).clear();
    
    if (kDebugMode) {
      debugPrint('🔄 Cleared all boxes, initializing fresh data...');
    }
    
    await _initializeSampleData();
    
    if (kDebugMode) {
      debugPrint('✅ Sample data initialized with passwords');
    }
  }

  static Future<void> _initializeSampleData() async {
    if (kDebugMode) {
      debugPrint('📚 Initializing sample data...');
    }

    // Create admin user
    final adminUser = User(
      id: 'admin001',
      name: '管理者',
      employeeNumber: 'ADMIN',
      password: 'admin123',
      isAdmin: true,
      createdAt: DateTime.now(),
    );
    await saveUser(adminUser);

    // Create sample driver users
    final driver1 = User(
      id: 'driver001',
      name: '山田太郎',
      employeeNumber: 'D001',
      password: 'pass123',
      isAdmin: false,
      createdAt: DateTime.now(),
    );
    final driver2 = User(
      id: 'driver002',
      name: '佐藤花子',
      employeeNumber: 'D002',
      password: 'pass123',
      isAdmin: false,
      createdAt: DateTime.now(),
    );
    await saveUser(driver1);
    await saveUser(driver2);

    // Initialize education items based on 国交省マニュアル
    await _initializeEducationItems();
    
    // Initialize sample medical checkup data for demo
    await _initializeSampleMedicalCheckups();

    if (kDebugMode) {
      debugPrint('✅ Sample data initialized');
    }
  }
  
  static Future<void> _initializeSampleMedicalCheckups() async {
    final now = DateTime.now();
    
    // Driver1 (D001 - 山田太郎) のサンプル診断データ
    // 1. 期限切れの適齢診断
    final checkup1 = MedicalCheckup(
      id: 'checkup001',
      userId: 'driver001',
      type: MedicalCheckupType.tekireishindan,
      checkupDate: DateTime(now.year - 3, now.month, now.day - 10),
      institution: '東京適性診断センター',
      certificateNumber: '診第2021-0123号',
      notes: '異常なし',
      nextDueDate: DateTime(now.year, now.month, now.day - 10), // 10日前に期限切れ
      notificationSent: false,
      createdAt: DateTime(now.year - 3, now.month, now.day - 10),
      updatedAt: DateTime(now.year - 3, now.month, now.day - 10),
    );
    await saveMedicalCheckup(checkup1);
    
    // 2. もうすぐ期限の適性診断
    final checkup2 = MedicalCheckup(
      id: 'checkup002',
      userId: 'driver001',
      type: MedicalCheckupType.tekiseishindan,
      checkupDate: DateTime(now.year - 1, now.month, now.day),
      institution: '関東自動車適性診断センター',
      certificateNumber: '診第2023-0456号',
      notes: '良好',
      nextDueDate: DateTime(now.year, now.month, now.day + 20), // 20日後が期限
      notificationSent: false,
      createdAt: DateTime(now.year - 1, now.month, now.day),
      updatedAt: DateTime(now.year - 1, now.month, now.day),
    );
    await saveMedicalCheckup(checkup2);
    
    // 3. 正常な初任診断
    final checkup3 = MedicalCheckup(
      id: 'checkup003',
      userId: 'driver001',
      type: MedicalCheckupType.shoninshindan,
      checkupDate: DateTime(now.year - 5, 4, 15),
      institution: '首都圏適性診断協会',
      certificateNumber: '診第2019-0789号',
      notes: '初任教育合格',
      nextDueDate: DateTime(now.year + 5, 4, 15), // まだ先
      notificationSent: false,
      createdAt: DateTime(now.year - 5, 4, 15),
      updatedAt: DateTime(now.year - 5, 4, 15),
    );
    await saveMedicalCheckup(checkup3);
    
    // Driver2 (D002 - 佐藤花子) のサンプル診断データ
    // 正常な状態
    final checkup4 = MedicalCheckup(
      id: 'checkup004',
      userId: 'driver002',
      type: MedicalCheckupType.tekiseishindan,
      checkupDate: DateTime(now.year, now.month - 2, now.day),
      institution: '東京適性診断センター',
      certificateNumber: '診第2024-0111号',
      notes: '特に問題なし',
      nextDueDate: DateTime(now.year + 1, now.month - 2, now.day),
      notificationSent: false,
      createdAt: DateTime(now.year, now.month - 2, now.day),
      updatedAt: DateTime(now.year, now.month - 2, now.day),
    );
    await saveMedicalCheckup(checkup4);
    
    if (kDebugMode) {
      debugPrint('✅ Sample medical checkup data initialized');
    }
  }

  static Future<void> _initializeEducationItems() async {
    final items = [
      EducationItem(
        id: 'edu001',
        title: 'トラック・バスの運行の安全を確保するために遵守すべき基本的事項',
        category: '基本的事項',
        content: '''
タクシー運転者として、安全運転を実践するための基本的な心構えと法令遵守について学習します。

【重要ポイント】
• 旅客の命を預かる責任の重さを理解する
• 道路運送法、道路交通法等の関係法令を遵守する
• 点呼を確実に受け、運行前の準備を怠らない
• 運行管理者の指示に従い、安全運転を実践する

【安全運転の基本姿勢】
1. 常に周囲の状況を確認し、危険を予測する
2. 制限速度を守り、安全な速度で運行する
3. 適切な車間距離を保つ
4. 疲労を感じたら無理をせず休憩を取る
5. 体調管理に努め、健康状態を維持する
        ''',
        keyPoints: [
          '旅客運送の責任の重さを認識',
          '関係法令の確実な遵守',
          '点呼による健康状態の確認',
          '運行管理者の指示に従う',
          '安全運転の基本姿勢の実践',
        ],
        quizQuestions: [
          QuizQuestion(
            question: 'タクシー運転者が遵守すべき最も基本的な法令はどれですか？',
            options: ['道路運送法', '民法', '商法', '労働基準法'],
            correctAnswerIndex: 0,
            explanation: '道路運送法は、旅客自動車運送事業を規制する基本的な法令です。',
          ),
          QuizQuestion(
            question: '運行前に必ず受けなければならないものは？',
            options: ['健康診断', '点呼', '研修', '試験'],
            correctAnswerIndex: 1,
            explanation: '点呼は、運転者の健康状態や酒気帯びの有無を確認するため、運行前に必ず受けなければなりません。',
          ),
        ],
        estimatedMinutes: 20,
        orderIndex: 1,
      ),
      EducationItem(
        id: 'edu002',
        title: 'タクシー事業に関する法令及び実務の大要',
        category: '法令・実務',
        content: '''
タクシー事業を行う上で必要な法令知識と実務について学習します。

【道路運送法の基礎】
タクシー事業は、道路運送法に基づき国土交通大臣の許可を受けて営業しています。
この法律は、輸送の安全を確保し、利用者の利便性を向上させることを目的としています。

【運賃・料金】
• 認可を受けた運賃・料金以外は収受できません
• メーター器の使用が義務付けられています
• 領収書の発行義務があります

【乗車拒否の禁止】
正当な理由なく乗車を拒否することはできません。
ただし、以下の場合は拒否できます：
• 泥酔者など、他の旅客に迷惑をかける恐れがある場合
• 危険物を携帯している場合
• 感染症の疾病にかかっていると明らかに認められる場合
        ''',
        keyPoints: [
          '道路運送法の目的と内容',
          '運賃・料金に関する規定',
          '乗車拒否禁止の原則',
          '正当な拒否事由の理解',
          '領収書発行義務',
        ],
        quizQuestions: [
          QuizQuestion(
            question: '正当な理由なく乗車を拒否した場合、どうなりますか？',
            options: ['特に問題ない', '注意される', '法令違反となる', '会社が決める'],
            correctAnswerIndex: 2,
            explanation: '乗車拒否は道路運送法違反であり、行政処分の対象となります。',
          ),
          QuizQuestion(
            question: 'タクシーの運賃について正しいものは？',
            options: [
              '運転者が自由に決められる',
              '会社が自由に決められる',
              '国土交通大臣の認可が必要',
              'お客様と交渉して決める'
            ],
            correctAnswerIndex: 2,
            explanation: 'タクシーの運賃は、国土交通大臣の認可を受けた金額以外を収受することはできません。',
          ),
        ],
        estimatedMinutes: 25,
        orderIndex: 2,
      ),
      EducationItem(
        id: 'edu003',
        title: '安全運転の基礎と事故防止',
        category: '安全運転',
        content: '''
事故を未然に防ぐための基本的な運転技術と心構えについて学習します。

【危険予測運転】
常に「かもしれない運転」を心がけましょう。
• 交差点では、他の車が飛び出してくるかもしれない
• 歩行者が急に横断してくるかもしれない
• 前の車が急ブレーキをかけるかもしれない

【安全確認のポイント】
1. 発進時：周囲の安全確認、特に死角に注意
2. 進路変更時：目視による確認が重要
3. 交差点：一時停止の確実な履行
4. バック時：必ず降車して後方確認

【夜間運転の注意点】
• 視界が制限されることを意識する
• ライトの適切な使用（ハイビーム・ロービーム）
• 歩行者や自転車の発見が遅れがちになることに注意
• 疲労が蓄積しやすいため、こまめな休憩を
        ''',
        keyPoints: [
          '危険予測運転（かもしれない運転）',
          '発進・進路変更時の安全確認',
          '交差点での一時停止の徹底',
          '夜間運転の特別な注意事項',
          '疲労運転の防止',
        ],
        quizQuestions: [
          QuizQuestion(
            question: '「かもしれない運転」とは何ですか？',
            options: [
              '不安を持ちながら運転すること',
              '危険を予測しながら運転すること',
              '慎重に運転すること',
              'ゆっくり運転すること'
            ],
            correctAnswerIndex: 1,
            explanation: '「かもしれない運転」とは、常に危険が潜んでいることを予測し、それに備えながら運転することです。',
          ),
          QuizQuestion(
            question: '進路変更時に最も重要な確認方法は？',
            options: ['ミラーだけで確認', '目視による確認', 'センサーに頼る', '勘で判断'],
            correctAnswerIndex: 1,
            explanation: 'ミラーには死角があるため、進路変更時は必ず目視で確認することが重要です。',
          ),
        ],
        estimatedMinutes: 30,
        orderIndex: 3,
      ),
      EducationItem(
        id: 'edu004',
        title: '接客サービスとお客様対応',
        category: '接客',
        content: '''
タクシー運転者として求められる接客サービスの基本を学習します。

【第一印象の重要性】
お客様が最初に接する運転者の印象が、タクシー会社全体の印象につながります。
• 清潔な身だしなみ
• 明るい挨拶
• 丁寧な言葉遣い

【乗車から降車までの対応】
1. 乗車時
   - 「いらっしゃいませ」の挨拶
   - 行き先の確認
   - ドアの安全確認

2. 運行中
   - 安全運転の徹底
   - 快適な車内環境（温度、音楽等）
   - 適切なルート選択

3. 降車時
   - 料金の明確な提示
   - お釣りの確実な授受
   - 「ありがとうございました」の挨拶
   - 忘れ物の確認

【クレーム対応】
お客様からのご意見やクレームには、誠実に対応します。
• まず謝罪する
• お客様の話をよく聞く
• 言い訳をしない
• すぐに対応できない場合は、会社に報告する
        ''',
        keyPoints: [
          '第一印象の大切さ',
          '乗車から降車までの基本対応',
          '快適な車内環境の提供',
          'クレーム対応の基本',
          '忘れ物への注意',
        ],
        quizQuestions: [
          QuizQuestion(
            question: 'お客様が乗車された時、最初にすべきことは？',
            options: ['料金を確認する', '行き先を聞く', '挨拶をする', 'メーターを倒す'],
            correctAnswerIndex: 2,
            explanation: 'まず「いらっしゃいませ」と明るく挨拶をすることが、良い接客の第一歩です。',
          ),
          QuizQuestion(
            question: 'クレームを受けた時の最初の対応は？',
            options: ['言い訳をする', '謝罪する', '無視する', '反論する'],
            correctAnswerIndex: 1,
            explanation: 'クレームには、まず誠意を持って謝罪することが重要です。',
          ),
        ],
        estimatedMinutes: 20,
        orderIndex: 4,
      ),
      EducationItem(
        id: 'edu005',
        title: '交通事故発生時の対応',
        category: '事故対応',
        content: '''
万が一、交通事故が発生した場合の適切な対応について学習します。

【事故発生直後の対応（義務）】
1. 直ちに運転を停止
2. 負傷者の救護
3. 道路上の危険防止措置
4. 警察への通報（110番）
5. 会社への連絡

【絶対にしてはいけないこと】
• 現場から立ち去る（ひき逃げ）
• 当事者間だけで示談する
• 事実と異なる説明をする
• 警察や会社への報告を怠る

【負傷者の救護】
• 安全な場所に移動させる
• 出血がある場合は止血する
• 意識がない場合は呼吸の確認
• 119番通報（救急車の要請）
• できる限りの応急手当を行う

【警察への報告事項】
• 事故発生の日時・場所
• 死傷者の数及び負傷の程度
• 損壊した物及びその程度
• 事故車両の積載物
• 事故について講じた措置

【保険会社への連絡】
会社を通じて、速やかに保険会社に事故を報告します。
        ''',
        keyPoints: [
          '事故発生時の義務（救護・危険防止・通報）',
          '絶対にしてはいけない行動',
          '負傷者の救護方法',
          '警察への報告内容',
          '会社・保険会社への連絡',
        ],
        quizQuestions: [
          QuizQuestion(
            question: '交通事故を起こした時、最優先すべきことは？',
            options: ['会社に連絡', '負傷者の救護', '警察に連絡', '保険会社に連絡'],
            correctAnswerIndex: 1,
            explanation: '人命が最優先です。負傷者がいる場合は、まず救護活動を行います。',
          ),
          QuizQuestion(
            question: '軽微な事故でも必ずしなければならないことは？',
            options: ['当事者間で示談', '警察への報告', '無視する', '後日報告'],
            correctAnswerIndex: 1,
            explanation: 'どんなに軽微な事故でも、警察への報告は法律で義務付けられています。',
          ),
        ],
        estimatedMinutes: 25,
        orderIndex: 5,
      ),
      EducationItem(
        id: 'edu006',
        title: '健康管理と疲労運転の防止',
        category: '健康管理',
        content: '''
安全運転のためには、運転者自身の健康管理が不可欠です。

【日常の健康管理】
• 十分な睡眠時間の確保（最低6時間以上）
• バランスの取れた食事
• 適度な運動習慣
• 定期健康診断の受診
• ストレスの解消

【疲労運転の危険性】
疲労運転は、次のような状態を引き起こします：
• 注意力の低下
• 判断力の低下
• 反応速度の低下
• 眠気（居眠り運転）

これらは重大事故につながる危険性があります。

【疲労を感じた時の対処】
1. すぐに安全な場所に停車
2. 10〜15分の仮眠を取る
3. 軽い体操やストレッチ
4. 顔を洗う、冷たい水を飲む
5. 無理をせず、会社に連絡して指示を仰ぐ

【睡眠時無呼吸症候群（SAS）】
睡眠中に呼吸が止まる病気です。
症状：
• 大きないびき
• 日中の強い眠気
• 起床時の頭痛
• 熟睡感がない

心当たりがある場合は、必ず医療機関を受診しましょう。

【アルコールと運転】
• 飲酒運転は絶対に禁止
• 酒気帯び状態での運転も違法
• 前日の飲酒も翌日に影響する可能性
• 点呼時に必ずアルコールチェックを受ける
        ''',
        keyPoints: [
          '日常的な健康管理の重要性',
          '疲労運転の危険性の認識',
          '疲労を感じた時の適切な対処',
          '睡眠時無呼吸症候群への注意',
          'アルコールと運転の関係',
        ],
        quizQuestions: [
          QuizQuestion(
            question: '疲労を感じた時、最も適切な対処法は？',
            options: ['コーヒーを飲む', '音楽を大音量にする', '安全な場所で休憩', '我慢して運転続行'],
            correctAnswerIndex: 2,
            explanation: '疲労を感じたら、すぐに安全な場所に停車し、休憩を取ることが最も重要です。',
          ),
          QuizQuestion(
            question: '睡眠時無呼吸症候群の主な症状は？',
            options: ['夜間の頻尿', '日中の強い眠気', '手足の痺れ', '視力の低下'],
            correctAnswerIndex: 1,
            explanation: '睡眠時無呼吸症候群の代表的な症状は、十分寝たつもりでも日中に強い眠気を感じることです。',
          ),
        ],
        estimatedMinutes: 20,
        orderIndex: 6,
      ),
    ];

    final box = Hive.box(_educationItemsBox);
    for (final item in items) {
      await box.put(item.id, item.toJson());
    }
  }

  // User operations
  static Future<void> saveUser(User user) async {
    final box = Hive.box(_usersBox);
    await box.put(user.id, user.toJson());
  }

  static User? getUser(String id) {
    final box = Hive.box(_usersBox);
    final data = box.get(id);
    if (data != null) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static User? getUserByEmployeeNumber(String employeeNumber) {
    final box = Hive.box(_usersBox);
    // 大文字小文字を区別しないで検索
    final searchNumber = employeeNumber.toUpperCase().trim();
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final user = User.fromJson(Map<String, dynamic>.from(data));
        if (user.employeeNumber.toUpperCase() == searchNumber) {
          return user;
        }
      }
    }
    return null;
  }

  static List<User> getAllUsers() {
    final box = Hive.box(_usersBox);
    return box.values
        .map((data) => User.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  static List<User> getAllDrivers() {
    return getAllUsers().where((user) => !user.isAdmin).toList();
  }

  // Current user session
  static Future<void> setCurrentUser(User user) async {
    final box = Hive.box(_currentUserBox);
    await box.put('current_user', user.toJson());
  }

  static User? getCurrentUser() {
    final box = Hive.box(_currentUserBox);
    final data = box.get('current_user');
    if (data != null) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<void> clearCurrentUser() async {
    final box = Hive.box(_currentUserBox);
    await box.clear();
  }

  static Future<void> clearAllData() async {
    if (kDebugMode) {
      debugPrint('🗑️ Clearing all data...');
    }
    
    await Hive.box(_usersBox).clear();
    await Hive.box(_educationItemsBox).clear();
    await Hive.box(_learningRecordsBox).clear();
    await Hive.box(_currentUserBox).clear();
    await Hive.box(_medicalCheckupsBox).clear();
    
    if (kDebugMode) {
      debugPrint('✅ All data cleared');
    }
  }

  // Medical Checkup operations
  static Future<void> saveMedicalCheckup(MedicalCheckup checkup) async {
    final box = Hive.box(_medicalCheckupsBox);
    await box.put(checkup.id, checkup.toJson());
  }

  static MedicalCheckup? getMedicalCheckup(String id) {
    final box = Hive.box(_medicalCheckupsBox);
    final data = box.get(id);
    if (data != null) {
      return MedicalCheckup.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static List<MedicalCheckup> getAllMedicalCheckups() {
    final box = Hive.box(_medicalCheckupsBox);
    return box.values
        .map((data) => MedicalCheckup.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  static List<MedicalCheckup> getMedicalCheckupsByUser(String userId) {
    final checkups = getAllMedicalCheckups()
        .where((checkup) => checkup.userId == userId)
        .toList();
    checkups.sort((a, b) => b.checkupDate.compareTo(a.checkupDate));
    return checkups;
  }

  static List<MedicalCheckup> getMedicalCheckupsByType(
    String userId,
    MedicalCheckupType type,
  ) {
    return getMedicalCheckupsByUser(userId)
        .where((checkup) => checkup.type == type)
        .toList();
  }

  static MedicalCheckup? getLatestCheckupByType(
    String userId,
    MedicalCheckupType type,
  ) {
    final checkups = getMedicalCheckupsByType(userId, type);
    if (checkups.isEmpty) return null;
    return checkups.first; // Already sorted by date desc
  }

  static Future<void> deleteMedicalCheckup(String id) async {
    final box = Hive.box(_medicalCheckupsBox);
    await box.delete(id);
  }

  /// 次回診断が必要な人のリストを取得 (通知日数を考慮)
  static List<Map<String, dynamic>> getUpcomingCheckupNotifications() {
    final now = DateTime.now();
    final allUsers = getAllDrivers();
    final notifications = <Map<String, dynamic>>[];

    for (final user in allUsers) {
      final checkups = getMedicalCheckupsByUser(user.id);
      
      // 各診断タイプごとにチェック
      for (final type in MedicalCheckupType.values) {
        final latestCheckup = getLatestCheckupByType(user.id, type);
        
        if (latestCheckup != null && latestCheckup.nextDueDate != null) {
          final notificationDate = latestCheckup.nextDueDate!.subtract(
            Duration(days: type.notificationDaysBefore),
          );
          
          // 通知日を過ぎていて、まだ通知していない場合
          if (now.isAfter(notificationDate) && 
              now.isBefore(latestCheckup.nextDueDate!) &&
              !latestCheckup.notificationSent) {
            notifications.add({
              'user': user,
              'checkup': latestCheckup,
              'daysRemaining': latestCheckup.nextDueDate!.difference(now).inDays,
              'isOverdue': false,
            });
          }
          
          // 期限を過ぎている場合
          if (now.isAfter(latestCheckup.nextDueDate!)) {
            notifications.add({
              'user': user,
              'checkup': latestCheckup,
              'daysOverdue': now.difference(latestCheckup.nextDueDate!).inDays,
              'isOverdue': true,
            });
          }
        }
      }
    }

    return notifications;
  }

  /// 診断管理の統計情報を取得
  static Map<String, dynamic> getMedicalCheckupStatistics(String userId) {
    final checkups = getMedicalCheckupsByUser(userId);
    final now = DateTime.now();
    
    int upToDate = 0;
    int upcoming = 0;
    int overdue = 0;
    
    for (final type in MedicalCheckupType.values) {
      final latest = getLatestCheckupByType(userId, type);
      
      if (latest != null && latest.nextDueDate != null) {
        final daysUntilDue = latest.nextDueDate!.difference(now).inDays;
        
        if (daysUntilDue < 0) {
          overdue++;
        } else if (daysUntilDue <= type.notificationDaysBefore) {
          upcoming++;
        } else {
          upToDate++;
        }
      }
    }
    
    return {
      'total': checkups.length,
      'upToDate': upToDate,
      'upcoming': upcoming,
      'overdue': overdue,
    };
  }

  // Education item operations
  static Future<void> saveEducationItem(EducationItem item) async {
    final box = Hive.box(_educationItemsBox);
    await box.put(item.id, item.toJson());
  }

  static EducationItem? getEducationItem(String id) {
    final box = Hive.box(_educationItemsBox);
    final data = box.get(id);
    if (data != null) {
      return EducationItem.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static List<EducationItem> getAllEducationItems() {
    final box = Hive.box(_educationItemsBox);
    final items = box.values
        .map((data) => EducationItem.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  static Map<String, List<EducationItem>> getEducationItemsByCategory() {
    final items = getAllEducationItems();
    final Map<String, List<EducationItem>> categoryMap = {};
    
    for (var item in items) {
      if (!categoryMap.containsKey(item.category)) {
        categoryMap[item.category] = [];
      }
      categoryMap[item.category]!.add(item);
    }
    
    return categoryMap;
  }

  // Learning record operations
  static Future<void> saveLearningRecord(LearningRecord record) async {
    final box = Hive.box(_learningRecordsBox);
    await box.put(record.id, record.toJson());
  }

  static LearningRecord? getLearningRecord(String id) {
    final box = Hive.box(_learningRecordsBox);
    final data = box.get(id);
    if (data != null) {
      return LearningRecord.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static List<LearningRecord> getAllLearningRecords() {
    final box = Hive.box(_learningRecordsBox);
    return box.values
        .map((data) => LearningRecord.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  static List<LearningRecord> getLearningRecordsByUser(String userId) {
    final records = getAllLearningRecords()
        .where((record) => record.userId == userId)
        .toList();
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  static List<LearningRecord> getLearningRecordsByEducationItem(String educationItemId) {
    return getAllLearningRecords()
        .where((record) => record.educationItemId == educationItemId)
        .toList();
  }

  // Statistics
  static int getTotalLearningMinutes(String userId) {
    final records = getLearningRecordsByUser(userId);
    return records.fold(0, (sum, record) => sum + record.durationMinutes);
  }

  static int getCompletedItemsCount(String userId) {
    final records = getLearningRecordsByUser(userId);
    final completedItemIds = records
        .where((record) => record.completed)
        .map((record) => record.educationItemId)
        .toSet();
    return completedItemIds.length;
  }

  static double getAverageQuizScore(String userId) {
    final records = getLearningRecordsByUser(userId)
        .where((record) => record.quizScore != null && record.totalQuestions != null)
        .toList();
    
    if (records.isEmpty) return 0.0;
    
    final totalScore = records.fold(0.0, (sum, record) {
      final percentage = (record.quizScore! / record.totalQuestions!) * 100;
      return sum + percentage;
    });
    
    return totalScore / records.length;
  }
}
