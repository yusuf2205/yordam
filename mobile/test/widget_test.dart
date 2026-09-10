// Basic smoke test: the app boots and shows the login screen.
//
// Replaces the default `flutter create` counter-app template (which
// referenced a nonexistent `MyApp` widget) with something that matches
// Yordam's actual entry point (`YordamApp` in lib/main.dart).

import 'package:flutter_test/flutter_test.dart';

import 'package:yordam_mobile/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(YordamApp());

    expect(find.text('YORDAM'), findsOneWidget);
    expect(find.text('Телефон'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });
}
