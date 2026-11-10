import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/settings_store.dart';

/// Khung kính lỏng kiểu iOS: làm mờ phía sau, viền sáng lệch góc, vệt phản chiếu trên đỉnh.
/// Đây là xấp xỉ bằng blur và gradient, chưa có khúc xạ thật (cần shader riêng).
/// Khi tắt hiệu ứng mờ trong Cài đặt, khung vẫn có viền và đổ bóng nhưng không làm mờ nền.
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
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsStore.instance.blurOn,
      builder: (context, blur, _) {
        final content = Padding(padding: padding, child: child);
        final painted = CustomPaint(
          painter: _GlassPainter(radius: radius, frosted: blur),
          child: content,
        );
        final body = RepaintBoundary(
          child: Container(
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
              child: blur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: painted,
                    )
                  : painted,
            ),
          ),
        );
        if (onTap == null) return body;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: body,
        );
      },
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double radius;
  final bool frosted;
  const _GlassPainter({required this.radius, required this.frosted});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Khi không mờ, thêm một lớp tối để chữ vẫn đọc được trên nền sáng.
    if (!frosted) {
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }

    // Lớp kính: sáng dần từ trên xuống.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: frosted ? 0.18 : 0.12),
            Colors.white.withValues(alpha: frosted ? 0.05 : 0.02),
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
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.radius != radius || old.frosted != frosted;
}
