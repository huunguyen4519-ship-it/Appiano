import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Thanh tiêu đề kính mờ. Nội dung cuộn bên dưới bị làm mờ, không đè lên chữ.
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
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
