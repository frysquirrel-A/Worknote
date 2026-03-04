import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/theme/app_theme.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/login_page.dart';
import 'package:worknote/features/auth/ui/profile_selection_page.dart';
import 'package:worknote/features/auth/ui/profile_setup_page.dart';
import 'package:worknote/app/main_shell.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class WorkNoteApp extends StatelessWidget {
  const WorkNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSetting = context.watch<TeamProvider>().currentThemeMode;
    final themeMode = AppTheme.resolveThemeMode(themeSetting);
    final authProv = context.watch<AuthProvider>();

    debugPrint(
      '[WorkNoteApp] profile=${authProv.currentProfile?.name ?? 'null'} '
      'loading=${authProv.isLoading} pendingGoogle=${authProv.hasPendingGoogleSelection}',
    );

    Widget rootChild;
    if (authProv.isLoading) {
      rootChild = const _SplashLoadingScreen(key: ValueKey('splash'));
    } else if (authProv.currentProfile == null && authProv.hasPendingGoogleSelection) {
      rootChild = const ProfileSelectionPage(key: ValueKey('profile_select_root'));
    } else if (authProv.currentProfile == null) {
      rootChild = const LoginPage(key: ValueKey('login'));
    } else if (authProv.needsProfileSetup) {
      rootChild = const ProfileSetupPage(key: ValueKey('profile_setup'));
    } else {
      rootChild = const MainShell(key: ValueKey('main_shell'));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote Master',
      theme: AppTheme.light(setting: themeSetting),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(begin: const Offset(0.02, 0.0), end: Offset.zero).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: rootChild,
      ),
    );
  }
}

class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.architecture_rounded, size: 64, color: Colors.blueAccent),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
