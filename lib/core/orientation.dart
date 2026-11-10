import 'package:flutter/services.dart';

/// Hướng dọc: màn chính và danh sách bài học.
const List<DeviceOrientation> kPortrait = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];

/// Hướng ngang: các màn có bàn phím đầy đủ.
const List<DeviceOrientation> kLandscape = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

/// Đổi hướng màn hình cho màn đang hiển thị.
void lockOrientation(List<DeviceOrientation> orientations) {
  SystemChrome.setPreferredOrientations(orientations);
}
