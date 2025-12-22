class User {
  String employeeNumber;
  String name;
  String password;
  String role;
  String companyId;  // 所属会社ID（マルチテナント対応）

  User({
    required this.employeeNumber,
    required this.name,
    required this.password,
    required this.role,
    this.companyId = '',  // デフォルト値
  });
  
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';  // スーパー管理者（コミュニティ運営者）
  bool get isCompanyAdmin => role == 'company_admin';  // 会社管理者
  bool get isDriver => role == 'driver';  // 運転者
  String get id => employeeNumber;
  DateTime get createdAt => DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'employee_number': employeeNumber,  // スネークケース（Firebase互換）
      'employeeNumber': employeeNumber,    // キャメルケース（新規）
      'name': name,
      'password': password,
      'role': role,
      'company_id': companyId,  // スネークケース
      'companyId': companyId,   // キャメルケース
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // 両方の形式に対応
      employeeNumber: json['employeeNumber'] ?? json['employee_number'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? (json['isAdmin'] == true ? 'admin' : 'driver'),
      companyId: json['companyId'] ?? json['company_id'] ?? '',
    );
  }
}
