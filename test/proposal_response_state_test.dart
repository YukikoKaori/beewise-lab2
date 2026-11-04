import 'package:beewise/models/chat_message.dart';
import 'package:beewise/models/chat_preview.dart';
import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/chat_service.dart';
import 'package:beewise/services/crash_reporting_service.dart';
import 'package:beewise/services/workflow_service.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/widgets/bee_wise_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MessagesChatService implements ChatService {
  _MessagesChatService(this.messages);
  final List<ChatMessage> messages;

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
      Stream.value(messages);

  @override
  Stream<List<ChatPreview>> watchParentChats(String parentId) =>
      Stream.value(const []);
}

class _MockWorkflow extends Mock implements WorkflowService {}

ChatMessage _proposal(String kind, Map<String, dynamic> payload) => ChatMessage(
  id: 'p1',
  senderId: 'consultant',
  senderName: 'Tư vấn viên',
  role: 'consultant',
  kind: kind,
  body: 'Đề xuất',
  createdAt: DateTime(2026, 11, 5),
  payload: payload,
);

Map<String, dynamic> _pending() => {
  'status': 'pending',
  'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
};

void main() {
  group('closedProposalNotice', () {
    test('a pending, unexpired proposal stays answerable', () {
      expect(closedProposalNotice(_pending()), isNull);
    });

    test('backend outcomes explain what happened instead of "expired"', () {
      expect(
        closedProposalNotice({'status': 'accepted'})!.message,
        contains('Bạn đã đồng ý lịch học thử'),
      );
      expect(
        closedProposalNotice({'status': 'confirmed'})!.message,
        contains('Bạn đã xác nhận thông tin lớp'),
      );
      expect(
        closedProposalNotice({'status': 'alternate_requested'})!.message,
        contains('thời gian khác'),
      );
      expect(
        closedProposalNotice({'status': 'adjustment_requested'})!.message,
        contains('điều chỉnh'),
      );
      expect(
        closedProposalNotice({'status': 'superseded'})!.message,
        contains('đề xuất mới'),
      );
    });

    test('a locally saved answer shows "Bạn đã phản hồi" until processed', () {
      final notice = closedProposalNotice(_pending(), responded: true)!;
      expect(
        notice.message,
        'Bạn đã phản hồi đề xuất này. Hệ thống đang xử lý.',
      );
      expect(notice.kind, NoticeKind.success);
    });

    test('only a really expired pending proposal is reported as expired', () {
      final notice = closedProposalNotice({
        'status': 'pending',
        'expiresAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      }, now: DateTime(2026, 11, 5))!;
      expect(notice.message, contains('hết hạn'));
      expect(notice.kind, NoticeKind.warning);
    });
  });

  group('proposal screens', () {
    late _MockWorkflow workflow;

    setUp(() {
      workflow = _MockWorkflow();
      when(
        () => workflow.answerTrial(
          chatId: any(named: 'chatId'),
          proposalId: any(named: 'proposalId'),
          accepted: any(named: 'accepted'),
          alternateTime: any(named: 'alternateTime'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => workflow.confirmClassRevision(
          chatId: any(named: 'chatId'),
          revisionId: any(named: 'revisionId'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester, Widget screen, ChatMessage msg) {
      // Tall surface so the lazily built ListView renders the action area.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatServiceProvider.overrideWithValue(_MessagesChatService([msg])),
            workflowServiceProvider.overrideWithValue(workflow),
            analyticsServiceProvider.overrideWithValue(AnalyticsService()),
            crashReportingServiceProvider.overrideWithValue(
              CrashReportingService(),
            ),
          ],
          child: MaterialApp(theme: BeeWiseTheme.light, home: screen),
        ),
      );
    }

    testWidgets('an accepted trial hides every action', (tester) async {
      await pump(
        tester,
        const TrialScreen(chatId: 'c1', proposalId: 'p1'),
        _proposal('trial_proposal', {'status': 'accepted'}),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn đã đồng ý lịch học thử'), findsOneWidget);
      expect(find.text('Đồng ý lịch học thử'), findsNothing);
      expect(find.text('Đề xuất thời gian khác'), findsNothing);
      expect(find.textContaining('hết hạn'), findsNothing);
    });

    testWidgets('tapping accept switches to "Bạn đã phản hồi" at once', (
      tester,
    ) async {
      await pump(
        tester,
        const TrialScreen(chatId: 'c1', proposalId: 'p1'),
        _proposal('trial_proposal', _pending()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đồng ý lịch học thử'));
      await tester.tap(find.text('Đồng ý lịch học thử'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn đã phản hồi đề xuất này. Hệ thống đang xử lý.'),
        findsOneWidget,
      );
      expect(find.text('Đồng ý lịch học thử'), findsNothing);
      verify(
        () => workflow.answerTrial(
          chatId: 'c1',
          proposalId: 'p1',
          accepted: true,
          alternateTime: null,
        ),
      ).called(1);
    });

    testWidgets('a confirmed class revision hides every action', (
      tester,
    ) async {
      await pump(
        tester,
        const ClassRevisionScreen(chatId: 'c1', revisionId: 'p1'),
        _proposal('class_revision', {'status': 'confirmed'}),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bạn đã xác nhận thông tin lớp'),
        findsOneWidget,
      );
      expect(find.text('Thông tin đã chính xác'), findsNothing);
      expect(find.text('Yêu cầu tư vấn viên điều chỉnh'), findsNothing);
    });

    testWidgets('a pending class revision still offers both actions', (
      tester,
    ) async {
      await pump(
        tester,
        const ClassRevisionScreen(chatId: 'c1', revisionId: 'p1'),
        _proposal('class_revision', _pending()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thông tin đã chính xác'), findsOneWidget);
      expect(find.text('Yêu cầu tư vấn viên điều chỉnh'), findsOneWidget);
    });
  });
}
