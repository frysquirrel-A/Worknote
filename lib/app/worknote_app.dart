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
      home: context.watch<AuthProvider>().currentUser == null ? const LoginPage() : const MainShell(),
    );
  }
}
