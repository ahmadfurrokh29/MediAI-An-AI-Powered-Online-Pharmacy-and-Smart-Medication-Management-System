import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';

class UpdateAdminPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> admin;

  const UpdateAdminPage({super.key, required this.onBack, required this.admin});

  @override
  State<UpdateAdminPage> createState() => _UpdateAdminPageState();
}

class _UpdateAdminPageState extends State<UpdateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late bool isActive;

  // Password change
  final _passwordFormKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
      text: widget.admin['firstName'],
    );
    lastNameController = TextEditingController(text: widget.admin['lastName']);
    phoneController = TextEditingController(
      text: widget.admin['phoneNumber'] ?? '',
    );
    isActive = widget.admin['isActive'] ?? true;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = AdminController.instance;
    final success = await controller.updateAdmin(
      id: widget.admin['id'],
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      phoneNumber: phoneController.text,
      isActive: isActive,
    );

    if (success && mounted) {
      widget.onBack();
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4299E1), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            InkWell(
              onTap: widget.onBack,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                  SizedBox(width: 8),
                  Text(
                    'Update Admin',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Admin Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Editing: ${widget.admin['email'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // First Name & Last Name row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Color(0xFF4A5568),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'First name',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: firstNameController,
                                  decoration: _inputDecoration('First name'),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Please enter first name'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Color(0xFF4A5568),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Last name',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: lastNameController,
                                  decoration: _inputDecoration('Last name'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Phone number
                      const Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: Color(0xFF4A5568),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Phone number (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Phone number'),
                      ),
                      const SizedBox(height: 24),

                      // Status
                      Row(
                        children: [
                          const Icon(
                            Icons.toggle_on_outlined,
                            size: 20,
                            color: Color(0xFF4A5568),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Switch(
                            value: isActive,
                            activeColor: const Color(0xFF48BB78),
                            onChanged: (val) => setState(() => isActive = val),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF48BB78)
                                  : const Color(0xFFE53E3E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Update button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4299E1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Update Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ════════════════════════════════════════════
            // ── Change Password Section ──
            // ════════════════════════════════════════════
            const SizedBox(height: 32),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 22,
                            color: Color(0xFF4A5568),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the current password to verify identity, then set a new password.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Current password
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Color(0xFF4A5568),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: !_showCurrentPassword,
                        decoration: _inputDecoration('Enter current password')
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFA0AEC0),
                                ),
                                onPressed: () => setState(
                                  () => _showCurrentPassword =
                                      !_showCurrentPassword,
                                ),
                              ),
                            ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter the current password'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // New password & Confirm row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lock_reset,
                                      size: 20,
                                      color: Color(0xFF4A5568),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'New Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: newPasswordController,
                                  obscureText: !_showNewPassword,
                                  decoration:
                                      _inputDecoration(
                                        'Enter new password',
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showNewPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xFFA0AEC0),
                                          ),
                                          onPressed: () => setState(
                                            () => _showNewPassword =
                                                !_showNewPassword,
                                          ),
                                        ),
                                      ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter a new password';
                                    }
                                    if (v.length < 6) {
                                      return 'Minimum 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lock_reset,
                                      size: 20,
                                      color: Color(0xFF4A5568),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Confirm New Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  decoration:
                                      _inputDecoration(
                                        'Re-enter new password',
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xFFA0AEC0),
                                          ),
                                          onPressed: () => setState(
                                            () => _showConfirmPassword =
                                                !_showConfirmPassword,
                                          ),
                                        ),
                                      ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm the new password';
                                    }
                                    if (v != newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Change password button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isChangingPassword
                              ? null
                              : _submitPasswordChange,
                          icon: _isChangingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.lock_reset),
                          label: Text(
                            _isChangingPassword
                                ? 'Changing...'
                                : 'Change Password',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFED8936),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPasswordChange() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    final controller = AdminController.instance;
    final success = await controller.changeAdminPassword(
      adminId: widget.admin['id'],
      email: widget.admin['email'] ?? '',
      currentPassword: currentPasswordController.text,
      newPassword: newPasswordController.text,
    );

    if (mounted) {
      setState(() => _isChangingPassword = false);
    }

    if (success && mounted) {
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
  }
}
