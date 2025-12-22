import 'package:flutter/material.dart';
import '../models/user.dart';

class WelfareScreen extends StatefulWidget {
  final User currentUser;

  const WelfareScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends State<WelfareScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('福利厚生'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ヘッダー情報カード
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '福利厚生制度',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '社員のみなさまの働きやすい環境づくりをサポートします',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 福利厚生メニュー
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCategorySection(
                    context,
                    '保険・年金制度',
                    Icons.health_and_safety,
                    Colors.blue,
                    [
                      _WelfareItem(
                        '健康保険',
                        '社会保険完備（協会けんぽ加入）',
                        Icons.local_hospital,
                      ),
                      _WelfareItem(
                        '厚生年金保険',
                        '厚生年金に加入し、将来の年金を確保',
                        Icons.savings,
                      ),
                      _WelfareItem(
                        '雇用保険',
                        '雇用保険に加入し、失業時の生活を保障',
                        Icons.work,
                      ),
                      _WelfareItem(
                        '労災保険',
                        '業務災害・通勤災害に対応',
                        Icons.security,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    context,
                    '手当・補助',
                    Icons.attach_money,
                    Colors.green,
                    [
                      _WelfareItem(
                        '通勤手当',
                        '通勤にかかる交通費を全額支給',
                        Icons.train,
                      ),
                      _WelfareItem(
                        '家族手当',
                        '扶養家族1人につき月額5,000円を支給',
                        Icons.family_restroom,
                      ),
                      _WelfareItem(
                        '住宅手当',
                        '家賃の一部を補助（上限月額20,000円）',
                        Icons.home,
                      ),
                      _WelfareItem(
                        '深夜手当',
                        '22時〜翌5時の勤務に対し割増賃金を支給',
                        Icons.nightlight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    context,
                    '休暇制度',
                    Icons.beach_access,
                    Colors.orange,
                    [
                      _WelfareItem(
                        '有給休暇',
                        '年間10日〜20日（勤続年数に応じて付与）',
                        Icons.event_available,
                      ),
                      _WelfareItem(
                        '特別休暇',
                        '慶弔休暇、リフレッシュ休暇など',
                        Icons.star,
                      ),
                      _WelfareItem(
                        '産前産後休暇',
                        '産前6週間、産後8週間の休暇を付与',
                        Icons.pregnant_woman,
                      ),
                      _WelfareItem(
                        '育児休業',
                        '最長2年間の育児休業を取得可能',
                        Icons.child_care,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    context,
                    '健康・医療サポート',
                    Icons.medical_services,
                    Colors.red,
                    [
                      _WelfareItem(
                        '定期健康診断',
                        '年1回の定期健康診断を会社負担で実施',
                        Icons.medication,
                      ),
                      _WelfareItem(
                        '人間ドック補助',
                        '35歳以上の社員に人間ドック費用を一部補助',
                        Icons.local_pharmacy,
                      ),
                      _WelfareItem(
                        'インフルエンザ予防接種',
                        '希望者にインフルエンザ予防接種を会社負担で実施',
                        Icons.vaccines,
                      ),
                      _WelfareItem(
                        'メンタルヘルスケア',
                        '専門カウンセラーによる相談窓口を設置',
                        Icons.psychology,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    context,
                    'キャリア支援',
                    Icons.school,
                    Colors.purple,
                    [
                      _WelfareItem(
                        '資格取得支援',
                        '業務に関連する資格取得費用を会社が負担',
                        Icons.card_membership,
                      ),
                      _WelfareItem(
                        '研修制度',
                        '社内研修、外部研修への参加機会を提供',
                        Icons.cast_for_education,
                      ),
                      _WelfareItem(
                        'キャリア面談',
                        '年2回の個別キャリア面談を実施',
                        Icons.groups,
                      ),
                      _WelfareItem(
                        '表彰制度',
                        '優秀な成績を収めた社員を表彰',
                        Icons.emoji_events,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySection(
                    context,
                    'その他の制度',
                    Icons.more_horiz,
                    Colors.teal,
                    [
                      _WelfareItem(
                        '退職金制度',
                        '勤続3年以上の社員に退職金を支給',
                        Icons.account_balance,
                      ),
                      _WelfareItem(
                        '社員旅行',
                        '年1回の社員旅行を実施（参加費用は会社負担）',
                        Icons.flight,
                      ),
                      _WelfareItem(
                        '社員食堂',
                        '栄養バランスの取れた食事を格安で提供',
                        Icons.restaurant,
                      ),
                      _WelfareItem(
                        '制服貸与',
                        '業務用制服を無償貸与、クリーニング費用も会社負担',
                        Icons.checkroom,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // お問い合わせカード
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_support,
                        size: 32,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '福利厚生に関するお問い合わせ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '福利厚生制度についてご不明な点がございましたら、\n人事部までお問い合わせください。',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: お問い合わせ機能を実装
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('お問い合わせ機能は実装予定です'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mail),
                        label: const Text('人事部に問い合わせる'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_WelfareItem> items,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(item.icon, color: color, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WelfareItem {
  final String title;
  final String description;
  final IconData icon;

  _WelfareItem(this.title, this.description, this.icon);
}
