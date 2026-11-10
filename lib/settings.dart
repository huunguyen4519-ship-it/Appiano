import 'package:flutter/material.dart';

import 'ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ValueListenableBuilder<Color>(
          valueListenable: AppThemeController.instance.accent,
          builder: (context, accent, _) {
            final hue = HSVColor.fromColor(accent).hue;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassBox(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Màu chủ đề',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final c in accentPresets)
                            _Swatch(
                              color: c,
                              selected: c.toARGB32() == accent.toARGB32(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tùy chỉnh màu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: hue,
                        min: 0,
                        max: 360,
                        activeColor: accent,
                        onChanged: (h) => AppThemeController.instance.setAccent(
                          HSVColor.fromAHSV(1, h, 0.6, 1).toColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;

  const _Swatch({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppThemeController.instance.setAccent(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          ),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: selected ? 16 : 6,
            ),
          ],
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
