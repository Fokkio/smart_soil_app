import 'package:flutter/material.dart';
import 'package:smart_soil_app/data/app_scope.dart';
import 'package:smart_soil_app/data/farm_repository.dart';
import 'package:smart_soil_app/data/farm_store.dart';
import 'package:smart_soil_app/data/seed.dart';
import 'package:smart_soil_app/theme.dart';

Future<FarmRepository> seededRepo({DateTime? now}) => FarmRepository.open(
      MemoryFarmStore(),
      seed: seedFromMock,
      clock: () => now ?? DateTime(2026, 11, 19, 14, 32),
    );

Widget wrap(FarmRepository repo, Widget home) => AppScope(
      repository: repo,
      child: MaterialApp(theme: buildTheme(), home: home),
    );
