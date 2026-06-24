class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String status;
  final bool emailVerified;
  final String role;
  final String? avatar;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
    required this.emailVerified,
    required this.role,
    required this.createdAt,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'inactive',
      emailVerified: json['emailVerified'] ?? false,
      role: json['role'] ?? 'admin', // Default to admin for now if backend doesn't return role
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : DateTime.now(),
    );
  }
}
