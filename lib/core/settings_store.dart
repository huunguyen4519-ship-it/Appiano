import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiểu tên hiển thị trên phím.
enum NoteLabelMode { off, letters, numbers, solfege }

const int minVisibleWhites = 7;
const int maxVisibleWhites = 24;

int _clampVisible(int v) {
  if (v < minVisibleWhites) return minVisibleWhites;
  if (v > maxVisibleWhites) return maxVisibleWhites;
  return v;
}

/// Mọi cài đặt của người dùng. Lưu trên máy và tự thông báo khi thay đổi.
class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _visibleKey = 'visible_whites';
  static const _labelKey = 'label_mode';
  static const _hapticKey = 'haptics_on';
  static const _soundKey = 'ui_sounds_on';
  static const _blurKey = 'blur_on';

  /// Tên 5 dải tần của bộ chỉnh âm.
  static const List<String> eqLabels = ['60 Hz', '250 Hz', '1 kHz', '4 kHz', '12 kHz'];

  /// Số phím trắng hiển thị cùng lúc.
  final ValueNotifier<int> visibleWhites = ValueNotifier<int>(10);

  /// Kiểu tên phím.
  final ValueNotifier<NoteLabelMode> labelMode =
      ValueNotifier<NoteLabelMode>(NoteLabelMode.letters);

  /// Rung nhẹ khi chạm phím và khi làm đúng sai.
  final ValueNotifier<bool> haptics = ValueNotifier<bool>(true);

  /// Âm thanh giao diện (click, đúng, sai, hoàn thành).
  final ValueNotifier<bool> uiSounds = ValueNotifier<bool>(true);

  /// Hiệu ứng kính mờ. Tắt thì khung kính đặc hơn, máy yếu sẽ mượt hơn khi chuyển màn.
  final ValueNotifier<bool> blurOn = ValueNotifier<bool>(true);

  /// Độ tăng giảm (dB) của 5 dải tần, từ -12 đến +12.
  final List<ValueNotifier<double>> eqGains =
      List.generate(5, (_) => ValueNotifier<double>(0));

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_visibleKey);
      if (v != null) visibleWhites.value = _clampVisible(v);
      final m = prefs.getInt(_labelKey);
      if (m != null && m >= 0 && m < NoteLabelMode.values.length) {
        labelMode.value = NoteLabelMode.values[m];
      }
      haptics.value = prefs.getBool(_hapticKey) ?? true;
      uiSounds.value = prefs.getBool(_soundKey) ?? true;
      blurOn.value = prefs.getBool(_blurKey) ?? true;
      for (var i = 0; i < eqGains.length; i++) {
        eqGains[i].value = prefs.getDouble('eq_$i') ?? 0;
      }
    } catch (_) {}
  }

  Future<void> setVisibleWhites(int value) async {
    visibleWhites.value = _clampVisible(value);
    await _write((p) => p.setInt(_visibleKey, visibleWhites.value));
  }

  Future<void> setLabelMode(NoteLabelMode mode) async {
    labelMode.value = mode;
    await _write((p) => p.setInt(_labelKey, mode.index));
  }

  Future<void> setHaptics(bool on) async {
    haptics.value = on;
    await _write((p) => p.setBool(_hapticKey, on));
  }

  Future<void> setUiSounds(bool on) async {
    uiSounds.value = on;
    await _write((p) => p.setBool(_soundKey, on));
  }

  Future<void> setBlur(bool on) async {
    blurOn.value = on;
    await _write((p) => p.setBool(_blurKey, on));
  }

  Future<void> setEqGain(int band, double db) async {
    eqGains[band].value = db;
    await _write((p) => p.setDouble('eq_$band', db));
  }

  Future<void> resetEq() async {
    for (var i = 0; i < eqGains.length; i++) {
      await setEqGain(i, 0);
    }
  }

  Future<void> _write(Future<bool> Function(SharedPreferences) op) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await op(prefs);
    } catch (_) {}
  }
}
