import 'package:flutter/material.dart';

/// Brand-accurate logo widgets for each payment method.
/// Built entirely with Flutter primitives — no external image assets required.

// ── Card (generic bank card) ──────────────────────────────────────────────
// Clean design using CustomPaint — zero overflow risk.

class CardLogo extends StatelessWidget {
  const CardLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Fixed aspect ratio 1.58:1 (standard credit card ratio)
    final w = size;
    final h = (size / 1.58).roundToDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: CustomPaint(size: Size(w, h), painter: _CardPainter()),
    );
  }
}

class _CardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Gold EMV chip
    final chipPaint = Paint()..color = const Color(0xFFFFD54F);
    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.20, w * 0.28, h * 0.32),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(chipRect, chipPaint);

    // Chip vertical line
    final linePaint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(w * 0.08 + (w * 0.28 / 2), h * 0.20),
      Offset(w * 0.08 + (w * 0.28 / 2), h * 0.52),
      linePaint,
    );

    // Four groups of dots (card number)
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final dotR = w * 0.028;
    final dotY = h * 0.76;
    const groups = 4;
    const dotsPerGroup = 4;
    final totalWidth =
        groups * dotsPerGroup * (dotR * 2 + 1.5) + (groups - 1) * (dotR * 3);
    var x = (w - totalWidth) / 2;
    for (int g = 0; g < groups; g++) {
      for (int d = 0; d < dotsPerGroup; d++) {
        canvas.drawCircle(Offset(x + dotR, dotY), dotR, dotPaint);
        x += dotR * 2 + 1.5;
      }
      x += dotR * 3; // gap between groups
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Easypaisa ─────────────────────────────────────────────────────────────
// Official brand: green (#1BA260) wordmark "easypaisa"

class EasypaisaLogo extends StatelessWidget {
  const EasypaisaLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1BA260),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'easy',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'paisa',
              style: TextStyle(
                color: const Color(0xFFFFE082),
                fontSize: size * 0.20,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── JazzCash ──────────────────────────────────────────────────────────────
// Official brand: red (#EE1C25) with "Jazz" in red + orange "Cash"

class JazzCashLogo extends StatelessWidget {
  const JazzCashLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEE1C25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jazz',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.24,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Cash',
              style: TextStyle(
                color: const Color(0xFFFFCC00),
                fontSize: size * 0.21,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Convenience factory ────────────────────────────────────────────────────

class PaymentLogo extends StatelessWidget {
  const PaymentLogo({super.key, required this.type, this.size = 32});

  /// Accepts: 'card', 'easypaisa', 'jazzcash'
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (type.toLowerCase()) {
      case 'easypaisa':
        return EasypaisaLogo(size: size);
      case 'jazzcash':
        return JazzCashLogo(size: size);
      default:
        return CardLogo(size: size);
    }
  }
}
