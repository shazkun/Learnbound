import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:learnbound/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow Test', () {
    testWidgets('registers and logs in a user', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ✅ Go to Register screen
      final goToRegisterButton = find.text('sign up');
      expect(goToRegisterButton, findsOneWidget);
      await tester.tap(goToRegisterButton);
      await tester.pumpAndSettle();

      // ✅ Fill Registration Form
      await tester.enterText(find.byKey(Key('registerUsername')), 'testuser');
      await tester.enterText(
          find.byKey(Key('registerEmail')), 'testuser@example.com');
      await tester.enterText(
          find.byKey(Key('registerPassword')), 'password123');
      await tester.enterText(find.byKey(Key('registerName')), 'Test User');
      await tester.enterText(find.byKey(Key('registerAge')), '20');
      await tester.pump();

      // ✅ Submit Registration
      final registerButton = find.byKey(Key('registerButton'));
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Wait for navigation to Login screen
      expect(find.text('sign in'), findsOneWidget);

      // ✅ Fill Login Form
      await tester.enterText(
          find.byKey(Key('loginEmail')), 'testuser@example.com');
      await tester.enterText(find.byKey(Key('loginPassword')), 'password123');
      await tester.pump();

      // ✅ Submit Login
      final loginButton = find.byKey(Key('loginButton'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // ✅ Verify Login success
      expect(find.text('Welcome, Test User'),
          findsOneWidget); // adjust based on your app's home screen
    });
  });
}
