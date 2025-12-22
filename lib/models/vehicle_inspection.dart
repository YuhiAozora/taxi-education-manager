import 'package:cloud_firestore/cloud_firestore.dart';

/// 整備点検記録
class VehicleInspection {
  final String id;
  final String userId;              // 運転者の社員番号
  final String companyId;           // 所属会社ID
  final DateTime inspectionDate;    // 点検日時
  final Map<String, InspectionItem> items;  // 点検項目（29項目）
  final bool isCompleted;           // 完了フラグ
  final int okCount;                // 良の数
  final int ngCount;                // 否の数
  final DateTime createdAt;

  VehicleInspection({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.inspectionDate,
    required this.items,
    required this.isCompleted,
    required this.okCount,
    required this.ngCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 点検項目のテンプレートを生成
  static Map<String, InspectionItem> createTemplate() {
    return {
      // 運転者席（9項目）
      'driver_fuel': InspectionItem(
        category: '運転者席',
        itemName: '燃料',
        detail: '量・もれ',
        order: 1,
      ),
      'driver_engine': InspectionItem(
        category: '運転者席',
        itemName: 'エンジン',
        detail: 'かかり具合・異音',
        order: 2,
      ),
      'driver_steering': InspectionItem(
        category: '運転者席',
        itemName: 'かじ取りハンドル',
        detail: '遊び・がた・振れ・取られ・重さ',
        order: 3,
      ),
      'driver_clutch': InspectionItem(
        category: '運転者席',
        itemName: 'クラッチ',
        detail: '遊び・作用',
        order: 4,
      ),
      'driver_brake': InspectionItem(
        category: '運転者席',
        itemName: 'ブレーキペダル・ブレーキレバー',
        detail: '踏みしろ・片ぎき・引きしろ・聞き具合',
        order: 5,
      ),
      'driver_horn': InspectionItem(
        category: '運転者席',
        itemName: '警音器・窓ふき器・方向指示器',
        detail: '作用',
        order: 6,
      ),
      'driver_meter': InspectionItem(
        category: '運転者席',
        itemName: '計器・デフロスタ',
        detail: '作用',
        order: 7,
      ),
      'driver_mirror': InspectionItem(
        category: '運転者席',
        itemName: '後写鏡・反射鏡',
        detail: '写影・損傷',
        order: 8,
      ),
      'driver_door': InspectionItem(
        category: '運転者席',
        itemName: 'ドアロック・座席ベルト',
        detail: '正常・損傷・取付具合',
        order: 9,
      ),

      // 前部（12項目）
      'front_clip': InspectionItem(
        category: '前部',
        itemName: 'クリップボルト',
        detail: 'ゆるみ・折損',
        order: 10,
      ),
      'front_light': InspectionItem(
        category: '前部',
        itemName: '前照灯・車内灯・登録番号標',
        detail: '点滅具合・汚れ・損傷',
        order: 11,
      ),
      'front_tire': InspectionItem(
        category: '前部',
        itemName: 'タイヤ',
        detail: '空気圧・摩擦・損傷・亀裂・溝の深さ・異物のはさまり・金属片、石、その他',
        order: 12,
      ),
      'front_radiator': InspectionItem(
        category: '前部',
        itemName: 'ラジエーター',
        detail: '水の量・もれ・装着具合',
        order: 13,
      ),
      'front_radiator_cap': InspectionItem(
        category: '前部',
        itemName: 'ラジエーターキャップ',
        detail: '水の量・もれ・装着具合',
        order: 14,
      ),
      'front_fan_belt': InspectionItem(
        category: '前部',
        itemName: 'ファンベルト',
        detail: '貼り具合・損傷',
        order: 15,
      ),
      'front_oil': InspectionItem(
        category: '前部',
        itemName: 'オイル',
        detail: '量・もれ',
        order: 16,
      ),
      'front_washer': InspectionItem(
        category: '前部',
        itemName: '洗浄噴射装置',
        detail: '量・もれ',
        order: 17,
      ),
      'front_brake_oil': InspectionItem(
        category: '前部',
        itemName: 'ブレーキオイル',
        detail: '液量・もれ',
        order: 18,
      ),
      'front_clutch_oil': InspectionItem(
        category: '前部',
        itemName: 'クラッチオイル',
        detail: '液量・もれ',
        order: 19,
      ),
      'front_spring': InspectionItem(
        category: '前部',
        itemName: 'シャシバネ',
        detail: '折損',
        order: 20,
      ),
      'front_total': InspectionItem(
        category: '前部',
        itemName: '前部総合',
        detail: '',
        order: 21,
      ),

      // 後部（4項目）
      'rear_spare_tire': InspectionItem(
        category: '後部',
        itemName: 'スペアタイヤ',
        detail: '空気圧・摩擦・損傷・亀裂・溝の深さ・異物のはさまり・金属片、石、その他',
        order: 22,
      ),
      'rear_battery': InspectionItem(
        category: '後部',
        itemName: 'バッテリー',
        detail: '液量・ターミナル',
        order: 23,
      ),
      'rear_light': InspectionItem(
        category: '後部',
        itemName: '番号灯・尾灯・制動灯・後退灯・その他灯火',
        detail: '点滅具合・汚れ・損傷',
        order: 24,
      ),
      'rear_total': InspectionItem(
        category: '後部',
        itemName: '後部総合',
        detail: '',
        order: 25,
      ),

      // その他（4項目）
      'other_meter': InspectionItem(
        category: 'その他',
        itemName: 'その他計器',
        detail: '作用',
        order: 26,
      ),
      'other_signal': InspectionItem(
        category: 'その他',
        itemName: '非常信号用具',
        detail: '有・無',
        order: 27,
      ),
      'other_certificate': InspectionItem(
        category: 'その他',
        itemName: '自動車検査証・保険証',
        detail: '有・無',
        order: 28,
      ),
      'other_tool': InspectionItem(
        category: 'その他',
        itemName: '工具',
        detail: '定位置固定の有無',
        order: 29,
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyId': companyId,
      'inspectionDate': Timestamp.fromDate(inspectionDate),
      'items': items.map((key, value) => MapEntry(key, value.toJson())),
      'isCompleted': isCompleted,
      'okCount': okCount,
      'ngCount': ngCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VehicleInspection.fromJson(Map<String, dynamic> json, String id) {
    final itemsData = json['items'] as Map<String, dynamic>? ?? {};
    final items = itemsData.map(
      (key, value) => MapEntry(
        key,
        InspectionItem.fromJson(value as Map<String, dynamic>),
      ),
    );

    return VehicleInspection(
      id: id,
      userId: json['userId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      inspectionDate: (json['inspectionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
      isCompleted: json['isCompleted'] as bool? ?? false,
      okCount: json['okCount'] as int? ?? 0,
      ngCount: json['ngCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 点検項目
class InspectionItem {
  final String category;      // カテゴリ（運転者席/前部/後部/その他）
  final String itemName;      // 項目名
  final String detail;        // 詳細内容
  final int order;            // 表示順
  bool? isOk;                 // 良=true, 否=false, null=未チェック
  String? note;               // 備考（否の場合）

  InspectionItem({
    required this.category,
    required this.itemName,
    required this.detail,
    required this.order,
    this.isOk,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'itemName': itemName,
      'detail': detail,
      'order': order,
      'isOk': isOk,
      'note': note,
    };
  }

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      category: json['category'] as String,
      itemName: json['itemName'] as String,
      detail: json['detail'] as String,
      order: json['order'] as int,
      isOk: json['isOk'] as bool?,
      note: json['note'] as String?,
    );
  }

  InspectionItem copyWith({
    bool? isOk,
    String? note,
  }) {
    return InspectionItem(
      category: category,
      itemName: itemName,
      detail: detail,
      order: order,
      isOk: isOk ?? this.isOk,
      note: note ?? this.note,
    );
  }
}
