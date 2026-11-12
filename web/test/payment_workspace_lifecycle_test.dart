// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:beewise_admin/main.dart' show AdminSession, StaffGate;
import 'package:beewise_admin/payment_workspace.dart';
import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIdTokenResult implements IdTokenResult {
  _FakeIdTokenResult({required this.signInProvider, required this.claims});

  @override
  final String? signInProvider;

  @override
  final Map<String, dynamic>? claims;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser({
    required this.uid,
    this.signInProvider = 'google.com',
    this.emailVerified = true,
  });

  @override
  final String uid;
  final String signInProvider;
  @override
  final bool emailVerified;

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      _FakeIdTokenResult(
        signInProvider: signInProvider,
        claims: {'email_verified': emailVerified},
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  final _controller = StreamController<User?>.broadcast(sync: true);
  User? _currentUser;
  int signOutCalls = 0;

  @override
  User? get currentUser => _currentUser;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<User?> idTokenChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emitUser(null);
  }

  Future<void> dispose() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSnapshotMetadata implements SnapshotMetadata {
  const _FakeSnapshotMetadata({
    required this.isFromCache,
    required this.hasPendingWrites,
  });

  @override
  final bool isFromCache;

  @override
  final bool hasPendingWrites;
}

class _FakeDocEntry {
  _FakeDocEntry(this.path, this.data, {this.isFromCache = false});
  final String path;
  Map<String, dynamic> data;
  bool isFromCache;
  int version = 1;
}

class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._db, this.path);

  final _FakeFirestore _db;

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  FirebaseFirestore get firestore => _db;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollectionReference(_db, '$path/$collectionPath');

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => _db.watchDoc(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this.reference, this._data, {required this.metadata});

  @override
  final DocumentReference<Map<String, dynamic>> reference;

  final Map<String, dynamic>? _data;

  @override
  final SnapshotMetadata metadata;

  @override
  String get id => reference.id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot extends _FakeDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(
    super.reference,
    Map<String, dynamic> super.data, {
    super.metadata = const _FakeSnapshotMetadata(
      isFromCache: false,
      hasPendingWrites: false,
    ),
  });

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(super.data()!);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAggregateQuerySnapshot implements AggregateQuerySnapshot {
  _FakeAggregateQuerySnapshot(this.count);

  @override
  final int? count;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAggregateQuery implements AggregateQuery {
  _FakeAggregateQuery(this._query);

  final _FakeQuery _query;

  @override
  Query<Map<String, dynamic>> get query => _query;

  @override
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async => _FakeAggregateQuerySnapshot(_query._matchingDocs().length);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuery implements Query<Map<String, dynamic>> {
  _FakeQuery(
    this._db,
    this._collectionPath, {
    Map<String, Object?>? equalsFilters,
    this._orderByField,
    this._descending = false,
  }) : _equalsFilters = equalsFilters ?? const {};

  final _FakeFirestore _db;
  final String _collectionPath;
  final Map<String, Object?> _equalsFilters;
  final String? _orderByField;
  final bool _descending;

  @override
  FirebaseFirestore get firestore => _db;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _matchingDocs() {
    final docs = <_FakeQueryDocumentSnapshot>[];
    final prefix = '$_collectionPath/';
    for (final entry in _db.docs.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final relative = entry.key.substring(prefix.length);
      if (relative.contains('/')) continue;
      var matched = true;
      for (final filter in _equalsFilters.entries) {
        if (entry.value.data[filter.key] != filter.value) {
          matched = false;
          break;
        }
      }
      if (!matched) continue;
      docs.add(
        _FakeQueryDocumentSnapshot(
          _FakeDocumentReference(_db, entry.key),
          entry.value.data,
        ),
      );
    }
    final sortField = _orderByField;
    if (sortField != null) {
      docs.sort((a, b) {
        final av = a.data()[sortField];
        final bv = b.data()[sortField];
        if (av is Timestamp && bv is Timestamp) {
          return _descending ? bv.compareTo(av) : av.compareTo(bv);
        }
        return 0;
      });
    }
    return docs;
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final nextFilters = Map<String, Object?>.from(_equalsFilters);
    if (isEqualTo != null && field is String) {
      nextFilters[field] = isEqualTo;
    }
    return _FakeQuery(
      _db,
      _collectionPath,
      equalsFilters: nextFilters,
      orderByField: _orderByField,
      descending: _descending,
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => _FakeQuery(
    _db,
    _collectionPath,
    equalsFilters: _equalsFilters,
    orderByField: field is String ? field : _orderByField,
    descending: descending,
  );

  @override
  Query<Map<String, dynamic>> limit(int limit) => this;

  @override
  AggregateQuery count() => _FakeAggregateQuery(this);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => _db.watchQuery(_collectionPath, _matchingDocs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference extends _FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(super.db, super.collectionPath);

  @override
  String get path => _collectionPath;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? _db.nextAutoId();
    return _FakeDocumentReference(_db, '$_collectionPath/$docId');
  }
}

class _FakeTransaction implements Transaction {
  _FakeTransaction(this._db);

  final _FakeFirestore _db;
  final readVersions = <String, int>{};
  final pendingSets = <String, Map<String, dynamic>>{};
  final pendingUpdates = <String, Map<Object, Object?>>{};

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final path = documentReference.path;
    _db.recordOp('tx_get:$path');
    final entry = _db.docs[path];
    final version = entry?.version ?? -1;
    final snapshot = _FakeDocumentSnapshot(
      _FakeDocumentReference(_db, path),
      entry == null ? null : Map<String, dynamic>.from(entry.data),
      metadata: const _FakeSnapshotMetadata(
        isFromCache: false,
        hasPendingWrites: false,
      ),
    ) as DocumentSnapshot<T>;
    readVersions[path] = version;
    await _db.onTxRead?.call(path);
    return snapshot;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    if (data is Map<String, dynamic>) {
      pendingSets[documentReference.path] = Map<String, dynamic>.from(data);
    }
    return this;
  }

  @override
  Transaction update(
    DocumentReference<Object?> documentReference,
    Map<Object, Object?> data,
  ) {
    pendingUpdates[documentReference.path] = Map<Object, Object?>.from(data);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final docs = <String, _FakeDocEntry>{};
  final _docControllers =
      <String, Set<StreamController<DocumentSnapshot<Map<String, dynamic>>>>>{};
  final _queryControllers =
      <
        String,
        Set<
          (
            StreamController<QuerySnapshot<Map<String, dynamic>>>,
            List<QueryDocumentSnapshot<Map<String, dynamic>>> Function(),
          )
        >
      >{};
  final ops = <String>[];
  int _checkpoint = 0;
  int _autoSeq = 0;
  int activeRoleListeners = 0;
  int activeFinalPaymentListeners = 0;
  int activeReviewListeners = 0;
  Future<void> Function(String path)? onTxRead;

  void checkpointOps() => _checkpoint = ops.length;

  List<String> get opsSinceCheckpoint => ops.sublist(_checkpoint);

  String nextAutoId() => 'auto_${++_autoSeq}';

  void recordOp(String op) => ops.add(op);

  void seed(
    String path,
    Map<String, dynamic> data, {
    bool isFromCache = false,
  }) {
    docs[path] = _FakeDocEntry(
      path,
      Map<String, dynamic>.from(data),
      isFromCache: isFromCache,
    );
    _notifyDoc(path);
    _notifyQueriesForDoc(path);
  }

  void _notifyDoc(String path) {
    final controllers = _docControllers[path];
    if (controllers == null) return;
    final entry = docs[path];
    for (final ctrl in controllers.toList()) {
      if (ctrl.isClosed) continue;
      ctrl.add(
        _FakeDocumentSnapshot(
          _FakeDocumentReference(this, path),
          entry == null ? null : Map<String, dynamic>.from(entry.data),
          metadata: _FakeSnapshotMetadata(
            isFromCache: entry?.isFromCache ?? false,
            hasPendingWrites: false,
          ),
        ),
      );
    }
  }

  void _notifyQueriesForDoc(String docPath) {
    final parentCollection = docPath.substring(0, docPath.lastIndexOf('/'));
    final listeners = _queryControllers[parentCollection];
    if (listeners == null) return;
    for (final item in listeners.toList()) {
      if (item.$1.isClosed) continue;
      item.$1.add(_FakeQuerySnapshot(item.$2()));
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDoc(String path) {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> ctrl;
    ctrl = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
      sync: true,
      onListen: () {
        recordOp('listen_doc:$path');
        if (path.startsWith('users/')) activeRoleListeners++;
        _docControllers.putIfAbsent(path, () => {}).add(ctrl);
        final entry = docs[path];
        scheduleMicrotask(() {
          if (ctrl.isClosed) return;
          ctrl.add(
            _FakeDocumentSnapshot(
              _FakeDocumentReference(this, path),
              entry == null ? null : Map<String, dynamic>.from(entry.data),
              metadata: _FakeSnapshotMetadata(
                isFromCache: entry?.isFromCache ?? false,
                hasPendingWrites: false,
              ),
            ),
          );
        });
      },
      onCancel: () {
        recordOp('cancel_doc:$path');
        if (path.startsWith('users/')) activeRoleListeners--;
        _docControllers[path]?.remove(ctrl);
        ctrl.close();
      },
    );
    return ctrl.stream;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuery(
    String collectionPath,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> Function() evaluator,
  ) {
    late StreamController<QuerySnapshot<Map<String, dynamic>>> ctrl;
    late (
      StreamController<QuerySnapshot<Map<String, dynamic>>>,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> Function(),
    )
    record;
    ctrl = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
      sync: true,
      onListen: () {
        recordOp('listen_query:$collectionPath');
        if (collectionPath == 'finalPayments') activeFinalPaymentListeners++;
        if (collectionPath.endsWith('/reviews')) activeReviewListeners++;
        record = (ctrl, evaluator);
        _queryControllers.putIfAbsent(collectionPath, () => {}).add(record);
        scheduleMicrotask(() {
          if (!ctrl.isClosed) ctrl.add(_FakeQuerySnapshot(evaluator()));
        });
      },
      onCancel: () {
        recordOp('cancel_query:$collectionPath');
        if (collectionPath == 'finalPayments') activeFinalPaymentListeners--;
        if (collectionPath.endsWith('/reviews')) activeReviewListeners--;
        _queryControllers[collectionPath]?.remove(record);
        ctrl.close();
      },
    );
    return ctrl.stream;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollectionReference(this, collectionPath);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    recordOp('tx_start');
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final tx = _FakeTransaction(this);
      final result = await transactionHandler(tx);
      var conflicted = false;
      for (final rv in tx.readVersions.entries) {
        final current = docs[rv.key]?.version ?? -1;
        if (current != rv.value) {
          conflicted = true;
          break;
        }
      }
      if (conflicted) {
        if (attempt == maxAttempts - 1) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'aborted',
            message: 'Aborted',
          );
        }
        continue;
      }
      final changed = <String>{};
      for (final s in tx.pendingSets.entries) {
        recordOp('tx_set:${s.key}');
        final materialized = _materializeTimestamps(s.value);
        docs[s.key] = _FakeDocEntry(s.key, materialized)
          ..version = (docs[s.key]?.version ?? 0) + 1;
        changed.add(s.key);
      }
      for (final u in tx.pendingUpdates.entries) {
        recordOp('tx_update:${u.key}');
        final entry = docs[u.key]!;
        final materialized = _materializeTimestamps({
          for (final kv in u.value.entries) kv.key.toString(): kv.value,
        });
        entry.data.addAll(materialized);
        entry.version++;
        changed.add(u.key);
      }
      for (final p in changed) {
        _notifyDoc(p);
        _notifyQueriesForDoc(p);
      }
      return result;
    }
    throw StateError('Unreachable');
  }

  Map<String, dynamic> _materializeTimestamps(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    for (final kv in raw.entries) {
      result[kv.key] = kv.value is FieldValue
          ? Timestamp.fromDate(DateTime.utc(2026, 11, 12, 12))
          : kv.value;
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const validChatId = 'chatAbcdef1234567890';
  final createdAt = Timestamp.fromDate(DateTime.utc(2026, 11, 12, 10));

  Map<String, dynamic> samplePayment({
    required String status,
    String? claimId,
    String reference = 'BWTEST1234567890AB',
  }) => {
    'invoiceId': validChatId,
    'chatId': validChatId,
    'parentId': 'parent-1',
    'tutorId': 'tutor-1',
    'subject': '[TEST] Toán 9',
    'tutorName': 'Gia sư Kiểm thử',
    'date': '2026-11-20',
    'time': '19:00',
    'location': 'Hà Nội',
    'amount': 450000,
    'currency': 'VND',
    'recipient': {
      'bankBin': '970436',
      'accountNumber': '1234567890',
      'accountHolder': 'CONG TY BEEWISE TEST',
      'instructions': 'TEST',
    },
    'transferReference': reference,
    'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 11, 17)),
    'createdAt': createdAt,
    'offeredBy': 'staff-1',
    'status': status,
    'claimId': ?claimId,
  };

  void seedIssuePrereqs(_FakeFirestore db) {
    db.seed('settings/paymentRecipient', {
      'bankBin': '970436',
      'accountNumber': '1234567890',
      'accountHolder': 'CONG TY BEEWISE TEST',
      'instructions': 'TEST ONLY',
    });
    db.seed('chats/$validChatId', {
      'parentId': 'parent-1',
      'tutorId': 'tutor-1',
      'paymentMode': 'manual_vietqr',
      'onboardingStatus': 'final_waiting_class_offer',
    });
    db.seed('tutors/tutor-1', {'name': 'Gia sư Kiểm thử', 'active': true});
  }

  group('Web PaymentWorkspace & F-FINAL-03 UI lifecycle', () {
    testWidgets(
      '_IssueDialog validates inputs and issues an immutable offer transactionally',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = _FakeFirestore();
        seedIssuePrereqs(db);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PaymentWorkspace(
                  store: ManualPayments(db),
                  uid: 'staff-1',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Phát hành đề xuất lớp'));
        await tester.pumpAndSettle();
        expect(find.text('Mã cuộc trò chuyện'), findsOneWidget);

        // Empty form validation keeps dialog open and performs zero writes.
        await tester.tap(find.text('Phát hành'));
        await tester.pumpAndSettle();
        expect(find.text('Không được để trống.'), findsNWidgets(6));
        expect(db.docs.containsKey('finalPayments/$validChatId'), isFalse);

        // Invalid time format shows typed FormatException message.
        final fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), validChatId);
        await tester.enterText(fields.at(1), '[TEST] Toán lớp 9');
        await tester.enterText(fields.at(2), '2026-11-20');
        await tester.enterText(fields.at(3), '99:99');
        await tester.enterText(fields.at(4), 'Cầu Giấy');
        await tester.enterText(fields.at(5), '450000');
        await tester.tap(find.text('Phát hành'));
        await tester.pumpAndSettle();
        expect(
          find.text('Kiểm tra giờ HH:mm và số tiền VND nguyên dương.'),
          findsOneWidget,
        );

        // Correct time and submit -> transactional create closes dialog.
        await tester.enterText(fields.at(3), '19:30');
        await tester.tap(find.text('Phát hành'));
        await tester.pumpAndSettle();
        expect(find.text('Mã cuộc trò chuyện'), findsNothing);
        expect(
          db.docs['finalPayments/$validChatId']?.data['status'],
          'offered',
        );
        expect(db.docs['finalPayments/$validChatId']?.data['amount'], 450000);
      },
    );

    testWidgets(
      '_ReviewDialog passes expectedStatus on cancel, surfaces concurrent claim race, and verifies matching statement',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final db = _FakeFirestore();
        db.seed('finalPayments/$validChatId', samplePayment(status: 'offered'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PaymentWorkspace(
                  store: ManualPayments(db),
                  uid: 'staff-1',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch dropdown filter to "Chờ phụ huynh xác nhận lớp".
        await tester.tap(find.text('Chờ nhân viên đối soát'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chờ phụ huynh xác nhận lớp').last);
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('BWTEST1234567890AB'));
        await tester.pumpAndSettle();
        expect(find.text('Hóa đơn $validChatId'), findsOneWidget);

        // Cancel requires non-empty reason.
        await tester.tap(find.text('Hủy hóa đơn'));
        await tester.pumpAndSettle();
        expect(find.text('Cần ghi lý do từ 1 đến 500 ký tự.'), findsOneWidget);

        // Concurrent parent claim transitions doc -> stale expectedStatus / non-cancellable error surfaced.
        db.onTxRead = (path) async {
          if (path == 'finalPayments/$validChatId') {
            db.docs[path]!.data['status'] = 'awaiting_verification';
            db.docs[path]!.data['claimId'] = 'claim-race-1';
            db.docs[path]!.version++;
            db.onTxRead = null;
          }
        };
        await tester.enterText(
          find.widgetWithText(TextField, 'Lý do từ chối / hủy'),
          'Hủy do trùng lịch',
        );
        await tester.tap(find.text('Hủy hóa đơn'));
        await tester.pumpAndSettle();
        expect(
          find.text('Hóa đơn đã thay đổi trạng thái. Hãy mở lại.'),
          findsNothing,
        );
        expect(
          find.text('Hóa đơn không còn ở trạng thái có thể hủy.'),
          findsOneWidget,
        );

        // Reset to awaiting_transfer and verify clean cancel + audit fields.
        await tester.tap(find.text('Đóng'));
        await tester.pumpAndSettle();
        db.seed(
          'finalPayments/$validChatId',
          samplePayment(status: 'awaiting_transfer'),
        );
        await tester.tap(find.text('Chờ phụ huynh xác nhận lớp'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chờ chuyển khoản').last);
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('BWTEST1234567890AB'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Lý do từ chối / hủy'),
          'Phụ huynh đổi nhu cầu',
        );
        await tester.tap(find.text('Hủy hóa đơn'));
        await tester.pumpAndSettle();
        expect(find.text('Hóa đơn $validChatId'), findsNothing);
        expect(
          db.docs['finalPayments/$validChatId']?.data['status'],
          'cancelled',
        );
        expect(
          db.docs['finalPayments/$validChatId']?.data['cancelReason'],
          'Phụ huynh đổi nhu cầu',
        );

        // Now verify full statement verification path on awaiting_verification.
        const id2 = 'chatVerify1234567890';
        db.seed(
          'finalPayments/$id2',
          samplePayment(
            status: 'awaiting_verification',
            claimId: 'claim-1',
            reference: 'BWVERIFY9876543210',
          ),
        );
        await tester.tap(find.text('Chờ chuyển khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chờ nhân viên đối soát').last);
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('BWVERIFY9876543210'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Số tiền thực nhận (VND)'),
          '450000',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Nội dung trên sao kê'),
          'BWVERIFY9876543210',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'BIN ngân hàng của sao kê'),
          '970436',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Số tài khoản của sao kê'),
          '1234567890',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mã giao dịch ngân hàng (chữ và số)'),
          'FT2631600001',
        );
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xác minh chuyển khoản'));
        await tester.pumpAndSettle();

        expect(find.text('Hóa đơn $id2'), findsNothing);
        expect(db.docs['finalPayments/$id2']?.data['status'], 'verified');
        expect(
          db.docs['classes/vietqr_$id2']?.data['paymentStatus'],
          'verified',
        );
        expect(
          db.docs['finalBankReceipts/970436_FT2631600001']?.data['invoiceId'],
          id2,
        );
      },
    );
  });

  group('F-FINAL-01 Web role-scoped dialogs & authorization lifecycle', () {
    testWidgets(
      'live staff->user revocation dismisses _IssueDialog, blocks cached roles, and halts Firestore payment queries',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final auth = _FakeFirebaseAuth();
        addTearDown(auth.dispose);
        final db = _FakeFirestore();
        db.seed('finalPayments/$validChatId', samplePayment(status: 'offered'));

        await tester.pumpWidget(
          MaterialApp(
            home: StaffGate(
              session: AdminSession(auth, BeeWiseFirestore(db), null, null),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 0);

        // Cached staff snapshot alone MUST NOT grant access.
        db.seed('users/staff-1', {'role': 'staff'}, isFromCache: true);
        auth.emitUser(_FakeUser(uid: 'staff-1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Đang xác minh quyền truy cập…'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 0);

        // Server-confirmed staff opens AdminWorkspace -> switch to VietQR -> open _IssueDialog.
        db.seed('users/staff-1', {'role': 'staff'}, isFromCache: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('VietQR'));
        await tester.pumpAndSettle();
        expect(db.activeFinalPaymentListeners, 1);

        await tester.tap(find.text('Phát hành đề xuất lớp'));
        await tester.pumpAndSettle();
        expect(find.text('Mã cuộc trò chuyện'), findsOneWidget);

        // Revoke staff role on server while _IssueDialog is open!
        db.checkpointOps();
        db.seed('users/staff-1', {'role': 'user'}, isFromCache: false);
        await tester.pumpAndSettle();

        // Dialog MUST be gone immediately because useRootNavigator: false binds it to StaffRoleGate's Navigator.
        expect(find.text('Mã cuộc trò chuyện'), findsNothing);
        expect(find.text('Chưa mở được trang quản trị'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 0);
        expect(db.activeReviewListeners, 0);
        expect(
          db.opsSinceCheckpoint.where(
            (op) =>
                op.startsWith('listen_query:finalPayments') ||
                op.startsWith('tx_'),
          ),
          isEmpty,
        );
      },
    );

    testWidgets(
      'live revocation and sign-out immediately dismiss _ReviewDialog, close listeners, and block unauthorized re-entry',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final auth = _FakeFirebaseAuth();
        addTearDown(auth.dispose);
        final db = _FakeFirestore();
        db.seed('users/staff-2', {'role': 'admin'}, isFromCache: false);
        db.seed(
          'finalPayments/$validChatId',
          samplePayment(
            status: 'awaiting_verification',
            claimId: 'claim-1',
            reference: 'BWREVOKE1234567890',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: StaffGate(
              session: AdminSession(auth, BeeWiseFirestore(db), null, null),
            ),
          ),
        );
        await tester.pumpAndSettle();
        auth.emitUser(_FakeUser(uid: 'staff-2'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('VietQR'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('BWREVOKE1234567890'));
        await tester.pumpAndSettle();

        expect(find.text('Hóa đơn $validChatId'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 1);
        expect(db.activeReviewListeners, 1);

        // Case 1: Live role revocation dismisses _ReviewDialog and cancels both listeners.
        db.checkpointOps();
        db.seed('users/staff-2', {'role': 'user'}, isFromCache: false);
        await tester.pumpAndSettle();

        expect(find.text('Hóa đơn $validChatId'), findsNothing);
        expect(find.text('Chưa mở được trang quản trị'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 0);
        expect(db.activeReviewListeners, 0);
        expect(
          db.opsSinceCheckpoint.where((op) => op.startsWith('tx_')),
          isEmpty,
        );

        // Unauthorized re-entry using unverified Google email or non-Google provider is denied cleanly.
        auth.emitUser(
          _FakeUser(uid: 'unverified-google', emailVerified: false),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Hãy dùng tài khoản Google đã xác minh của nhân viên BeeWise.',
          ),
          findsOneWidget,
        );
        expect(db.activeFinalPaymentListeners, 0);

        auth.emitUser(_FakeUser(uid: 'rogue-user', signInProvider: 'password'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Hãy dùng tài khoản Google đã xác minh của nhân viên BeeWise.',
          ),
          findsOneWidget,
        );
        expect(db.activeFinalPaymentListeners, 0);

        // Case 2: Sign-in legitimate staff, open _ReviewDialog, then trigger sign-out -> immediate teardown.
        db.seed('users/staff-3', {'role': 'staff'}, isFromCache: false);
        auth.emitUser(_FakeUser(uid: 'staff-3'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('VietQR'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('BWREVOKE1234567890'));
        await tester.pumpAndSettle();
        expect(find.text('Hóa đơn $validChatId'), findsOneWidget);
        expect(db.activeReviewListeners, 1);

        db.checkpointOps();
        await auth.signOut();
        await tester.pumpAndSettle();

        expect(find.text('Hóa đơn $validChatId'), findsNothing);
        expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
        expect(db.activeFinalPaymentListeners, 0);
        expect(db.activeReviewListeners, 0);
        expect(db.activeRoleListeners, 0);
        expect(
          db.opsSinceCheckpoint.where(
            (op) =>
                op.startsWith('listen_query:') ||
                op.startsWith('listen_doc:') ||
                op.startsWith('tx_'),
          ),
          isEmpty,
        );
      },
    );
  });
}
