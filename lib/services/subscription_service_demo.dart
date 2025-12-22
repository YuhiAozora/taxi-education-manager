// Web版用のダミーデータサービス
// Firebase/Firestoreを使用せず、完全にローカルデータで動作

import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../models/invoice.dart';
import '../models/company.dart';

class SubscriptionServiceDemo {
  
  /// すべての契約データを取得（ダミーデータ）
  Future<List<Subscription>> getAllSubscriptions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final now = DateTime.now();
    return [
      Subscription(
        id: 'sub1',
        companyId: 'company1',
        status: SubscriptionStatus.active,
        startDate: now.subtract(const Duration(days: 60)),
        contractedDriverCount: 25,
        monthlyFee: 125000,
        lastPaymentDate: now.subtract(const Duration(days: 5)),
        nextPaymentDate: now.add(const Duration(days: 25)),
      ),
      Subscription(
        id: 'sub2',
        companyId: 'company2',
        status: SubscriptionStatus.trial,
        startDate: now.subtract(const Duration(days: 10)),
        trialEndDate: now.add(const Duration(days: 20)),
        contractedDriverCount: 45,
        monthlyFee: 0,
        nextPaymentDate: now.add(const Duration(days: 20)),
      ),
    ];
  }
  
  /// すべての請求書データを取得（ダミーデータ）
  Future<List<Invoice>> getAllInvoices() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return [
      Invoice(
        id: 'inv1',
        invoiceNumber: 'INV-2024-11-001',
        companyId: 'company1',
        companyName: '東京タクシー株式会社',
        status: InvoiceStatus.paid,
        billingPeriodStart: DateTime(2024, 11, 1),
        billingPeriodEnd: DateTime(2024, 11, 30),
        issueDate: DateTime(2024, 11, 1),
        dueDate: DateTime(2024, 11, 30),
        lineItems: [
          InvoiceLineItem(
            description: 'タクシー乗務員教育管理システム 月額利用料',
            quantity: 25,
            unitPrice: 5000,
            amount: 125000,
          ),
        ],
        subtotal: 125000,
        taxRate: 0.1,
        taxAmount: 12500,
        totalAmount: 137500,
        paidDate: DateTime(2024, 11, 15),
      ),
      Invoice(
        id: 'inv2',
        invoiceNumber: 'INV-2024-10-001',
        companyId: 'company1',
        companyName: '東京タクシー株式会社',
        status: InvoiceStatus.paid,
        billingPeriodStart: DateTime(2024, 10, 1),
        billingPeriodEnd: DateTime(2024, 10, 31),
        issueDate: DateTime(2024, 10, 1),
        dueDate: DateTime(2024, 10, 31),
        lineItems: [
          InvoiceLineItem(
            description: 'タクシー乗務員教育管理システム 月額利用料',
            quantity: 25,
            unitPrice: 5000,
            amount: 125000,
          ),
        ],
        subtotal: 125000,
        taxRate: 0.1,
        taxAmount: 12500,
        totalAmount: 137500,
        paidDate: DateTime(2024, 10, 20),
      ),
    ];
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
  
  /// 契約を有効化（ダミー実装）
  Future<void> activateSubscription(String subscriptionId, Company company) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('✅ Subscription activated (demo): $subscriptionId');
    }
  }
  
  /// 契約を停止（ダミー実装）
  Future<void> suspendSubscription(String subscriptionId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('⏸️ Subscription suspended (demo): $subscriptionId');
    }
  }
  
  /// 契約を解約（ダミー実装）
  Future<void> cancelSubscription(String subscriptionId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('❌ Subscription cancelled (demo): $subscriptionId');
    }
  }
  
  /// 請求書のステータスを更新（ダミー実装）
  Future<void> updateInvoiceStatus(String invoiceId, InvoiceStatus status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) {
      print('📝 Invoice status updated (demo): $invoiceId -> $status');
    }
  }
  
  /// 月次の自動請求処理（ダミー実装）
  Future<void> processMonthlyBilling() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (kDebugMode) {
      print('💰 Monthly billing processed (demo)');
    }
  }
}
