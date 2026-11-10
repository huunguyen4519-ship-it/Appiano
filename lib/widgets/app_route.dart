import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Chuyển màn hình dùng chung: trang mới trượt từ dưới lên và che hoàn toàn trang cũ.
/// Không mờ dần, nên hai trang không bao giờ chồng lên nhau trong lúc chuyển.
Route<T> appRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        // Bọc nền đặc để trang mới che kín trang cũ trong lúc trượt.
        child: LiquidBackground(child: child),
      );
    },
  );
}
