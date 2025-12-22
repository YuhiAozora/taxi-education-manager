import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../models/invoice.dart';
import '../models/company.dart';
import '../services/subscription_service_demo.dart';


class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> with SingleTickerProviderStateMixin {
  final SubscriptionServiceDemo _subscriptionService = SubscriptionServiceDemo();
  
  late TabController _tabController;
  List<Subscription> _subscriptions = [];
  List<Invoice> _invoices = [];
  List<Company> _companies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (kDebugMode) {
      print('🔄 Loading subscription data...');
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        print('📊 Fetching demo data...');
      }
      
      // ダミーサービスからデータを取得
      final subscriptions = await _subscriptionService.getAllSubscriptions();
      final invoices = await _subscriptionService.getAllInvoices();
      
      // ダミー会社データ
      final now = DateTime.now();
      final companies = [
          Company(
            id: 'company1',
            code: 'TC001',
            name: '東京タクシー株式会社',
            maxDriverCount: 25,
            isActive: true,
            contactEmail: 'info@tokyo-taxi.jp',
            contactPhone: '03-1234-5678',
            createdAt: now.subtract(const Duration(days: 180)),
          ),
          Company(
            id: 'company2',
            code: 'OT001',
            name: '大阪交通サービス',
            maxDriverCount: 45,
            isActive: true,
            contactEmail: 'contact@osaka-trans.jp',
            contactPhone: '06-8765-4321',
            createdAt: now.subtract(const Duration(days: 90)),
          ),
        ];
      
      if (kDebugMode) {
        print('✅ Demo data loaded successfully');
        print('   Companies: ${companies.length}');
        print('   Subscriptions: ${subscriptions.length}');
        print('   Invoices: ${invoices.length}');
      }
      
      setState(() {
        _companies = companies;
        _subscriptions = subscriptions;
        _invoices = invoices;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('🎉 State updated, _isLoading = false');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error loading subscription data: $e');
        print('Stack trace: $stackTrace');
      }
      
      setState(() {
        _isLoading = false;
        _error = 'データの読み込みに失敗しました: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatCurrency(double amount) {
    return '¥${NumberFormat('#,###').format(amount)}';
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
        return Colors.orange;
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.suspended:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getInvoiceStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.pending:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  Company? _getCompanyById(String companyId) {
    try {
      return _companies.firstWhere((c) => c.id == companyId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('契約・請求管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: '契約一覧'),
            Tab(icon: Icon(Icons.receipt_long), text: '請求書一覧'),
            Tab(icon: Icon(Icons.analytics), text: '統計'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '再読み込み',
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
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'エラーが発生しました',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSubscriptionsTab(),
                    _buildInvoicesTab(),
                    _buildStatisticsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMonthlyBillingDialog,
        icon: const Icon(Icons.payments),
        label: const Text('月次請求処理'),
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_subscriptions.isEmpty) {
      return const Center(
        child: Text('契約情報がありません'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          final company = _getCompanyById(subscription.companyId);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(subscription.status),
                child: Icon(
                  _getSubscriptionIcon(subscription.status),
                  color: Colors.white,
                ),
              ),
              title: Text(
                company?.name ?? '不明な会社',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('ステータス: ${subscription.status.displayName}'),
                  Text('契約運転者数: ${subscription.contractedDriverCount}名'),
                  Text('月額料金: ${_formatCurrency(subscription.monthlyFee)}'),
                  if (subscription.status == SubscriptionStatus.trial)
                    Text(
                      '試用期間残り: ${subscription.trialDaysRemaining}日',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  if (subscription.nextPaymentDate != null)
                    Text('次回支払日: ${_formatDate(subscription.nextPaymentDate!)}'),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  if (subscription.status == SubscriptionStatus.trial)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Text('契約を有効化'),
                    ),
                  if (subscription.status == SubscriptionStatus.active)
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Text('契約を停止'),
                    ),
                  if (subscription.status != SubscriptionStatus.cancelled)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('契約を解約'),
                    ),
                  const PopupMenuItem(
                    value: 'invoices',
                    child: Text('請求書を表示'),
                  ),
                ],
                onSelected: (value) => _handleSubscriptionAction(value, subscription, company),
              ),
              onTap: () => _showSubscriptionDetails(subscription, company),
            ),
          );
        },
      ),
    );
  }

