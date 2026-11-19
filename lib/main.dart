import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/app_scope.dart';
import 'data/farm_repository.dart';
import 'data/farm_store.dart';
import 'data/seed.dart';
import 'screens/onboarding_screens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}smart_soil.json');
  final repository =
      await FarmRepository.open(FileFarmStore(file), seed: seedFromMock);
  runApp(SmartSoilApp(repository: repository));
}

class SmartSoilApp extends StatelessWidget {
  const SmartSoilApp({super.key, required this.repository});

  final FarmRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: MaterialApp(
        title: 'Smart Soil',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const WelcomeScreen(),
      ),
    );
  }
}
