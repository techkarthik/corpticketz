class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int? branchId;
  final int? departmentId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.branchId,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      email: json['email'],
      fullName: json['full_name'] ?? '',
      role: json['role'],
      branchId: json['branch_id'] != null ? int.tryParse(json['branch_id'].toString()) : null,
      departmentId: json['department_id'] != null ? int.tryParse(json['department_id'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'branch_id': branchId,
      'department_id': departmentId,
    };
  }
}
