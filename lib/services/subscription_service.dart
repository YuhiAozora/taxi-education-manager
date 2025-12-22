import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../models/invoice.dart';
import '../models/company.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 新規契約を作成（試用期間30日）
  Future<Subscription> createTrialSubscription(String companyId, int driverCount) async {
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 30));
    
    final subscription = Subscription(
      companyId: companyId,
      status: SubscriptionStatus.trial,
      startDate: now,
      trialEndDate: trialEndDate,
      contractedDriverCount: driverCount,
      monthlyFee: 0, // 試用期間は無料
      nextPaymentDate: trialEndDate, // 試用期間終了後に最初の支払い
    );

    final docRef = await _firestore
        .collection('subscriptions')
        .add(subscription.toJson());
    
    return subscription.copyWith(id: docRef.id);
  }

  /// 契約を有効化（試用期間→有効）
  Future<void> activateSubscription(String subscriptionId, Company company) async {
    final monthlyFee = company.calculateMonthlyFee().toDouble();
    final now = DateTime.now();
    final nextPaymentDate = DateTime(now.year, now.month + 1, 1); // 翌月1日

    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.active.name,
      'monthlyFee': monthlyFee,
      'lastPaymentDate': Timestamp.fromDate(now),
      'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// 契約を停止（支払い遅延時）
  Future<void> suspendSubscription(String subscriptionId, String reason) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.suspended.name,
      'notes': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 契約を解約
  Future<void> cancelSubscription(String subscriptionId, String reason) async {
    final now = DateTime.now();
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
      'endDate': Timestamp.fromDate(now),
      'notes': reason,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// 会社の契約情報を取得
  Future<Subscription?> getSubscriptionByCompanyId(String companyId) async {
    final querySnapshot = await _firestore
        .collection('subscriptions')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    return Subscription.fromJson(doc.data(), doc.id);
  }

  /// すべての契約を取得
  Future<List<Subscription>> getAllSubscriptions() async {
    final querySnapshot = await _firestore
        .collection('subscriptions')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 有効な契約のみを取得
  Future<List<Subscription>> getActiveSubscriptions() async {
    final querySnapshot = await _firestore
        .collection('subscriptions')
        .where('status', whereIn: [
          SubscriptionStatus.trial.name,
          SubscriptionStatus.active.name,
        ])
        .get();

    return querySnapshot.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 支払い期限が近い契約を取得（7日以内）
  Future<List<Subscription>> getUpcomingPayments() async {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    final querySnapshot = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .where('nextPaymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('nextPaymentDate', isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysLater))
        .get();

    return querySnapshot.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 支払い遅延の契約を取得
  Future<List<Subscription>> getOverdueSubscriptions() async {
    final now = DateTime.now();

    final querySnapshot = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .where('nextPaymentDate', isLessThan: Timestamp.fromDate(now))
        .get();

    return querySnapshot.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 月次請求書を生成
  Future<Invoice> generateMonthlyInvoice(Subscription subscription, Company company) async {
    final now = DateTime.now();
    final billingPeriodStart = DateTime(now.year, now.month, 1);
    final billingPeriodEnd = DateTime(now.year, now.month + 1, 0);

    // 請求書番号の生成（例: INV-2024-11-001）
    final invoiceNumber = await _generateInvoiceNumber(now);

    // 明細項目の作成
    final lineItems = <InvoiceLineItem>[
      InvoiceLineItem(
        description: 'タクシー乗務員教育管理システム 月額利用料',
        quantity: subscription.contractedDriverCount,
        unitPrice: company.getPricePerDriver().toDouble(),
        amount: subscription.monthlyFee,
      ),
    ];

    final invoice = Invoice(
      invoiceNumber: invoiceNumber,
      companyId: company.id,
      companyName: company.name,
      status: InvoiceStatus.pending,
      billingPeriodStart: billingPeriodStart,
      billingPeriodEnd: billingPeriodEnd,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      lineItems: lineItems,
      subtotal: subscription.monthlyFee,
      taxRate: 0.1,
    );

    // 合計金額の計算
    invoice.recalculateTotals();

    // Firestoreに保存
    final docRef = await _firestore
        .collection('invoices')
        .add(invoice.toJson());

    return invoice.copyWith(id: docRef.id);
  }

  /// 請求書番号を生成
  Future<String> _generateInvoiceNumber(DateTime date) async {
    final prefix = 'INV-${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    // 今月の請求書数を取得
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);

    final querySnapshot = await _firestore
        .collection('invoices')
        .where('issueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final count = querySnapshot.docs.length + 1;
    return '$prefix-${count.toString().padLeft(3, '0')}';
  }

  /// すべての請求書を取得
  Future<List<Invoice>> getAllInvoices() async {
    final querySnapshot = await _firestore
        .collection('invoices')
        .orderBy('issueDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Invoice.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 会社の請求書を取得
  Future<List<Invoice>> getInvoicesByCompanyId(String companyId) async {
    final querySnapshot = await _firestore
        .collection('invoices')
        .where('companyId', isEqualTo: companyId)
        .orderBy('issueDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Invoice.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// 請求書のステータスを更新
  Future<void> updateInvoiceStatus(String invoiceId, InvoiceStatus status) async {
    final updates = {
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (status == InvoiceStatus.paid) {
      updates['paidDate'] = Timestamp.fromDate(DateTime.now());
    }

    await _firestore.collection('invoices').doc(invoiceId).update(updates);
  }

  /// CSV形式で請求書データをエクスポート
  String exportInvoicesToCsv(List<Invoice> invoices) {
    final buffer = StringBuffer();
    buffer.writeln(Invoice.csvHeader);

    for (final invoice in invoices) {
      buffer.writeln(invoice.toCsvRow());
    }

    return buffer.toString();
  }

  /// 月次の自動請求処理（バッチ処理用）
  Future<void> processMonthlyBilling() async {
    if (kDebugMode) {
      print('月次請求処理を開始...');
    }

    // 有効な契約を取得
    final activeSubscriptions = await getActiveSubscriptions();
    
    if (kDebugMode) {
      print('有効な契約数: ${activeSubscriptions.length}');
    }

    for (final subscription in activeSubscriptions) {
      try {
        // 試用期間の契約はスキップ
        if (subscription.status == SubscriptionStatus.trial) {
          continue;
        }

        // 会社情報を取得
        final companyDoc = await _firestore
            .collection('companies')
            .doc(subscription.companyId)
            .get();

        if (!companyDoc.exists) {
          if (kDebugMode) {
            print('会社情報が見つかりません: ${subscription.companyId}');
          }
          continue;
        }

        final company = Company.fromJson(companyDoc.data()!, companyDoc.id);

        // 請求書を生成
        final invoice = await generateMonthlyInvoice(subscription, company);

        if (kDebugMode) {
          print('請求書を生成しました: ${invoice.invoiceNumber} - ${company.name}');
        }

        // 請求書を送付済みにマーク
        await updateInvoiceStatus(invoice.id, InvoiceStatus.sent);

      } catch (e) {
        if (kDebugMode) {
          print('請求処理エラー (契約ID: ${subscription.id}): $e');
        }
      }
    }

    if (kDebugMode) {
      print('月次請求処理が完了しました');
    }
  }
}
