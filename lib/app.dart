import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/studio_provider.dart';
import 'ui/splash/splash_screen.dart';

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => StudioProvider()),
      ],
      child: MaterialApp(
        title: 'Voice Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
