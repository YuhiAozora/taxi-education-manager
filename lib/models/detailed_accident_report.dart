import 'package:cloud_firestore/cloud_firestore.dart';

/// 詳細自動車事故調書（添付画像の形式を完全再現）
class DetailedAccidentReport {
  final String id;
  
  // 作成日
  final DateTime createdDate;
  
  // 事故発生日時
  final DateTime accidentDate;
  final bool isAm; // 午前/午後
  
  // 事故発生場所
  final String accidentLocation;
  
  // 車両登録番号
  final String vehicleRegistrationNumber;
  
  // 運転者情報
  final String driverName;
  final String driverAddress;
  final DateTime driverBirthDate;
  final String driverGender; // 'male' or 'female'
  final String driverLicenseNumber;
  
  // 負傷の有無
  final bool isDriverInjured;
  final DateTime? injuryTreatmentDate;
  final String? injuredPersonName;
  final String? hospitalName;
  final String? hospitalTel;
  
  // 事故相手情報
  final String? opponentName;
  final String? opponentGender;
  final String? opponentTel;
  final String? opponentCompany;
  final String? opponentCompanyTel;
  final String? opponentAddress;
  final String? opponentVehicleNumber;
  
  // 相手の負傷情報
  final bool isOpponentInjured;
  final String? opponentInjuredName;
  final String? opponentInjuredTel;
  final String? opponentInjuredAddress;
  final String? opponentHospitalName;
  
  // 自転車・歩行者との事故
  final bool isBicycleOrPedestrian;
  final String? pedestrianName;
  final String? pedestrianTel;
  final String? pedestrianAddress;
  final String? pedestrianHospitalName;
  
  // 事故状況の図と説明
  final String accidentDiagram; // テキスト形式の図
  final String accidentDescription;
  
  // 破損箇所
  final List<String> ownVehicleDamage; // 自車の破損部位
  final List<String> opponentVehicleDamage; // 相手車の破損部位
  
  // その他備考
  final String? additionalNotes;
  
  // 報告者情報
  final String reporterId; // 社員番号
  final String reporterName;
  final String companyId;
  final String companyName;
  
  // 保険会社FAX送信日
  final DateTime? insuranceFaxDate;
  
