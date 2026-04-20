import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id; // Firebase Auth UID
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String profilePicture;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Initials for the avatar (max 2 chars)
  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static AdminModel empty() => AdminModel(
    id: '',
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    profilePicture: '',
    role: 'admin',
    isActive: true,
    createdAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'role': role,
      'IsActive': isActive,
      'CreatedAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Also written to the Users collection so the auth check can find the role
  Map<String, dynamic> toUserJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Username': '${firstName.toLowerCase()}.${lastName.toLowerCase()}',
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'role': role,
    };
  }

  factory AdminModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return AdminModel(
      id: document.id,
      firstName: data['FirstName'] ?? '',
      lastName: data['LastName'] ?? '',
      email: data['Email'] ?? '',
      phoneNumber: data['PhoneNumber'] ?? '',
      profilePicture: data['ProfilePicture'] ?? '',
      role: data['role'] ?? 'admin',
      isActive: data['IsActive'] ?? true,
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AdminModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
