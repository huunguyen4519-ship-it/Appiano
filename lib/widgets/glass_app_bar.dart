import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/settings_store.dart';

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
      flexibleSpace: ValueListenableBuilder<bool>(
        valueListenable: SettingsStore.instance.blurOn,
        builder: (context, blur, _) {
          final tint = DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: blur ? 0.30 : 0.55),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          );
          return ClipRect(
            child: blur
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: tint,
                  )
                : tint,
          );
        },
      ),
    );
  }
}
