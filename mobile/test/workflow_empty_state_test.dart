import 'package:beewise/models/chat_message.dart';
import 'package:beewise/models/chat_preview.dart';
import 'package:beewise/services/chat_service.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/widgets/bee_wise_widgets.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

class _EmptyChatService implements ChatService {
  @override
  Future<String> createConnectionRequest({
    required String tutorId,
    required String learningGoal,
    required String area,
    required String schedule,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> sendMessage(String chatId, String body) =>
      throw UnimplementedError();

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      Stream.value(const []);

  @override
  Stream<List<ChatPreview>> watchParentChats(String parentId) =>
      Stream.value(const []);
}

// Mocktail requires implementing this Firebase interface for provider tests.
// ignore: subtype_of_sealed_class
class _MissingDocument extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [360.0, 412.0]) {
    testWidgets('four-step progress fits $width dp with enlarged text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: BeeWiseTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: OnboardingStepper(currentStep: 1),
            ),
          ),
        ),
      );

      expect(find.text('Học thử'), findsOneWidget);
      expect(find.text('Xác nhận lớp'), findsOneWidget);
      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Lịch học'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tiến trình tư vấn, bước 2 trên 4: Xác nhận lớp'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      // Flutter verifies open handles before test-level tearDown callbacks.
      semantics.dispose();
    });

    testWidgets(
      'empty onboarding workflow screens fit $width dp at 1.8 text scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final invoice = _MissingDocument();
        when(() => invoice.exists).thenReturn(false);
        when(() => invoice.data()).thenReturn(null);
        final schedule = _MissingDocument();
        when(() => schedule.exists).thenReturn(false);
        when(() => schedule.data()).thenReturn(null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firebaseReadyProvider.overrideWithValue(false),
              chatServiceProvider.overrideWithValue(_EmptyChatService()),
              analyticsServiceProvider.overrideWithValue(AnalyticsService()),
              invoiceQueryProvider.overrideWith(
                (ref, invoiceId) => Stream.value(invoice),
              ),
              scheduleProvider.overrideWith(
                (ref, classId) => Stream.value(schedule),
              ),
            ],
            child: MaterialApp(
              theme: BeeWiseTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.8)),
                child: child!,
              ),
              home: const _WorkflowRoutes(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Trial'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có đề xuất'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Class'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có thông tin lớp'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Payment'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có hóa đơn'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Schedule'));
        await tester.pumpAndSettle();
        expect(find.text('Lịch chưa được xác nhận'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty chat keeps its composer available at 360dp', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWithValue(false),
          chatServiceProvider.overrideWithValue(_EmptyChatService()),
          analyticsServiceProvider.overrideWithValue(AnalyticsService()),
        ],
        child: MaterialApp(
          theme: BeeWiseTheme.light,
          home: const _RouteScreen(
            body: ChatScreen(chatId: 'synthetic-empty-chat'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có tin nhắn'), findsOneWidget);
    expect(find.byTooltip('Gửi tin nhắn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WorkflowRoutes extends StatefulWidget {
  const _WorkflowRoutes();

  @override
  State<_WorkflowRoutes> createState() => _WorkflowRoutesState();
}

class _WorkflowRoutesState extends State<_WorkflowRoutes> {
  Widget _screen = const _RouteScreen(body: SizedBox.shrink());

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screen,
    bottomNavigationBar: SafeArea(
      child: Wrap(
        children: [
          TextButton(
            onPressed: () => setState(() {
              _screen = const _RouteScreen(
                body: TrialScreen(
                  chatId: 'synthetic-empty-chat',
                  proposalId: 'missing-proposal',
                ),
              );
            }),
            child: const Text('Trial'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _screen = const _RouteScreen(
                body: ClassRevisionScreen(
                  chatId: 'synthetic-empty-chat',
                  revisionId: 'missing-revision',
                ),
              );
            }),
            child: const Text('Class'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _screen = const _RouteScreen(
                body: PaymentScreen(invoiceId: 'missing-invoice'),
              );
            }),
            child: const Text('Payment'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _screen = const _RouteScreen(
                body: ScheduleScreen(classId: 'missing-class'),
              );
            }),
            child: const Text('Schedule'),
          ),
        ],
      ),
    ),
  );
}

class _RouteScreen extends StatelessWidget {
  const _RouteScreen({required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) => Material(
    child: BeeWiseScaffold(title: 'BeeWise', showBack: true, body: body),
  );
}
