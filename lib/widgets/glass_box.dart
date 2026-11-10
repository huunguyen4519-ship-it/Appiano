import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Khung kính lỏng kiểu iOS: làm mờ mạnh phía sau, viền sáng lệch góc, vệt phản chiếu trên đỉnh.
/// Đây là xấp xỉ bằng blur và gradient, chưa có khúc xạ thật (cần shader riêng).
class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final body = Container(
      // Bóng nằm ngoài ClipRRect để không bị cắt.
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: CustomPaint(
            painter: _GlassPainter(radius: radius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
    if (onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double radius;
  const _GlassPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Lớp kính: sáng dần từ trên xuống.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );

    // Vệt phản chiếu sáng ở nửa trên, giống mặt kính cong.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    // Viền sáng: đậm ở góc trên trái, mờ dần về góc dưới phải.
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.3),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) => old.radius != radius;
}
