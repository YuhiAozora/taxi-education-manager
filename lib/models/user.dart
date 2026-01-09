class User {
  String employeeNumber;
  String name;
  String password;
  String role;
  String companyId;
  String email;
  String? phone;
  String? address;
  DateTime? birthDate;
  String? gender;

  User({
    required this.employeeNumber,
    required this.name,
    required this.password,
    required this.role,
    this.companyId = '',
    this.email = '',
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
  });
  
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isCompanyAdmin => role == 'company_admin';
  bool get isDriver => role == 'driver';
  String get id => employeeNumber;
  DateTime get createdAt => DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'employee_number': employeeNumber,
      'employeeNumber': employeeNumber,
      'name': name,
      'password': password,
      'role': role,
      'company_id': companyId,
      'companyId': companyId,
      'email': email,
      'phone': phone,
      'address': address,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      employeeNumber: json['employeeNumber'] ?? json['employee_number'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? (json['isAdmin'] == true ? 'admin' : 'driver'),
      companyId: json['companyId'] ?? json['company_id'] ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      gender: json['gender'] as String?,
    );
  }
}
