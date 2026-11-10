import 'package:flutter/services.dart';

import 'audio.dart';
import 'settings_store.dart';

/// Một chỗ duy nhất cho mọi phản hồi cho người chơi: rung và âm giao diện.
/// Màn hình chỉ gọi hàm ở đây, không tự xử lý rung hay âm.
class AppFeedback {
  AppFeedback._();

  static bool get _haptics => SettingsStore.instance.haptics.value;
  static bool get _sounds => SettingsStore.instance.uiSounds.value;

  /// Khi chạm một phím đàn.
  static void key() {
    if (_haptics) HapticFeedback.lightImpact();
  }

  /// Khi bấm nút giao diện.
  static void tap() {
    if (_sounds) PianoAudio.instance.playUi('click');
    if (_haptics) HapticFeedback.selectionClick();
  }

  /// Khi làm đúng một nốt trong bài.
  static void correct() {
    if (_sounds) PianoAudio.instance.playUi('correct');
    if (_haptics) HapticFeedback.selectionClick();
  }

  /// Khi bấm sai.
  static void wrong() {
    if (_sounds) PianoAudio.instance.playUi('wrong');
    if (_haptics) HapticFeedback.mediumImpact();
  }

  /// Khi hoàn thành bài.
  static void done() {
    if (_sounds) PianoAudio.instance.playUi('done');
    if (_haptics) HapticFeedback.heavyImpact();
  }
}
