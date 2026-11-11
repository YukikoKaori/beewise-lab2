import 'package:beewise/services/workflow_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockStore extends Mock implements FirebaseFirestore {}

// Firestore SDK doubles are scoped to regression tests.
// ignore: subtype_of_sealed_class
class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {}

void main() {
  late WorkflowService service;
  late MockAuth auth;
  late MockTransaction transaction;
  late MockDocument response;
  late Map<String, dynamic> chat;
  late Map<String, dynamic> proposal;
  late bool answered;
  setUpAll(() {
    registerFallbackValue((Transaction _) async {});
  });
  setUp(() {
    auth = MockAuth();
    final user = MockUser();
    final store = MockStore();
    final chats = MockCollection();
    final messages = MockCollection();
    final responses = MockCollection();
    final chatRef = MockDocument();
    final proposalRef = MockDocument();
    response = MockDocument();
    final chatSnapshot = MockSnapshot();
    final proposalSnapshot = MockSnapshot();
    final responseSnapshot = MockSnapshot();
    transaction = MockTransaction();
    when(() => transaction.set<Map<String, dynamic>>(response, any()))
        .thenReturn(transaction);
    answered = false;
    chat = {
      'parentId': 'alice',
      'onboardingStatus': 'trial_proposed',
      'currentProposalId': 'proposal',
    };
    proposal = {
      'role': 'consultant',
      'kind': 'trial_proposal',
      'payload': {
        'status': 'pending',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      },
    };
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('alice');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => store.collection('chats')).thenReturn(chats);
    when(() => chats.doc('chat')).thenReturn(chatRef);
    when(() => chatRef.collection('messages')).thenReturn(messages);
    when(() => messages.doc('proposal')).thenReturn(proposalRef);
    when(() => chatRef.collection('responses')).thenReturn(responses);
    when(() => responses.doc('proposal')).thenReturn(response);
    when(() => transaction.get(chatRef)).thenAnswer((_) async => chatSnapshot);
    when(() => transaction.get(proposalRef))
        .thenAnswer((_) async => proposalSnapshot);
    when(() => transaction.get(response))
        .thenAnswer((_) async => responseSnapshot);
    when(() => chatSnapshot.data()).thenAnswer((_) => chat);
    when(() => proposalSnapshot.data()).thenAnswer((_) => proposal);
    when(() => responseSnapshot.exists).thenAnswer((_) => answered);
    when(() => store.runTransaction<void>(any())).thenAnswer((call) async {
      await (call.positionalArguments.first as TransactionHandler<void>)(
        transaction,
      );
    });
    service = WorkflowService(store, auth);
  });
  Future<void> accept() => service.answerTrial(
    chatId: 'chat',
    proposalId: 'proposal',
    accepted: true,
  );
  test('eligible response writes deterministic proposal ID and never advances chat', () async {
    await accept();
    verify(() => transaction.set<Map<String, dynamic>>(response, any()))
        .called(1);
  });
  test(
    'another owner, stale ID, expired or consumed proposal is denied',
    () async {
      chat['parentId'] = 'bob';
      await expectLater(accept(), throwsA(isA<WorkflowException>()));
      chat['parentId'] = 'alice';
      chat['currentProposalId'] = 'new';
      await expectLater(accept(), throwsA(isA<WorkflowException>()));
      chat['currentProposalId'] = 'proposal';
      (proposal['payload'] as Map)['expiresAt'] =
          Timestamp.fromMillisecondsSinceEpoch(1);
      await expectLater(accept(), throwsA(isA<WorkflowException>()));
      (proposal['payload'] as Map)['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 1)),
      );
      answered = true;
      await expectLater(accept(), throwsA(isA<WorkflowException>()));
      verifyNever(() => transaction.set<Map<String, dynamic>>(response, any()));
    },
  );
  test('alternate response rejects empty text and guest access', () async {
    await expectLater(
      service.answerTrial(
        chatId: 'chat',
        proposalId: 'proposal',
        accepted: false,
        alternateTime: '  ',
      ),
      throwsA(isA<WorkflowException>()),
    );
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(accept(), throwsA(isA<WorkflowException>()));
  });
}
