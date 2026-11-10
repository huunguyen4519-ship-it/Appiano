import 'package:flutter/material.dart';

import 'keyboard_palette.dart';

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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Thanh tổng quan đơn sắc: các phím trắng thu nhỏ màu xám.
/// Khung đang xem được làm sáng để nổi bật. Kéo hoặc chạm để chuyển vùng.
class KeyboardOverview extends StatelessWidget {
  final List<int> whites;
  final double start;
  final int visible;
  final KeyboardPalette palette;
  final Color accent;
  final ValueChanged<double> onChanged;

  const KeyboardOverview({
    super.key,
    required this.whites,
    required this.start,
    required this.visible,
    required this.palette,
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
                    color: palette.overviewTrack,
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
                      color: palette.overviewKey,
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
                    color: palette.overviewWindow,
                    border: Border.all(
                      color: palette.overviewWindowBorder ?? accent,
                      width: 1.5,
                    ),
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
