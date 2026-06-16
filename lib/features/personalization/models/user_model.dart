import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:med/utils/formatters/formatter.dart';

/// Model class representing user data.
class UserModel {
  // Keep those values final which you do not want to update
  final String id;
  String firstName;
  String lastName;
  final String username;
  final String email;
  String phoneNumber;
  String profilePicture;
  String profilePicturePublicId;
  String gender;
  String dateOfBirth;

  /// Constructor for UserModel.
  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
    this.profilePicturePublicId = '',
    this.gender = '',
    this.dateOfBirth = '',
  });

  /// Helper function to get the full name.
  String get fullName => '$firstName $lastName';

  /// Helper function to format phone number.
  String get formattedPhoneNo => MFormatter.formatPhoneNumber(phoneNumber);

  /// Static function to split full name into first and last name.
  static List<String> nameParts(String fullName) => fullName.split(" ");

  /// Static function to generate a username from the full name.
  static String generateUsername(String fullName) {
    final List<String> parts = fullName.split(" ");
    final String firstName = parts[0].toLowerCase();
    final String lastName = parts.length > 1 ? parts[1].toLowerCase() : "";

    final String camelCaseUsername =
        "$firstName$lastName"; // Combine first and last name
    final String usernameWithPrefix =
        "cwt_$camelCaseUsername"; // Add "cwt_" prefix
    return usernameWithPrefix;
  }

  /// Static function to create an empty user model.
  static UserModel empty() => UserModel(
    id: '',
    firstName: '',
    lastName: '',
    username: '',
    email: '',
    phoneNumber: '',
    profilePicture: '',
    profilePicturePublicId: '',
    gender: '',
    dateOfBirth: '',
  );

  /// Convert model to JSON structure for storing data in Firebase.
  ///
  /// Uses a single, consistent schema that both the MediAI app and the Admin
  /// panel's [CustomerModel.fromSnapshot] can read (it tries both casings).
  ///
  /// Canonical shippingAddress sub-document keys:
  ///   name, phoneNumber, street, postalCode, city, state, country
  Map<String, dynamic> toJson() {
    return {
      // ── Identity (PascalCase — canonical keys for MediAI) ───────────────
      'FirstName': firstName,
      'LastName': lastName,
      'Username': username,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'ProfilePicturePublicId': profilePicturePublicId,
      'Gender': gender,
      'DateOfBirth': dateOfBirth,

      // ── Role & timestamps ────────────────────────────────────────────────
      'role': 'Customer',
      'createdAt': Timestamp.now(),
      'isEmailVerified': false,

      // ── Customer-specific fields ─────────────────────────────────────────
      'points': 0,
      'orderCount': 0,
      // addresses is a list; selectedAddressIndex points to the active one.
      'addresses': <Map<String, dynamic>>[],
      'selectedAddressIndex': 0,
    };
  }

  /// Factory method to create a UserModel from a Firebase document snapshot.
  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return UserModel(
        id: document.id,
        firstName: data['FirstName'] ?? data['firstName'] ?? '',
        lastName: data['LastName'] ?? data['lastName'] ?? '',
        username: data['Username'] ?? data['username'] ?? '',
        email: data['Email'] ?? data['email'] ?? '',
        phoneNumber: data['PhoneNumber'] ?? data['phoneNumber'] ?? '',
        profilePicture: data['ProfilePicture'] ?? '',
        profilePicturePublicId: data['ProfilePicturePublicId'] ?? '',
        gender: data['Gender'] ?? data['gender'] ?? '',
        dateOfBirth: data['DateOfBirth'] ?? data['dateOfBirth'] ?? '',
      );
    } else {
      return UserModel.empty();
    }
  }
}