  IconData _getSubscriptionIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.trial:
        return Icons.schedule;
      case SubscriptionStatus.active:
        return Icons.check_circle;
      case SubscriptionStatus.suspended:
        return Icons.pause_circle;
      case SubscriptionStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return const Center(
        child: Text('請求書がありません'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _exportInvoicesToCsv,
            icon: const Icon(Icons.download),
            label: const Text('CSVエクスポート'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getInvoiceStatusColor(invoice.status),
                      child: const Icon(Icons.receipt, color: Colors.white),
                    ),
                    title: Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(invoice.companyName),
                        Text('発行日: ${_formatDate(invoice.issueDate)}'),
                        Text('支払期限: ${_formatDate(invoice.dueDate)}'),
                        Text(
                          '合計: ${_formatCurrency(invoice.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(invoice.status.displayName),
                      backgroundColor: _getInvoiceStatusColor(invoice.status).withOpacity(0.2),
                    ),
                    onTap: () => _showInvoiceDetails(invoice),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final activeCount = _subscriptions
        .where((s) => s.status == SubscriptionStatus.active || s.status == SubscriptionStatus.trial)
        .length;
    final trialCount = _subscriptions
        .where((s) => s.status == SubscriptionStatus.trial)
        .length;
    final totalRevenue = _subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .fold(0.0, (sum, s) => sum + s.monthlyFee);
    final paidInvoices = _invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .length;
    final overdueInvoices = _invoices
        .where((i) => i.status == InvoiceStatus.overdue || i.isOverdue)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          '有効契約数',
          '$activeCount件',
          Icons.business,
          Colors.green,
        ),
        _buildStatCard(
          '試用期間中',
          '$trialCount件',
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          '月間売上見込',
          _formatCurrency(totalRevenue),
          Icons.attach_money,
          Colors.blue,
        ),
        _buildStatCard(
          '支払済請求書',
          '$paidInvoices件',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          '期限超過請求書',
          '$overdueInvoices件',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubscriptionAction(dynamic value, Subscription subscription, Company? company) {
    switch (value) {
      case 'activate':
        _activateSubscription(subscription, company);
        break;
      case 'suspend':
        _suspendSubscription(subscription);
        break;
      case 'cancel':
        _cancelSubscription(subscription);
        break;
      case 'invoices':
        _showCompanyInvoices(subscription.companyId);
        break;
    }
  }

  Future<void> _activateSubscription(Subscription subscription, Company? company) async {
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会社情報が見つかりません')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('契約を有効化'),
        content: Text('${company.name}の契約を有効化しますか?\n月額料金が発生します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('有効化'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subscriptionService.activateSubscription(subscription.id, company);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('契約を有効化しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _suspendSubscription(Subscription subscription) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('契約を停止'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この契約を停止しますか?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '理由',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('停止'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subscriptionService.suspendSubscription(
          subscription.id,
          reasonController.text,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('契約を停止しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelSubscription(Subscription subscription) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('契約を解約'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この契約を解約しますか?\nこの操作は取り消せません。'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '理由',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('解約'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subscriptionService.cancelSubscription(
          subscription.id,
          reasonController.text,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('契約を解約しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  void _showSubscriptionDetails(Subscription subscription, Company? company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('契約詳細'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('会社名', company?.name ?? '不明'),
              _buildDetailRow('ステータス', subscription.status.displayName),
              _buildDetailRow('契約開始日', _formatDate(subscription.startDate)),
              if (subscription.trialEndDate != null)
                _buildDetailRow('試用期間終了日', _formatDate(subscription.trialEndDate!)),
              if (subscription.endDate != null)
                _buildDetailRow('契約終了日', _formatDate(subscription.endDate!)),
              _buildDetailRow('契約運転者数', '${subscription.contractedDriverCount}名'),
              _buildDetailRow('月額料金', _formatCurrency(subscription.monthlyFee)),
              if (subscription.lastPaymentDate != null)
                _buildDetailRow('最終支払日', _formatDate(subscription.lastPaymentDate!)),
              if (subscription.nextPaymentDate != null)
                _buildDetailRow('次回支払日', _formatDate(subscription.nextPaymentDate!)),
              if (subscription.notes != null)
                _buildDetailRow('備考', subscription.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(invoice.invoiceNumber),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('会社名', invoice.companyName),
              _buildDetailRow('ステータス', invoice.status.displayName),
              _buildDetailRow('発行日', _formatDate(invoice.issueDate)),
              _buildDetailRow('支払期限', _formatDate(invoice.dueDate)),
              if (invoice.paidDate != null)
                _buildDetailRow('支払日', _formatDate(invoice.paidDate!)),
              _buildDetailRow(
                '請求期間',
                '${_formatDate(invoice.billingPeriodStart)} - ${_formatDate(invoice.billingPeriodEnd)}',
              ),
              const Divider(),
              const Text(
                '明細',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...invoice.lineItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description),
                    Text(
                      '${item.quantity}名 × ${_formatCurrency(item.unitPrice)} = ${_formatCurrency(item.amount)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )),
              const Divider(),
              _buildDetailRow('小計', _formatCurrency(invoice.subtotal)),
              _buildDetailRow('消費税(${(invoice.taxRate * 100).toInt()}%)', _formatCurrency(invoice.taxAmount)),
              _buildDetailRow(
                '合計',
                _formatCurrency(invoice.totalAmount),
              ),
            ],
          ),
        ),
        actions: [
          if (invoice.status == InvoiceStatus.pending || invoice.status == InvoiceStatus.sent)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markInvoiceAsPaid(invoice);
              },
              child: const Text('支払済にする'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _markInvoiceAsPaid(Invoice invoice) async {
    try {
      await _subscriptionService.updateInvoiceStatus(invoice.id, InvoiceStatus.paid);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請求書を支払済にしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  void _showCompanyInvoices(String companyId) {
    // 会社の請求書一覧を表示
    final companyInvoices = _invoices
        .where((i) => i.companyId == companyId)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('請求書一覧'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: companyInvoices.length,
            itemBuilder: (context, index) {
              final invoice = companyInvoices[index];
              return ListTile(
                title: Text(invoice.invoiceNumber),
                subtitle: Text(_formatDate(invoice.issueDate)),
                trailing: Text(_formatCurrency(invoice.totalAmount)),
                onTap: () {
                  Navigator.pop(context);
                  _showInvoiceDetails(invoice);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthlyBillingDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('月次請求処理'),
        content: const Text(
          '有効な契約に対して今月分の請求書を一括生成します。\n処理を実行しますか?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('請求処理中...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await _subscriptionService.processMonthlyBilling();
        await _loadData();
        
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('月次請求処理が完了しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportInvoicesToCsv() async {
    try {
      final csvData = _subscriptionService.exportInvoicesToCsv(_invoices);
      
      // CSVデータをクリップボードにコピー
      // 実際のアプリではファイルダウンロードを実装
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSVデータを生成しました\n(実装: ファイルダウンロード機能を追加)'),
          action: SnackBarAction(
            label: '表示',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSVプレビュー'),
                  content: SingleChildScrollView(
                    child: Text(
                      csvData,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}
