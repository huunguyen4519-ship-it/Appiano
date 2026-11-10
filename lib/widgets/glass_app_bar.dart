import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Thanh tiêu đề có nền mờ đậm. Nội dung cuộn bên dưới không đè lên chữ.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;

  const GlassAppBar({super.key, required this.title, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}
