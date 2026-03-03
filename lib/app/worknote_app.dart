import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/theme/app_theme.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/login_page.dart';
import 'package:worknote/app/main_shell.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class WorkNoteApp extends StatelessWidget {
  const WorkNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSetting = context.watch<TeamProvider>().currentThemeMode;
    final themeMode = AppTheme.resolveThemeMode(themeSetting);
    
    // AuthProvider 상태 구독
    final authProv = context.watch<AuthProvider>();

    print('[Debug] WorkNoteApp Build - currentProfile: ${authProv.currentProfile?.name ?? "null"}, isLoading: ${authProv.isLoading}');

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
      // ✨ AuthProvider가 초기화 중일 때 스플래시 대기 로직 추가
      home: authProv.isLoading 
        ? const _SplashLoadingScreen() 
        : (authProv.currentProfile == null ? const LoginPage() : const MainShell()),
    );
  }
}

/// 🎨 초기화 대기 시 보여줄 로딩 화면
class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();
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
