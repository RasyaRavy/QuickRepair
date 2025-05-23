class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String role; // Reporter, Technician, Admin
  final DateTime createdAt;
  final DateTime? lastSignIn;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastSignIn,
  });

  // Create from Supabase response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'Reporter', // Default to Reporter
      createdAt: DateTime.parse(json['created_at']),
      lastSignIn: json['last_sign_in'] != null
          ? DateTime.parse(json['last_sign_in'])
          : null,
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
      'last_sign_in': lastSignIn?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? role,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
} 