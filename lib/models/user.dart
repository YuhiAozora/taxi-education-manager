class User {
  String id;
  String name;
  String employeeNumber;
  String password;
  bool isAdmin;
  DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.employeeNumber,
    required this.password,
    this.isAdmin = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeNumber': employeeNumber,
      'password': password,  // パスワードを保存
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      employeeNumber: json['employeeNumber'],
      password: json['password'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
