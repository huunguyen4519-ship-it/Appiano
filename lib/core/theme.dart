import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Các màu chủ đề gợi ý. Người dùng cũng có thể kéo thanh để chọn màu khác.
const List<Color> accentPresets = [
  Color(0xFF7C9CFF),
  Color(0xFF9B7CFF),
  Color(0xFFFF7CB6),
  Color(0xFFFF9F7C),
  Color(0xFF6BE3B5),
  Color(0xFF5EE7FF),
  Color(0xFFFFD86B),
  Color(0xFFFF6F61), // san hô
  Color(0xFFE53950), // đỏ thẫm
  Color(0xFFA6E22E), // xanh chanh
  Color(0xFF26A69A), // xanh cổ vịt
  Color(0xFF4FC3F7), // xanh da trời
  Color(0xFFE040FB), // hồng tím
  Color(0xFFFFB300), // hổ phách
  Color(0xFF5C6BC0), // chàm
  Color(0xFFE8A598), // hồng đất
  Color(0xFF26C6DA), // ngọc lam
];

/// Giữ màu chủ đề hiện tại và lưu lại trên máy.
class AppThemeController {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();
  static const _key = 'accent_argb';

  final ValueNotifier<Color> accent = ValueNotifier<Color>(accentPresets.first);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_key);
      if (value != null) accent.value = Color(value);
    } catch (_) {}
  }

  Future<void> setAccent(Color color) async {
    accent.value = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, color.toARGB32());
    } catch (_) {}
  }
}

ThemeData buildTheme(Color accent) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// Nền tối có hai quầng màu mờ theo màu chủ đề, tạo cảm giác chất lỏng.
class LiquidBackground extends StatelessWidget {
  final Widget child;
  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppThemeController.instance.accent,
      builder: (context, accent, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF0B0B12), accent, 0.22)!,
                      const Color(0xFF060609),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -140,
              left: -90,
              child: _Blob(color: accent, size: 340),
            ),
            Positioned(
              bottom: -160,
              right: -80,
              child: _Blob(
                color: Color.lerp(accent, Colors.white, 0.2)!,
                size: 380,
              ),
            ),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
