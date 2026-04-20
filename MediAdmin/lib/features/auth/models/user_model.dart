import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String phoneNumber;
  final String profilePicture;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phoneNumber,
    required this.profilePicture,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  static UserModel empty() => UserModel(
    id: '',
    email: '',
    firstName: '',
    lastName: '',
    username: '',
    phoneNumber: '',
    profilePicture: '',
    role: '',
  );

  Map<String, dynamic> toJson() {
    return {
      'Email': email,
      'FirstName': firstName,
      'LastName': lastName,
      'Username': username,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'role': role,
    };
  }

  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return UserModel(
        id: document.id,
        email: data['Email'] ?? '',
        firstName: data['FirstName'] ?? '',
        lastName: data['LastName'] ?? '',
        username: data['Username'] ?? '',
        phoneNumber: data['PhoneNumber'] ?? '',
        profilePicture: data['ProfilePicture'] ?? '',
        role: data['role'] ?? '',
      );
    } else {
      return UserModel.empty();
    }
  }

  bool get isAdmin {
    // Allow admin access if role is admin, or if role is empty/null (backward compatibility)
    final roleCheck = role.toLowerCase();
    return roleCheck == 'admin' ||
        roleCheck == 'super admin' ||
        roleCheck == 'administrator' ||
        role.isEmpty; // Allow empty role for backward compatibility
  }
}
