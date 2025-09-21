import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectly_app/screens/sign_in_screen.dart';
import 'package:connectly_app/screens/sign_up_screen.dart';
import 'package:connectly_app/providers/auth_providers.dart';
import 'package:connectly_app/models/app_user.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Sign in screen renders and validates input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignInScreen())),
    );
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    // You can add more expectations here for error messages or loading indicators
  });

  testWidgets('Sign up screen renders and validates input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignUpScreen())),
    );
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<UserRole>), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'newuser@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mentor').last);
    await tester.pump();
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    // You can add more expectations here for error messages or loading indicators
  });
}
