class MValidator {
  /// Empty Text Validation
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    // Regular expression for email validation
    // Allow longer TLDs (e.g. .technology) by using {2,} instead of {2,4}
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    // Check for minimum password length
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    // Check for special characters
    // Allow at least one of common special characters
    if (!value.contains(RegExp(r'[!@#\$%\^&\*(),?":{}|<>\[\]\\\-_/+]'))) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }

    // Normalize: remove spaces, dashes, parentheses and plus sign
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Accept common lengths: 10 (local), 11 (leading 0), 12 (country code + 10),
    // or a reasonable range between 9 and 14 digits for international numbers.
    if (digits.length < 9 || digits.length > 14) {
      return 'Invalid phone number format (expected 9-14 digits).';
    }

    return null;
  }

  //more custom validators.
}
