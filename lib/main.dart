import 'package:flutter/material.dart';

import 'screens/onboarding_screens.dart';
import 'theme.dart';

void main() => runApp(const SmartSoilApp());

class SmartSoilApp extends StatelessWidget {
  const SmartSoilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Soil',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WelcomeScreen(),
    );
  }
}
