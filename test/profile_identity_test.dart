import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileUser extends Mock implements User {}

void main() {
  for (final identity in <({String? name, String? email, String initial})>[
    (name: '', email: 'alice@example.test', initial: 'A'),
    (name: '   ', email: 'alice@example.test', initial: 'A'),
    (name: null, email: 'alice@example.test', initial: 'A'),
    (name: null, email: null, initial: 'B'),
    (name: '', email: '   ', initial: 'B'),
    (name: 'Yuki', email: 'alice@example.test', initial: 'Y'),
  ]) {
    testWidgets('Profile handles identity $identity without losing logout', (
      tester,
    ) async {
      final user = MockProfileUser();
      when(() => user.displayName).thenReturn(identity.name);
      when(() => user.email).thenReturn(identity.email);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseReadyProvider.overrideWithValue(false),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            notificationsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Đăng xuất'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.text(identity.initial),
        ),
        findsOneWidget,
      );
    });
  }
}
