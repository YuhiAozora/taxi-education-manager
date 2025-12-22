import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';
import '../models/statistics.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'subscription_management_screen.dart';

/// スーパー管理者ホーム画面
/// コミュニティ運営者専用の管理画面
class SuperAdminHomeScreen extends StatefulWidget {
  final User currentUser;

  const SuperAdminHomeScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  List<Company> _companies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Web版ではデモデータを使用（Firestoreが使えないため）
      if (kIsWeb) {
        // デモ用の会社データ
        final demoCompanies = <Company>[];
        
        // まだ企業が登録されていない状態でスタート
        setState(() {
          _companies = demoCompanies;
          _isLoading = false;
        });
        return;
      }
      
      // モバイル版: Firestoreから取得
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      final companies = companiesSnapshot.docs
          .map((doc) => Company.fromJson(doc.data(), doc.id))
          .toList();

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スーパー管理者ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionManagementScreen(),
                ),
              );
            },
            tooltip: '契約・請求管理',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await DatabaseService.clearCurrentUser();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // サマリーカード
                          _buildSummaryCards(),
                          const SizedBox(height: 24),

                          // 会員企業一覧
                          _buildCompaniesSection(),
                          const SizedBox(height: 24),

                          // 統計情報
                          _buildStatisticsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCompanyDialog,
        icon: const Icon(Icons.add_business),
        label: const Text('新規企業追加'),
      ),
    );
  }

  /// サマリーカード（全体統計）
  Widget _buildSummaryCards() {
    final totalCompanies = _companies.length;
    final activeCompanies = _companies.where((c) => c.isActive).length;
    final totalDrivers = _companies.fold<int>(0, (sum, c) => sum + c.maxDriverCount);
    final totalRevenue = _companies.fold<int>(0, (sum, c) => sum + c.calculateMonthlyFee());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '全体サマリー',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '会員企業数',
                '$totalCompanies社',
                Icons.business,
                Colors.blue,
                subtitle: 'アクティブ: $activeCompanies社',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                '総運転者数',
                '$totalDrivers人',
                Icons.people,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '月間売上',
                '¥${totalRevenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                Icons.attach_money,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                '年間予測',
                '¥${(totalRevenue * 12).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 会員企業一覧セクション
  Widget _buildCompaniesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '会員企業一覧',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _exportCompaniesCSV,
              icon: const Icon(Icons.download),
              label: const Text('CSV出力'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_companies.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('まだ会員企業が登録されていません'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _companies.length,
            itemBuilder: (context, index) {
              final company = _companies[index];
              return _buildCompanyCard(company);
            },
          ),
      ],
    );
  }

  Widget _buildCompanyCard(Company company) {
    final monthlyFee = company.calculateMonthlyFee();
    final pricePerDriver = company.getPricePerDriver();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: company.isActive ? Colors.green : Colors.grey,
          child: Text(
            company.name.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          company.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('プラン: ${company.plan.displayName} | 運転者: ${company.maxDriverCount}人'),
            Text('単価: ¥${pricePerDriver.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} /人・月'),
            Text(
              '月額: ¥${monthlyFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            _showCompanyDetail(company);
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '業界統計（匿名化）',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('統計データは準備中です'),
            ),
          ),
        ),
      ],
    );
  }

  /// 新規企業追加ダイアログ
  Future<void> _showAddCompanyDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    CompanyPlan selectedPlan = CompanyPlan.basic;
    int maxDriverCount = 10;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新規会員企業追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '企業名',
                        hintText: '例: 〇〇タクシー株式会社',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: '企業コード',
                        hintText: '例: ABC001',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CompanyPlan>(
                      value: selectedPlan,
                      decoration: const InputDecoration(
                        labelText: 'プラン',
                      ),
                      items: CompanyPlan.values.map((plan) {
                        return DropdownMenuItem(
                          value: plan,
                          child: Text('${plan.displayName} (${plan.description})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPlan = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '運転者数',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        maxDriverCount = int.tryParse(value) ?? 10;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || codeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('企業名と企業コードを入力してください')),
                      );
                      return;
                    }

                    // 企業を追加
                    final company = Company(
                      id: 'company_${DateTime.now().millisecondsSinceEpoch}',
                      code: codeController.text,
                      name: nameController.text,
                      plan: selectedPlan,
                      maxDriverCount: maxDriverCount,
                      isActive: true,
                      contractStartDate: DateTime.now(),
                    );

                    // Web版ではローカルリストに追加
                    if (kIsWeb) {
                      setState(() {
                        _companies.add(company);
                      });
                    } else {
                      // モバイル版: Firestoreに追加
                      await FirebaseFirestore.instance
                          .collection('companies')
                          .add(company.toJson());
                      await _loadData();
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('企業を追加しました')),
                      );
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 企業詳細表示
  void _showCompanyDetail(Company company) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(company.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('企業コード', company.code),
                _buildDetailRow('プラン', company.plan.displayName),
                _buildDetailRow('運転者数', '${company.maxDriverCount}人'),
                _buildDetailRow('単価', '¥${company.getPricePerDriver()} /人・月'),
                _buildDetailRow(
                  '月額料金',
                  '¥${company.calculateMonthlyFee().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                ),
                _buildDetailRow(
                  '契約状態',
                  company.isActive ? 'アクティブ' : '停止中',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// CSV出力
  Future<void> _exportCompaniesCSV() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV出力機能は準備中です')),
    );
  }
}
