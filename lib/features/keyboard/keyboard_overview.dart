import 'package:flutter/material.dart';

/// Nhãn "Thấp" hoặc "Cao" ở hai đầu thanh tổng quan.
class EdgeLabel extends StatelessWidget {
  final String text;
  const EdgeLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: text == 'Thấp' ? TextAlign.left : TextAlign.right,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Thanh tổng quan: toàn bộ phím trắng thu nhỏ, nền chuyển từ xanh (thấp) sang cam (cao).
/// Khung sáng là vùng đang hiển thị. Kéo hoặc chạm để chuyển vùng.
class KeyboardOverview extends StatelessWidget {
  final List<int> whites;
  final double start;
  final int visible;
  final Color accent;
  final ValueChanged<double> onChanged;

  const KeyboardOverview({
    super.key,
    required this.whites,
    required this.start,
    required this.visible,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxWidth / whites.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onChanged(d.localPosition.dx / unit - visible / 2),
          onHorizontalDragUpdate: (d) => onChanged(start + d.delta.dx / unit),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B5BDB),
                        Color(0xFF7B5EA7),
                        Color(0xFFF08C3A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              for (int i = 0; i < whites.length; i++)
                Positioned(
                  left: i * unit + 0.5,
                  top: 6,
                  bottom: 6,
                  width: unit - 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Positioned(
                left: start * unit,
                top: 0,
                bottom: 0,
                width: visible * unit,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.25),
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
