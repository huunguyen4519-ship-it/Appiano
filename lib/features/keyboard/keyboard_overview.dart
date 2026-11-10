import 'package:flutter/material.dart';

/// Nhãn "Thấp" hoặc "Cao" ở hai đầu thanh tổng quan. Cùng chiều rộng để thanh cân đối.
class EdgeLabel extends StatelessWidget {
  final String text;
  const EdgeLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Thanh tổng quan kiểu kính: toàn bộ phím trắng thu nhỏ trên dải màu xanh (thấp) -> cam (cao).
/// Khung sáng phát màu chủ đề là vùng đang hiển thị.
/// Kéo khung thì khung bám theo ngón tay. Chạm một chỗ thì khung nhảy tới chỗ đó.
class KeyboardOverview extends StatefulWidget {
  final List<int> whites;
  final double start;
  final int visible;
  final Color accent;

  /// Chạm vào thanh: vị trí chạm tính theo đơn vị phím trắng.
  final ValueChanged<double> onTap;

  /// Kéo khung: vị trí mới của khung, cũng tính theo đơn vị phím trắng.
  final ValueChanged<double> onDrag;

  const KeyboardOverview({
    super.key,
    required this.whites,
    required this.start,
    required this.visible,
    required this.accent,
    required this.onTap,
    required this.onDrag,
  });

  @override
  State<KeyboardOverview> createState() => _KeyboardOverviewState();
}

class _KeyboardOverviewState extends State<KeyboardOverview> {
  // Khoảng cách từ ngón tay tới mép trái khung lúc bắt đầu kéo.
  double _grab = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxWidth / widget.whites.length;
        double posOf(Offset p) => p.dx / unit;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Dùng onTapUp để khi đang kéo thì không nhảy khung.
          onTapUp: (d) => widget.onTap(posOf(d.localPosition)),
          onHorizontalDragStart: (d) =>
              _grab = posOf(d.localPosition) - widget.start,
          onHorizontalDragUpdate: (d) =>
              widget.onDrag(posOf(d.localPosition) - _grab),
          child: CustomPaint(
            size: Size.infinite,
            painter: _OverviewPainter(
              whiteCount: widget.whites.length,
              start: widget.start,
              visible: widget.visible,
              accent: widget.accent,
            ),
          ),
        );
      },
    );
  }
}

class _OverviewPainter extends CustomPainter {
  final int whiteCount;
  final double start;
  final int visible;
  final Color accent;

  const _OverviewPainter({
    required this.whiteCount,
    required this.start,
    required this.visible,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / whiteCount;
    final bounds = Offset.zero & size;

    // Dải màu nửa trong suốt: xanh (thấp) -> tím -> cam (cao).
    final track = RRect.fromRectAndRadius(
      bounds.deflate(1),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x993B5BDB), Color(0x997B5EA7), Color(0x99F08C3A)],
        ).createShader(bounds),
    );
    // Vệt sáng trên đỉnh dải, cho cảm giác kính.
    canvas.drawRRect(
      track,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    // Vạch từng phím trắng, mảnh và mờ.
    final tick = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (int i = 0; i < whiteCount; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * unit + unit * 0.25,
            size.height * 0.22,
            unit * 0.5,
            size.height * 0.56,
          ),
          const Radius.circular(1),
        ),
        tick,
      );
    }

    // Khung vùng đang hiển thị: nền màu chủ đề, viền phát sáng.
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(start * unit + 1, 1, visible * unit - 2, size.height - 2),
      const Radius.circular(10),
    );
    canvas.drawRRect(window, Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _OverviewPainter old) =>
      old.start != start ||
      old.visible != visible ||
      old.accent != accent ||
      old.whiteCount != whiteCount;
}
