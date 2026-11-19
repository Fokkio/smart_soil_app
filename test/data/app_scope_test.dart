import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_soil_app/data/app_scope.dart';

import '../helpers.dart';

void main() {
  testWidgets('AppScope.of rebuilds dependents on change', (tester) async {
    final repo = await seededRepo();
    var builds = 0;
    await tester.pumpWidget(AppScope(
        repository: repo,
        child: Builder(builder: (c) {
          AppScope.of(c);
          builds++;
          return const SizedBox();
        })));
    await repo.addFarm(name: 'ใหม่');
    await tester.pump();
    expect(builds, 2);
  });

  testWidgets('AppScope.of throws FlutterError when no AppScope above',
      (tester) async {
    late Object error;
    await tester.pumpWidget(Builder(builder: (c) {
      try {
        AppScope.of(c);
      } catch (e) {
        error = e;
      }
      return const SizedBox();
    }));
    expect(error, isA<FlutterError>());
  });
}
