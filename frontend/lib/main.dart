import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/clinic_store.dart';
import 'data/clinic_api.dart';
import 'widgets/clinic_connection.dart';
import 'pages/app_shell.dart';
import 'widgets/clinic_ui.dart';
import 'widgets/app_motion.dart';

Future<void> main() async {
  // Resolve the real host before Device Preview overrides the simulated platform.
  final apiBaseUrl = defaultApiBaseUrl();
  const previewEnabled = bool.fromEnvironment(
    'DEVICE_PREVIEW',
    defaultValue: true,
  );
  const hostedPreview = bool.fromEnvironment('HOSTED_PREVIEW');
  DevicePreview.enable(
    enabled:
        previewEnabled &&
        (kDebugMode || (kIsWeb && kProfileMode && hostedPreview)),
  );
  await DevicePreview.maybeController?.applyPreset(DevicePresets.iPhone16);
  runApp(
    MyApp(
      store: const bool.fromEnvironment('USE_DEMO_DATA')
          ? ClinicStore()
          : ClinicStore.remote(ClinicApi(baseUrl: apiBaseUrl)),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.store});
  final ClinicStore? store;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final store = widget.store ?? ClinicStore();

  @override
  void initState() {
    super.initState();
    if (store.isRemote) unawaited(store.load());
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vista Care • Owner dashboard',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ClinicPageTransitions(),
          TargetPlatform.iOS: ClinicPageTransitions(),
          TargetPlatform.macOS: ClinicPageTransitions(),
          TargetPlatform.windows: ClinicPageTransitions(),
          TargetPlatform.linux: ClinicPageTransitions(),
          TargetPlatform.fuchsia: ClinicPageTransitions(),
        },
      ),
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.green,
        surface: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      dividerColor: AppColors.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
    ),
    home: ClinicConnection(
      store: store,
      child: AppShell(store: store),
    ),
  );
}
