import 'package:cloud_firestore/cloud_firestore.dart';

/// 料金プラン
enum CompanyPlan {
  basic,    // 基本プラン
  premium,  // プレミアムプラン
  enterprise, // エンタープライズプラン
}

extension CompanyPlanExtension on CompanyPlan {
  String get displayName {
    switch (this) {
      case CompanyPlan.basic:
        return 'ベーシック';
      case CompanyPlan.premium:
        return 'プレミアム';
      case CompanyPlan.enterprise:
        return 'エンタープライズ';
    }
  }
  
  String get description {
    switch (this) {
      case CompanyPlan.basic:
        return '小規模事業者向け（～50名）';
      case CompanyPlan.premium:
        return '中規模事業者向け（～200名）';
      case CompanyPlan.enterprise:
        return '大規模事業者向け（200名～）';
    }
  }
  
  /// 【廃止】プランごとの月額基本料金 → コミュニティ会費制のため基本料金なし
  @Deprecated('コミュニティ会費制では基本料金なし')
  int get basePrice => 0;
  
  /// 【廃止】プランごとの単価 → 人数段階で単価が変わるため
  @Deprecated('人数段階による従量課金を使用')
  int get pricePerDriver => 0;
  
  /// 最大運転者数（null = 無制限）
  int? get maxDrivers {
    switch (this) {
      case CompanyPlan.basic:
        return 50;
      case CompanyPlan.premium:
        return 200;
      case CompanyPlan.enterprise:
        return null; // 無制限
    }
  }
}

/// 会社モデル（マルチテナント対応）
class Company {
  String id;                    // 会社ID（一意）
  String code;                  // 会社コード（例: ABC001）
  String name;                  // 会社名
  CompanyPlan plan;             // 料金プラン
  int maxDriverCount;           // 契約運転者数
  bool isActive;                // 有効/無効
  DateTime createdAt;           // 作成日時
  DateTime? contractStartDate;  // 契約開始日
  DateTime? contractEndDate;    // 契約終了日
  String contactEmail;          // 連絡先メールアドレス
  String contactPhone;          // 連絡先電話番号
  String? logoUrl;              // ロゴ画像URL
  Map<String, dynamic>? metadata; // その他のメタデータ

  Company({
    this.id = '',
    required this.code,
    required this.name,
    this.plan = CompanyPlan.basic,
    this.maxDriverCount = 10,
    this.isActive = true,
    DateTime? createdAt,
    this.contractStartDate,
    this.contractEndDate,
    this.contactEmail = '',
    this.contactPhone = '',
    this.logoUrl,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 月額料金を計算（人数段階による従量課金）
  /// 
  /// 料金体系：
  /// - 1～30人: 5,000円/人・月
  /// - 31～50人: 4,850円/人・月
  /// - 51人以上: 未定（後で追加予定）
  int calculateMonthlyFee() {
    if (maxDriverCount <= 0) return 0;
    
    if (maxDriverCount <= 30) {
      // 1～30人: 5,000円/人
      return maxDriverCount * 5000;
    } else if (maxDriverCount <= 50) {
      // 31～50人: 4,850円/人
      return maxDriverCount * 4850;
    } else {
      // 51人以上: 暫定で4,850円（後で変更可能）
      return maxDriverCount * 4850;
    }
  }
  
  /// 1人あたりの月額単価を取得
  int getPricePerDriver() {
    if (maxDriverCount <= 30) {
      return 5000;
    } else if (maxDriverCount <= 50) {
      return 4850;
    } else {
      return 4850; // 暫定
    }
  }
  
  /// 契約が有効かどうか
  bool get isContractValid {
    if (!isActive) return false;
    if (contractEndDate == null) return true;
    return DateTime.now().isBefore(contractEndDate!);
  }
  
  /// プラン上限チェック
  bool canAddDriver(int currentDriverCount) {
    final maxLimit = plan.maxDrivers;
    if (maxLimit == null) return true; // 無制限
    return currentDriverCount < maxDriverCount && currentDriverCount < maxLimit;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'plan': plan.name,
      'maxDriverCount': maxDriverCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'contractStartDate': contractStartDate != null 
          ? Timestamp.fromDate(contractStartDate!) 
          : null,
      'contractEndDate': contractEndDate != null 
          ? Timestamp.fromDate(contractEndDate!) 
          : null,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'logoUrl': logoUrl,
      'metadata': metadata,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json, String documentId) {
    return Company(
      id: documentId,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      plan: CompanyPlan.values.firstWhere(
        (p) => p.name == json['plan'],
        orElse: () => CompanyPlan.basic,
      ),
      maxDriverCount: json['maxDriverCount'] ?? 10,
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contractStartDate: (json['contractStartDate'] as Timestamp?)?.toDate(),
      contractEndDate: (json['contractEndDate'] as Timestamp?)?.toDate(),
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      logoUrl: json['logoUrl'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Company copyWith({
    String? id,
    String? code,
    String? name,
    CompanyPlan? plan,
    int? maxDriverCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contactEmail,
    String? contactPhone,
    String? logoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Company(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      plan: plan ?? this.plan,
      maxDriverCount: maxDriverCount ?? this.maxDriverCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      logoUrl: logoUrl ?? this.logoUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
