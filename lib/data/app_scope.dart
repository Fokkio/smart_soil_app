import 'package:flutter/widgets.dart';

import 'farm_repository.dart';

class AppScope extends InheritedNotifier<FarmRepository> {
  const AppScope({
    super.key,
    required FarmRepository repository,
    required super.child,
  }) : super(notifier: repository);

  /// Subscribes the caller: rebuilds when the repository notifies.
  static FarmRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) throw FlutterError('AppScope not found');
    return scope.notifier!;
  }

  /// Does not subscribe; use inside callbacks.
  static FarmRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) throw FlutterError('AppScope not found');
    return scope.notifier!;
  }
}
