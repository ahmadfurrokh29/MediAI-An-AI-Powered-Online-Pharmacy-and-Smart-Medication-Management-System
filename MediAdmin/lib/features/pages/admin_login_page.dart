import 'package:flutter/material.dart';
import '../widgets/login_illustration_section.dart';
import '../widgets/admin_login_form.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showIllustration = width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (showIllustration)
            const Expanded(flex: 1, child: LoginIllustrationSection()),
          const Expanded(flex: 1, child: AdminLoginForm()),
        ],
      ),
    );
  }
}
