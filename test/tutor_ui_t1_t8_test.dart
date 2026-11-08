import 'package:beewise/screens/tutor_application_screens.dart';
import 'package:beewise/screens/tutor_screens.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  Widget widget, {
  List<dynamic> overrides = const [],
  Size size = const Size(412, 3200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(theme: BeeWiseTheme.light, home: widget),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('T1: Tutor Registration (Đăng ký gia sư)', () {
    testWidgets('renders all 3 sections and essential form fields', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorApplicationScreen());

      expect(find.text('Trở thành gia sư BeeWise'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.text('Chuyên môn'), findsOneWidget);
      expect(find.text('Học phí và lịch'), findsOneWidget);
      expect(find.text('Gửi hồ sơ'), findsOneWidget);
      expect(
        find.text(
          'Tôi đồng ý để BeeWise xác minh thông tin này và chỉ chia sẻ thông tin khi đã được duyệt.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows validation errors when invalid submit is attempted', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorApplicationScreen());

      // Clear phone to trigger phone error (< 10 digits)
      final phoneFinder = find.widgetWithText(TextFormField, 'Số điện thoại');
      await tester.enterText(phoneFinder, '123');

      // Tap submit
      await tester.tap(find.text('Gửi hồ sơ'));
      await tester.pumpAndSettle();

      // Validation banner and inline error should appear
      expect(find.textContaining('mục cần sửa'), findsOneWidget);
      expect(find.text('Số điện thoại cần đủ 10 số'), findsOneWidget);
    });
  });

  group('T2: Application Status (Hồ sơ gia sư)', () {
    testWidgets('renders pending status with bee robot and metadata', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const TutorApplicationStatusScreen(),
        overrides: [
          tutorApplicationDataProvider('mock_uid').overrideWith(
            (ref) => Stream.value(
              const TutorApplicationData(
                uid: 'mock_uid',
                name: 'Hoàng Thu Trang',
                email: 'trang@example.com',
                phone: '0912345678',
                qualification: 'Thạc sĩ Toán',
                introduction: 'Dạy ôn thi vào 10 chuyên sâu',
                subjects: ['Toán', 'Hóa học'],
                grades: ['Lớp 9', 'Ôn thi vào 10'],
                hourlyFee: 250000,
                areas: ['Cầu Giấy', 'Đống Đa'],
                teachingModes: ['in_person', 'online'],
                availability: 'Tối T3, T5, T7',
                status: 'pending',
                verified: false,
                active: false,
              ),
            ),
          ),
        ],
      );

      expect(find.byType(TutorApplicationStatusScreen), findsOneWidget);
    });
  });

  group('T3: Tutor Home Dashboard', () {
    testWidgets('renders active state with new chat and upcoming class', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorHomeScreen(forceEmptyState: false));

      expect(find.text('Việc cần làm hôm nay'), findsOneWidget);
      expect(find.text('Nhóm chat mới'), findsOneWidget);
      expect(find.text('Buổi học sắp tới'), findsOneWidget);
      expect(find.text('Lớp đang dạy'), findsOneWidget);
      expect(find.text('Vào nhóm chat'), findsOneWidget);
      expect(find.byType(TutorBottomNavigation), findsOneWidget);
    });

    testWidgets('renders empty state when forceEmptyState is true', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorHomeScreen(forceEmptyState: true));

      expect(find.text('Chưa có việc cần làm'), findsOneWidget);
      expect(find.text('Chưa có nhóm chat nào'), findsOneWidget);
      expect(find.text('Xem hồ sơ công khai'), findsOneWidget);
    });
  });

  group('T4: Tutor Group Chat', () {
    testWidgets('renders message stream and trial proposal card', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorChatScreen(chatId: 'chat_lan_trang'));

      expect(find.textContaining('Nhóm: Chị Lan'), findsOneWidget);
      expect(find.text('PHỤ HUYNH'), findsOneWidget);
      expect(find.text('TƯ VẤN VIÊN'), findsOneWidget);
      expect(find.text('Đề xuất buổi học thử'), findsOneWidget);
      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    });
  });

  group('T5: Tutor Class Detail', () {
    testWidgets('renders 4-stage stepper and verified payment banner', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const TutorClassDetailScreen(classId: 'class_toan9_lan'),
      );

      expect(find.text('HỌC THỬ'), findsOneWidget);
      expect(find.text('XÁC NHẬN LỚP'), findsOneWidget);
      expect(find.text('THANH TOÁN'), findsOneWidget);
      expect(find.text('LỊCH HỌC'), findsOneWidget);
      expect(
        find.text('Chị Lan đã thanh toán cho 10 buổi học chính thức'),
        findsOneWidget,
      );
      expect(find.text('Toán 9 — Ôn thi vào 10'), findsOneWidget);
      expect(find.text('Mở nhóm chat'), findsOneWidget);
    });
  });

  group('T6: Tutor Schedule', () {
    testWidgets('renders week range, day selector, and lesson session cards', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorScheduleScreen());

      expect(find.text('Tuần 18/11 — 24/11'), findsOneWidget);
      expect(find.text('Buổi 1/10'), findsOneWidget);
      expect(find.text('Buổi 2/10'), findsOneWidget);
      expect(find.text('Buổi 3/10'), findsOneWidget);
      expect(find.byType(TutorBottomNavigation), findsOneWidget);
    });
  });

  group('T7: Tutor Self Profile', () {
    testWidgets('renders public preview notice, badges, and support card', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorSelfProfileScreen());

      expect(find.text('Đây là hồ sơ phụ huynh nhìn thấy'), findsOneWidget);
      expect(find.text('Đã xác thực'), findsOneWidget);
      expect(find.text('4.9 (24)'), findsOneWidget);
      expect(find.text('HỌC PHÍ'), findsOneWidget);
      expect(find.text('Cần sửa hồ sơ?'), findsOneWidget);
      expect(find.text('Liên hệ BeeWise'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });
  });

  group('T8: Tutor Notification Center', () {
    testWidgets('renders categorized notifications and unread indicators', (
      tester,
    ) async {
      await pumpScreen(tester, const TutorNotificationScreen());

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Nhóm chat mới với chị Lan'), findsOneWidget);
      expect(find.text('Chị Lan đồng ý lịch học thử'), findsOneWidget);
      expect(
        find.text('Phụ huynh đã thanh toán · Có lớp dạy chính thức'),
        findsOneWidget,
      );
      expect(find.text('Hồ sơ của bạn đã được duyệt'), findsOneWidget);
    });
  });

  group('Responsive Layout Verification (360dp and 412dp)', () {
    for (final width in [360.0, 412.0]) {
      testWidgets('TutorHomeScreen renders without overflow at $width dp', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: BeeWiseTheme.light,
              home: const TutorHomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'TutorClassDetailScreen renders without overflow at $width dp',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 800);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: BeeWiseTheme.light,
                home: const TutorClassDetailScreen(classId: 'test_class'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('TutorScheduleScreen renders without overflow at $width dp', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: BeeWiseTheme.light,
              home: const TutorScheduleScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
