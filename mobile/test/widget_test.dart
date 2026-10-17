import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kinetiq/config.dart';
import 'package:kinetiq/main.dart';

void main() {
  testWidgets('signed-out users see the Kinetiq sign-in screen', (tester) async {
    await tester.pumpWidget(const KinetiqApp(isSignedIn: false));

    expect(find.text('Kinetiq'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(find.text('Create account'), findsOneWidget);
    expect(find.textContaining('Privacy Policy'), findsOneWidget);
  });

  testWidgets('sign-in validates empty fields before calling the API', (tester) async {
    await tester.pumpWidget(const KinetiqApp(isSignedIn: false));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email and password.'), findsOneWidget);
  });

  test('release builds must use an https API', () {
    expect(AppConfig.configurationError(releaseMode: true, baseUrl: 'http://10.0.2.2:8000'), isNotNull);
    expect(AppConfig.configurationError(releaseMode: true, baseUrl: 'https://api.kinetiq.app'), isNull);
    expect(AppConfig.configurationError(releaseMode: false, baseUrl: 'http://10.0.2.2:8000'), isNull);
  });

  testWidgets('config error app shows the message', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp(message: 'bad config'));
    expect(find.text('bad config'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