  // 管理者確認
  final String? adminComment;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  
  DetailedAccidentReport({
    required this.id,
    required this.createdDate,
    required this.accidentDate,
    required this.isAm,
    required this.accidentLocation,
    required this.vehicleRegistrationNumber,
    required this.driverName,
    required this.driverAddress,
    required this.driverBirthDate,
    required this.driverGender,
    required this.driverLicenseNumber,
    required this.isDriverInjured,
    this.injuryTreatmentDate,
    this.injuredPersonName,
    this.hospitalName,
    this.hospitalTel,
    this.opponentName,
    this.opponentGender,
    this.opponentTel,
    this.opponentCompany,
    this.opponentCompanyTel,
    this.opponentAddress,
    this.opponentVehicleNumber,
    required this.isOpponentInjured,
    this.opponentInjuredName,
    this.opponentInjuredTel,
    this.opponentInjuredAddress,
    this.opponentHospitalName,
    required this.isBicycleOrPedestrian,
    this.pedestrianName,
    this.pedestrianTel,
    this.pedestrianAddress,
    this.pedestrianHospitalName,
    required this.accidentDiagram,
    required this.accidentDescription,
    required this.ownVehicleDamage,
    required this.opponentVehicleDamage,
    this.additionalNotes,
    required this.reporterId,
    required this.reporterName,
    required this.companyId,
    required this.companyName,
    this.insuranceFaxDate,
    this.adminComment,
    this.verifiedAt,
    this.verifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'createdDate': Timestamp.fromDate(createdDate),
      'accidentDate': Timestamp.fromDate(accidentDate),
      'isAm': isAm,
      'accidentLocation': accidentLocation,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'driverName': driverName,
      'driverAddress': driverAddress,
      'driverBirthDate': Timestamp.fromDate(driverBirthDate),
      'driverGender': driverGender,
      'driverLicenseNumber': driverLicenseNumber,
      'isDriverInjured': isDriverInjured,
      'injuryTreatmentDate': injuryTreatmentDate != null 
          ? Timestamp.fromDate(injuryTreatmentDate!) 
          : null,
      'injuredPersonName': injuredPersonName,
      'hospitalName': hospitalName,
      'hospitalTel': hospitalTel,
      'opponentName': opponentName,
      'opponentGender': opponentGender,
      'opponentTel': opponentTel,
      'opponentCompany': opponentCompany,
      'opponentCompanyTel': opponentCompanyTel,
      'opponentAddress': opponentAddress,
      'opponentVehicleNumber': opponentVehicleNumber,
      'isOpponentInjured': isOpponentInjured,
      'opponentInjuredName': opponentInjuredName,
      'opponentInjuredTel': opponentInjuredTel,
      'opponentInjuredAddress': opponentInjuredAddress,
      'opponentHospitalName': opponentHospitalName,
      'isBicycleOrPedestrian': isBicycleOrPedestrian,
      'pedestrianName': pedestrianName,
      'pedestrianTel': pedestrianTel,
      'pedestrianAddress': pedestrianAddress,
      'pedestrianHospitalName': pedestrianHospitalName,
      'accidentDiagram': accidentDiagram,
      'accidentDescription': accidentDescription,
      'ownVehicleDamage': ownVehicleDamage,
      'opponentVehicleDamage': opponentVehicleDamage,
      'additionalNotes': additionalNotes,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'companyId': companyId,
      'companyName': companyName,
      'insuranceFaxDate': insuranceFaxDate != null 
          ? Timestamp.fromDate(insuranceFaxDate!) 
          : null,
      'adminComment': adminComment,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }

  factory DetailedAccidentReport.fromJson(Map<String, dynamic> json, String id) {
    return DetailedAccidentReport(
      id: id,
      createdDate: (json['createdDate'] as Timestamp).toDate(),
      accidentDate: (json['accidentDate'] as Timestamp).toDate(),
      isAm: json['isAm'] as bool,
      accidentLocation: json['accidentLocation'] as String,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
      driverName: json['driverName'] as String,
      driverAddress: json['driverAddress'] as String,
      driverBirthDate: (json['driverBirthDate'] as Timestamp).toDate(),
      driverGender: json['driverGender'] as String,
      driverLicenseNumber: json['driverLicenseNumber'] as String,
      isDriverInjured: json['isDriverInjured'] as bool,
      injuryTreatmentDate: json['injuryTreatmentDate'] != null
          ? (json['injuryTreatmentDate'] as Timestamp).toDate()
          : null,
      injuredPersonName: json['injuredPersonName'] as String?,
      hospitalName: json['hospitalName'] as String?,
      hospitalTel: json['hospitalTel'] as String?,
      opponentName: json['opponentName'] as String?,
      opponentGender: json['opponentGender'] as String?,
      opponentTel: json['opponentTel'] as String?,
      opponentCompany: json['opponentCompany'] as String?,
      opponentCompanyTel: json['opponentCompanyTel'] as String?,
      opponentAddress: json['opponentAddress'] as String?,
      opponentVehicleNumber: json['opponentVehicleNumber'] as String?,
      isOpponentInjured: json['isOpponentInjured'] as bool,
      opponentInjuredName: json['opponentInjuredName'] as String?,
      opponentInjuredTel: json['opponentInjuredTel'] as String?,
      opponentInjuredAddress: json['opponentInjuredAddress'] as String?,
      opponentHospitalName: json['opponentHospitalName'] as String?,
      isBicycleOrPedestrian: json['isBicycleOrPedestrian'] as bool,
      pedestrianName: json['pedestrianName'] as String?,
      pedestrianTel: json['pedestrianTel'] as String?,
      pedestrianAddress: json['pedestrianAddress'] as String?,
      pedestrianHospitalName: json['pedestrianHospitalName'] as String?,
      accidentDiagram: json['accidentDiagram'] as String,
      accidentDescription: json['accidentDescription'] as String,
      ownVehicleDamage: List<String>.from(json['ownVehicleDamage'] as List),
      opponentVehicleDamage: List<String>.from(json['opponentVehicleDamage'] as List),
      additionalNotes: json['additionalNotes'] as String?,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      insuranceFaxDate: json['insuranceFaxDate'] != null
          ? (json['insuranceFaxDate'] as Timestamp).toDate()
          : null,
      adminComment: json['adminComment'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? (json['verifiedAt'] as Timestamp).toDate()
          : null,
      verifiedBy: json['verifiedBy'] as String?,
    );
  }
}
