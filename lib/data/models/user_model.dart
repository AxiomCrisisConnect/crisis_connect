import 'package:equatable/equatable.dart';

enum UserRole { volunteer, civilian }

/// How the user authenticated — determines credential flow.
enum UserAuthProvider { email, google }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber; // optional — user may add later in profile
  final UserRole role;
  final UserAuthProvider authProvider;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.authProvider,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String?,
      role: map['role'] == 'volunteer' ? UserRole.volunteer : UserRole.civilian,
      authProvider: (map['auth_provider'] as String?) == 'google'
          ? UserAuthProvider.google
          : UserAuthProvider.email,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'role': role == UserRole.volunteer ? 'volunteer' : 'civilian',
      'auth_provider': authProvider == UserAuthProvider.google ? 'google' : 'email',
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    UserAuthProvider? authProvider,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, phoneNumber, role, authProvider, createdAt];
}
