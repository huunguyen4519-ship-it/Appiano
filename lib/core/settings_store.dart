import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theory/notation.dart';

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
  static const _notationKey = 'notation_id';
  static const _labelsKey = 'labels_visible';
  static const _hapticKey = 'haptics_on';
  static const _soundKey = 'ui_sounds_on';

  /// Số phím trắng hiển thị cùng lúc.
  final ValueNotifier<int> visibleWhites = ValueNotifier<int>(10);

  /// Cách ký âm hiển thị trên phím.
  final ValueNotifier<NoteNotation> notation =
      ValueNotifier<NoteNotation>(notationChoices.first);

  /// Có hiện nhãn trên phím không.
  final ValueNotifier<bool> labelsVisible = ValueNotifier<bool>(true);

  /// Rung nhẹ khi chạm phím và khi làm đúng sai.
  final ValueNotifier<bool> haptics = ValueNotifier<bool>(true);

  /// Âm thanh giao diện (click, sai, hoàn thành).
  final ValueNotifier<bool> uiSounds = ValueNotifier<bool>(true);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_visibleKey);
      if (v != null) visibleWhites.value = _clampVisible(v);
      final id = prefs.getString(_notationKey);
      for (final n in notationChoices) {
        if (n.id == id) notation.value = n;
      }
      labelsVisible.value = prefs.getBool(_labelsKey) ?? true;
      haptics.value = prefs.getBool(_hapticKey) ?? true;
      uiSounds.value = prefs.getBool(_soundKey) ?? true;
    } catch (_) {}
  }

  Future<void> setVisibleWhites(int value) async {
    visibleWhites.value = _clampVisible(value);
    await _write((p) => p.setInt(_visibleKey, visibleWhites.value));
  }

  Future<void> setNotation(NoteNotation value) async {
    notation.value = value;
    await _write((p) => p.setString(_notationKey, value.id));
  }

  Future<void> setLabelsVisible(bool on) async {
    labelsVisible.value = on;
    await _write((p) => p.setBool(_labelsKey, on));
  }

  Future<void> setHaptics(bool on) async {
    haptics.value = on;
    await _write((p) => p.setBool(_hapticKey, on));
  }

  Future<void> setUiSounds(bool on) async {
    uiSounds.value = on;
    await _write((p) => p.setBool(_soundKey, on));
  }

  Future<void> _write(Future<bool> Function(SharedPreferences) op) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await op(prefs);
    } catch (_) {}
  }
}
