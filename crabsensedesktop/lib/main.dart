import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'config/app_env.dart';
import 'screens/login_screen.dart';
import 'services/theme_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AppEnv.load();
  GoogleFonts.notoSans();
  runApp(const CrabFarmMonitorApp());
}

class CrabFarmMonitorApp extends StatelessWidget {
  const CrabFarmMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeMode,
      builder: (context, _) {
        return MaterialApp(
          title: 'CrabFarm Monitor',
          debugShowCheckedModeBanner: false,
          theme: appThemeMode.materialTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}
