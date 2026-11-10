import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/settings_store.dart';
import '../../core/theme.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_box.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore.instance;
    return Scaffold(
      appBar: GlassAppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            AppThemeController.instance.accent,
            store.visibleWhites,
            store.labelMode,
            store.haptics,
            store.uiSounds,
            store.blurOn,
          ]),
          builder: (context, _) {
            final accent = AppThemeController.instance.accent.value;
            final visible = store.visibleWhites.value;
            final mode = store.labelMode.value;
            final hue = HSVColor.fromColor(accent).hue;
            final theme = Theme.of(context);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassBox(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Màu chủ đề', style: theme.textTheme.titleMedium),
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
                      Text('Tùy chỉnh màu', style: theme.textTheme.titleMedium),
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
                const SizedBox(height: 12),
                GlassBox(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tên hiển thị trên phím',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<NoteLabelMode>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          selectedBackgroundColor: accent,
                          selectedForegroundColor:
                              ThemeData.estimateBrightnessForColor(accent) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: NoteLabelMode.off,
                            label: Text('Tắt'),
                          ),
                          ButtonSegment(
                            value: NoteLabelMode.letters,
                            label: Text('C4'),
                          ),
                          ButtonSegment(
                            value: NoteLabelMode.numbers,
                            label: Text('123'),
                          ),
                          ButtonSegment(
                            value: NoteLabelMode.solfege,
                            label: Text('Đô Rê'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) {
                          AppFeedback.tap();
                          store.setLabelMode(s.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassBox(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số phím hiển thị: $visible',
                        style: theme.textTheme.titleMedium,
                      ),
                      Slider(
                        value: visible.toDouble(),
                        min: minVisibleWhites.toDouble(),
                        max: maxVisibleWhites.toDouble(),
                        divisions: maxVisibleWhites - minVisibleWhites,
                        label: '$visible',
                        activeColor: accent,
                        onChanged: (v) => store.setVisibleWhites(v.round()),
                      ),
                      Text(
                        'Ít phím thì phím to hơn, dễ bấm. Nhiều phím thì thấy được nhiều nốt hơn.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassBox(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Rung phản hồi'),
                        subtitle: const Text('Rung nhẹ khi chạm phím và khi làm đúng sai'),
                        value: store.haptics.value,
                        onChanged: (v) => store.setHaptics(v),
                      ),
                      SwitchListTile(
                        title: const Text('Âm thanh giao diện'),
                        subtitle: const Text('Tiếng click, tiếng đúng, sai và hoàn thành'),
                        value: store.uiSounds.value,
                        onChanged: (v) => store.setUiSounds(v),
                      ),
                      SwitchListTile(
                        title: const Text('Hiệu ứng kính mờ'),
                        subtitle: const Text(
                          'Tắt nếu máy hay giật khi chuyển màn hình',
                        ),
                        value: store.blurOn.value,
                        onChanged: (v) => store.setBlur(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassBox(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Âm piano: Salamander Grand Piano, tác giả Alexander Holm, '
                    'chỉnh âm Markus Fiedler, tái tạo kinwie. '
                    'Giấy phép CC BY 3.0 (creativecommons.org/licenses/by/3.0).',
                    style: theme.textTheme.bodySmall,
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
      onTap: () {
        AppFeedback.tap();
        AppThemeController.instance.setAccent(color);
      },
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
