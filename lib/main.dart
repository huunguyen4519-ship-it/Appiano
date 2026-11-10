import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/settings_store.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn thanh trạng thái và thanh điều hướng để phần chơi đàn chiếm toàn màn hình.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AppThemeController.instance.load();
  await SettingsStore.instance.load();
  await PianoAudio.instance.load();
  runApp(const AppianoApp());
}

class AppianoApp extends StatelessWidget {
  const AppianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppThemeController.instance.accent,
      builder: (context, accent, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Appiano',
          theme: buildTheme(accent),
          builder: (context, child) =>
              LiquidBackground(child: child ?? const SizedBox.shrink()),
          home: const HomeScreen(),
        );
      },
    );
  }
}
