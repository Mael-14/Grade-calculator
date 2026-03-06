import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GradeGenieApp());
}

class GradeGenieApp extends StatelessWidget {
  const GradeGenieApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GradeGenie',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const WelcomeScreen(),
  );
}
