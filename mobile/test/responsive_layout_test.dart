import 'package:beewise/models/tutor.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/widgets/bee_wise_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation bar follows the 72dp Lab 2 handoff', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BeeWiseTheme.light,
        home: const Scaffold(
          body: SizedBox(),
          bottomNavigationBar: BeeWiseBottomNavigation(selectedIndex: 0),
        ),
      ),
    );

    final size = tester.getSize(find.byType(NavigationBar));
    expect(size.height, 72);
  });

  for (final width in [360.0, 412.0]) {
    testWidgets('tutor card fits $width dp with enlarged text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tutor = Tutor.fromMap('layout-check', {
        'name': 'Gia sư Nguyễn Minh Anh có tên dài để kiểm tra tự xuống dòng',
        'credential':
            'Thạc sĩ Toán học, Đại học Quốc gia Thành phố Hồ Chí Minh',
        'subjects': ['Toán nâng cao', 'Đại số', 'Hình học'],
        'areas': ['Thành phố Hồ Chí Minh', 'Thủ Đức'],
        'teachingModes': ['Trực tuyến và tại nhà'],
        'hourlyFee': 350000,
        'verified': true,
        'active': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: BeeWiseTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [TutorCard(tutor: tutor, onOpen: _noop)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Nguyễn Minh Anh'), findsOneWidget);
      expect(find.text('350.000đ/giờ'), findsOneWidget);
    });
  }
}

void _noop() {}
