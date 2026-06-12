import 'package:flutter/material.dart';

class LoginIllustrationSection extends StatelessWidget {
  const LoginIllustrationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 60, 221, 87),
            Color.fromARGB(255, 50, 218, 62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Image.asset(
                'assets/images/login_illustration.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              "Powered by MediAI",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
