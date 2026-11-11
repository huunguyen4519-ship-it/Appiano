import 'package:flutter/material.dart';

import '../../core/settings_store.dart';

/// Bộ chỉnh âm 5 dải dùng chung cho Cài đặt và bảng nhanh trên màn chơi đàn.
class EqPanel extends StatelessWidget {
  final Color accent;
  final double bandHeight;
  final bool showNote;

  const EqPanel({
    super.key,
    required this.accent,
    this.bandHeight = 200,
    this.showNote = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Bộ chỉnh âm', style: theme.textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () => SettingsStore.instance.resetEq(),
              child: const Text('Phẳng'),
            ),
          ],
        ),
        SizedBox(
          height: bandHeight,
          child: Row(
            children: [
              for (var i = 0; i < SettingsStore.eqLabels.length; i++)
                Expanded(
                  child: _EqBand(
                    index: i,
                    label: SettingsStore.eqLabels[i],
                    accent: accent,
                  ),
                ),
            ],
          ),
        ),
        if (showNote) ...[
          const SizedBox(height: 8),
          Text(
            'Thanh trượt đã được lưu. Âm thanh chưa đổi theo bộ chỉnh âm, phần này sẽ nối vào ở bước sau.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Một dải của bộ chỉnh âm: thanh trượt dọc, hiển thị dB và tên dải.
class _EqBand extends StatelessWidget {
  final int index;
  final String label;
  final Color accent;

  const _EqBand({
    required this.index,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore.instance;
    return ValueListenableBuilder<double>(
      valueListenable: store.eqGains[index],
      builder: (context, db, _) {
        final sign = db > 0 ? '+' : '';
        return Column(
          children: [
            Text('$sign${db.round()} dB', style: const TextStyle(fontSize: 11)),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  min: -12,
                  max: 12,
                  value: db,
                  activeColor: accent,
                  onChanged: (v) => store.setEqGain(index, v),
                ),
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        );
      },
    );
  }
}
