import 'package:flutter/material.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class CrabSplashScreen extends StatefulWidget {
  const CrabSplashScreen({required this.authBloc, super.key});

  final AuthBloc authBloc;

  @override
  State<CrabSplashScreen> createState() => _CrabSplashScreenState();
}

class _CrabSplashScreenState extends State<CrabSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.authBloc.add(const AuthenticationStatusRequested());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/crabsense_splash_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x22000000),
                Colors.transparent,
                Color(0x55000000),
              ],
              stops: [0, .48, 1],
            ),
          ),
        ),
        SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Column(
              children: [
                const Spacer(flex: 2),
                Transform.translate(offset: const Offset(0, 48), child: child!),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: _controller.value,
                      backgroundColor: Colors.white.withValues(alpha: .65),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF35C85A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đang khởi động...',
                  style: TextStyle(
                    color: Color(0xFF164D2A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/crabsense_splash_logo.png',
                  width: 178,
                  height: 178,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/images/crabsense_splash_slogan.png',
                  width: 285,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
