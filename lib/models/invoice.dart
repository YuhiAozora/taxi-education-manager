import 'package:cloud_firestore/cloud_firestore.dart';

/// 請求書ステータス
enum InvoiceStatus {
  pending,    // 未請求
  sent,       // 請求書送付済み
  paid,       // 支払い済み
  overdue,    // 支払い期限超過
  cancelled,  // キャンセル
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.pending:
        return '未請求';
      case InvoiceStatus.sent:
        return '送付済み';
      case InvoiceStatus.paid:
        return '支払済';
      case InvoiceStatus.overdue:
        return '期限超過';
      case InvoiceStatus.cancelled:
        return 'キャンセル';
    }
  }
  
  String get displayColor {
    switch (this) {
      case InvoiceStatus.pending:
        return '#9E9E9E'; // グレー
      case InvoiceStatus.sent:
        return '#FFA726'; // オレンジ
      case InvoiceStatus.paid:
        return '#66BB6A'; // 緑
      case InvoiceStatus.overdue:
        return '#EF5350'; // 赤
      case InvoiceStatus.cancelled:
        return '#9E9E9E'; // グレー
    }
  }
}

/// 請求書明細項目
class InvoiceLineItem {
  String description;       // 説明
  int quantity;            // 数量
  double unitPrice;        // 単価
  double amount;           // 金額

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

/// 請求書モデル
class Invoice {
  String id;                      // 請求書ID
  String invoiceNumber;           // 請求書番号（例: INV-2024-001）
  String companyId;               // 会社ID
  String companyName;             // 会社名（キャッシュ）
  InvoiceStatus status;           // ステータス
  DateTime billingPeriodStart;    // 請求期間開始日
  DateTime billingPeriodEnd;      // 請求期間終了日
  DateTime issueDate;             // 発行日
  DateTime dueDate;               // 支払期限
  DateTime? paidDate;             // 支払日
  List<InvoiceLineItem> lineItems; // 明細項目
  double subtotal;                // 小計
  double taxRate;                 // 税率（例: 0.1 = 10%）
  double taxAmount;               // 税額
  double totalAmount;             // 合計金額
  String? notes;                  // 備考
  DateTime createdAt;             // 作成日時
  DateTime updatedAt;             // 更新日時

  Invoice({
    this.id = '',
    required this.invoiceNumber,
    required this.companyId,
    required this.companyName,
    this.status = InvoiceStatus.pending,
    required this.billingPeriodStart,
    required this.billingPeriodEnd,
    DateTime? issueDate,
    DateTime? dueDate,
    this.paidDate,
    List<InvoiceLineItem>? lineItems,
    this.subtotal = 0,
    this.taxRate = 0.1,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : issueDate = issueDate ?? DateTime.now(),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30)),
       lineItems = lineItems ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 支払い期限が過ぎているか
  bool get isOverdue {
    if (status == InvoiceStatus.paid || status == InvoiceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate);
  }
  
  /// 期限までの残り日数
  int get daysUntilDue {
    final remaining = dueDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  /// 期限超過日数
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }
  
  /// 合計金額を再計算
  void recalculateTotals() {
    subtotal = lineItems.fold(0, (sum, item) => sum + item.amount);
    taxAmount = subtotal * taxRate;
    totalAmount = subtotal + taxAmount;
  }
  
  /// CSVフォーマットのヘッダー
  static String get csvHeader {
    return '請求書番号,会社名,請求期間,発行日,支払期限,ステータス,小計,税額,合計金額';
  }
  
  /// CSV行データ
  String toCsvRow() {
    final period = '${_formatDate(billingPeriodStart)} - ${_formatDate(billingPeriodEnd)}';
    return '$invoiceNumber,$companyName,$period,${_formatDate(issueDate)},${_formatDate(dueDate)},${status.displayName},¥${_formatCurrency(subtotal)},¥${_formatCurrency(taxAmount)},¥${_formatCurrency(totalAmount)}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
  
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'companyId': companyId,
      'companyName': companyName,
      'status': status.name,
      'billingPeriodStart': Timestamp.fromDate(billingPeriodStart),
      'billingPeriodEnd': Timestamp.fromDate(billingPeriodEnd),
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json, String documentId) {
    final lineItemsData = json['lineItems'] as List<dynamic>? ?? [];
    final lineItems = lineItemsData
        .map((item) => InvoiceLineItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Invoice(
      id: documentId,
      invoiceNumber: json['invoiceNumber'] ?? '',
      companyId: json['companyId'] ?? '',
      companyName: json['companyName'] ?? '',
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      billingPeriodStart: (json['billingPeriodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      billingPeriodEnd: (json['billingPeriodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issueDate: (json['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (json['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (json['paidDate'] as Timestamp?)?.toDate(),
      lineItems: lineItems,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0.1).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? companyId,
    String? companyName,
    InvoiceStatus? status,
    DateTime? billingPeriodStart,
    DateTime? billingPeriodEnd,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    List<InvoiceLineItem>? lineItems,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      billingPeriodStart: billingPeriodStart ?? this.billingPeriodStart,
      billingPeriodEnd: billingPeriodEnd ?? this.billingPeriodEnd,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
