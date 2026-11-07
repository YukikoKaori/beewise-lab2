import 'package:beewise/models/tutor.dart';
import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';
import 'package:beewise/widgets/bee_wise_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Tutor _tutor({String? avatarUrl}) => Tutor(
  id: 't1',
  name: 'Nguyễn Văn A',
  credential: '',
  introduction: '',
  subjects: const ['Toán'],
  grades: const [],
  hourlyFee: 200000,
  areas: const ['Quận 1'],
  teachingModes: const ['online'],
  availability: '',
  verified: false,
  active: true,
  avatarUrl: avatarUrl,
);

void main() {
  testWidgets('TutorAvatar with an empty avatarUrl falls back to initials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TutorAvatar(tutor: _tutor(avatarUrl: ''))),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('NA'), findsOneWidget);
  });

  testWidgets('"Xóa bộ lọc" also clears the teaching-mode filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final criteria = <TutorSearchCriteria>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWithValue(true),
          tutorSearchProvider.overrideWith((ref, c) async {
            criteria.add(c);
            return const <Tutor>[];
          }),
        ],
        child: MaterialApp(
          theme: BeeWiseTheme.light,
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Online'));
    await tester.pumpAndSettle();
    expect(criteria.last.teachingMode, 'online');

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    // The unfiltered criteria are cached, so assert on the pill state itself.
    final online = tester.widget<FilterPill>(
      find.widgetWithText(FilterPill, 'Online'),
    );
    expect(online.selected, isFalse);
  });

  test('WorkflowController.reset clears a stale error', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(workflowControllerProvider.notifier);
    // No Firebase in unit tests: the action fails and leaves an error behind.
    return controller.refreshPaymentStatus('inv').then((_) {
      expect(container.read(workflowControllerProvider).hasError, isTrue);
      controller.reset();
      expect(container.read(workflowControllerProvider).hasError, isFalse);
    });
  });
}
