import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'config/app_env.dart';
import 'config/preview_policy.dart';
import 'screens/auth_gate.dart';
import 'services/theme_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb && !PreviewPolicy.allows(
    uri: Uri.base,
    debug: kDebugMode,
    localEnabled: const bool.fromEnvironment('CRABSENSE_DESKTOP_PREVIEW'),
    hostedEnabled: const bool.fromEnvironment('CRABSENSE_DESKTOP_HOSTED_PREVIEW'),
    hostedOrigin: const String.fromEnvironment('CRABSENSE_PREVIEW_ORIGIN'),
  )) {
    runApp(const MaterialApp(home: Scaffold(body: Center(
      child: Text('CrabSense Desktop Preview is not enabled for this origin.'),
    ))));
    return;
  }
  await AppEnv.load();
  if (kIsWeb && !kDebugMode &&
      !PreviewPolicy.validHostedApi(AppEnv.cloudApiUrl)) {
    runApp(const MaterialApp(home: Scaffold(body: Center(
      child: Text('Preview API configuration is invalid.'),
    ))));
    return;
  }
  MediaKit.ensureInitialized();
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
      builder: (context, child) => kIsWeb && !kDebugMode
          ? Banner(message: 'PREVIEW', location: BannerLocation.topEnd,
              color: Colors.deepOrange, child: child ?? const SizedBox.shrink())
          : child ?? const SizedBox.shrink(),
    );
  }
}
