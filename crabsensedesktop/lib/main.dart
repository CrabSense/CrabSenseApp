import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'config/app_env.dart';
import 'screens/auth_gate.dart';
import 'services/theme_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Browser target exists solely for local UI development. Do not deploy it
  // as the administrator web app or use it to bypass platform roles.
  if (kIsWeb && (!kDebugMode ||
      !const bool.fromEnvironment('CRABSENSE_DESKTOP_PREVIEW') ||
      !const {'localhost', '127.0.0.1', '::1'}.contains(Uri.base.host))) {
    runApp(const MaterialApp(home: Scaffold(body: Center(
      child: Text('CrabSense Desktop Web Preview is local debug only.'),
    ))));
    return;
  }
  MediaKit.ensureInitialized();
  await AppEnv.load();
  GoogleFonts.notoSans();
  runApp(const CrabFarmMonitorApp());
}

class CrabFarmMonitorApp extends StatelessWidget {
  const CrabFarmMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrabSense',
      debugShowCheckedModeBanner: false,
      theme: appThemeMode.materialTheme,
      home: const AuthGate(),
    );
  }
}
