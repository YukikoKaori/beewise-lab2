// ignore_for_file: subtype_of_sealed_class

import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> tlv(String input) {
  final fields = <String, String>{};
  for (var start = 0; start < input.length;) {
    final id = input.substring(start, start + 2);
    final n = int.parse(input.substring(start + 2, start + 4));
    final end = start + 4 + n;
    fields[id] = input.substring(start + 4, end);
    start = end;
  }
  return fields;
}

class _FakeDocData {
  _FakeDocData(this.data, {this.version = 0});
  Map<String, dynamic> data;
  int version;
}

class _FakeSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this.id, this._data, {this.version = 0});

  @override
  final String id;
  final Map<String, dynamic>? _data;
  final int version;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocRef implements DocumentReference<Map<String, dynamic>> {
  _FakeDocRef(this.firestore, this.path);

  @override
  final _FakeFirestore firestore;
  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionRef implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionRef(this._firestore, this.path);

  final _FakeFirestore _firestore;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? docId]) =>
      _FakeDocRef(_firestore, '$path/${docId ?? 'auto'}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransaction implements Transaction {
  _FakeTransaction(this._firestore);

  final _FakeFirestore _firestore;
  final readVersions = <String, int>{};
  final stagedUpdates = <String, Map<Object, Object?>>{};

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final path = documentReference.path;
    final entry = _firestore.store[path];
    final version = entry?.version ?? -1;
    final snapshot = _FakeSnapshot(
      documentReference.id,
      entry == null ? null : Map<String, dynamic>.from(entry.data),
      version: version,
    ) as DocumentSnapshot<T>;
    readVersions[path] = version;
    await _firestore.onTxRead?.call(path);
    return snapshot;
  }

  @override
  Transaction update(
    DocumentReference<Object?> documentReference,
    Map<Object, Object?> data,
  ) {
    stagedUpdates[documentReference.path] = Map<Object, Object?>.from(data);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final store = <String, _FakeDocData>{};
  int txAttempts = 0;
  Future<void> Function(String path)? onTxRead;
  Map<Object, Object?>? lastAppliedPatch;

  void seed(String path, Map<String, dynamic> data) {
    store[path] = _FakeDocData(Map<String, dynamic>.from(data), version: 1);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollectionRef(this, collectionPath);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      txAttempts++;
      final tx = _FakeTransaction(this);
      final result = await transactionHandler(tx);
      var conflicted = false;
      for (final entry in tx.readVersions.entries) {
        final currentVersion = store[entry.key]?.version ?? -1;
        if (currentVersion != entry.value) {
          conflicted = true;
          break;
        }
      }
      if (conflicted) {
        if (attempt == maxAttempts - 1) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'aborted',
            message: 'Transaction aborted due to concurrent write.',
          );
        }
        continue;
      }
      for (final updateEntry in tx.stagedUpdates.entries) {
        final existing = store[updateEntry.key];
        if (existing != null) {
          lastAppliedPatch = Map<Object, Object?>.from(updateEntry.value);
          for (final kv in updateEntry.value.entries) {
            existing.data[kv.key.toString()] = kv.value;
          }
          existing.version++;
        }
      }
      return result;
    }
    throw StateError('Unreachable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _invoiceDoc(String status) => {
  'invoiceId': 'FinalChatCase0000001',
  'chatId': 'FinalChatCase0000001',
  'parentId': 'alice',
  'tutorId': 'tutor',
  'amount': 150000,
  'transferReference': 'BWTESTREFERENCE001',
  'recipient': const BankRecipient(
    '000000',
    '000000000',
    'EMULATOR ONLY',
    '',
  ).toMap(),
  'status': status,
};

void main() {
  test('matches the published NAPAS 1.5.2 dynamic IBFT account vector', () {
    expect(
      napasAccountPayload(
        bankBin: '970403',
        accountNumber: '0011012345678',
        amount: 180000,
        billNumber: 'NPS6869',
        purpose: 'thanh toan don hang',
      ),
      '00020101021238570010A00000072701270006970403011300110123456780208QRIBFTTA'
      '530370454061800005802VN62340107NPS68690819thanh toan don hang63042E2E',
    );
  });

  test(
    'invoice QR encodes exact recipient, VND, amount and distinct reference',
    () {
      const fake = BankRecipient('000000', '000000000', 'EMULATOR ONLY', '');
      final one = dynamicVietQr(
        recipient: fake,
        amount: 150000,
        reference: 'BWTESTREFERENCE001',
      );
      final two = dynamicVietQr(
        recipient: fake,
        amount: 160001,
        reference: 'BWTESTREFERENCE002',
      );
      expect(one, isNot(two));
      for (final (payload, amount, ref) in [
        (one, '150000', 'BWTESTREFERENCE001'),
        (two, '160001', 'BWTESTREFERENCE002'),
      ]) {
        final data = tlv(payload);
        final account = tlv(tlv(data['38']!)['01']!);
        expect(account, {'00': '000000', '01': '000000000'});
        expect(tlv(data['38']!)['02'], 'QRIBFTTA');
        expect(data['01'], '12');
        expect(data['53'], '704');
        expect(data['54'], amount);
        expect(tlv(data['62']!), {'01': ref, '08': ref});
      }
      expect(
        () => dynamicVietQr(
          recipient: fake,
          amount: 0,
          reference: 'BWTESTREFERENCE001',
        ),
        throwsFormatException,
      );
      expect(BankRecipient.parse({'bankBin': 'invalid'}), isNull);
    },
  );

  group('ManualPayments.cancel transactional safety & validation', () {
    test(
      'rejects blank and >500-char reasons before any transaction',
      () async {
        final db = _FakeFirestore();
        final store = ManualPayments(db);
        db.seed('finalPayments/FinalChatCase0000001', _invoiceDoc('offered'));

        for (final invalidReason in ['', '   ', '\t\n', 'x' * 501]) {
          await expectLater(
            store.cancel('FinalChatCase0000001', 'staff', invalidReason),
            throwsFormatException,
          );
        }
        expect(db.txAttempts, 0);
        expect(
          db.store['finalPayments/FinalChatCase0000001']!.data['status'],
          'offered',
        );
      },
    );

    test('rejects missing invoice documents with FormatException', () async {
      final db = _FakeFirestore();
      final store = ManualPayments(db);

      await expectLater(
        store.cancel('FinalChatCase0000001', 'staff', 'Hóa đơn không tồn tại'),
        throwsFormatException,
      );
      expect(db.txAttempts, 1);
    });

    for (final status in ManualPayments.cancellableStatuses) {
      test(
        'cancels "$status" atomically and preserves financial fields',
        () async {
          final db = _FakeFirestore();
          final store = ManualPayments(db);
          const id = 'FinalChatCase0000001';
          db.seed('finalPayments/$id', _invoiceDoc(status));
          final maxReason = 'r' * 500;

          await store.cancel(
            id,
            'staff-1',
            '  $maxReason  ',
            expectedStatus: status,
          );

          expect(db.txAttempts, 1);
          final saved = db.store['finalPayments/$id']!.data;
          expect(saved['status'], 'cancelled');
          expect(saved['cancelReason'], maxReason);
          expect(saved['cancelledBy'], 'staff-1');
          expect(saved['cancelledAt'], isA<FieldValue>());
          expect(saved['amount'], 150000);
          expect(saved['transferReference'], 'BWTESTREFERENCE001');
          expect(db.lastAppliedPatch?.keys.toSet(), {
            'status',
            'cancelReason',
            'cancelledBy',
            'cancelledAt',
          });
        },
      );
    }

    for (final blocked in [
      'awaiting_verification',
      'verified',
      'cancelled',
      'other',
    ]) {
      test(
        'rejects non-cancellable status "$blocked" without mutation',
        () async {
          final db = _FakeFirestore();
          final store = ManualPayments(db);
          const id = 'FinalChatCase0000001';
          db.seed('finalPayments/$id', _invoiceDoc(blocked));

          await expectLater(
            store.cancel(id, 'staff-1', 'Lý do hợp lệ'),
            throwsFormatException,
          );
          expect(db.store['finalPayments/$id']!.data['status'], blocked);
          expect(db.store['finalPayments/$id']!.data['amount'], 150000);
        },
      );
    }

    test(
      'rejects stale expectedStatus when state moved concurrently',
      () async {
        final db = _FakeFirestore();
        final store = ManualPayments(db);
        const id = 'FinalChatCase0000001';
        db.seed('finalPayments/$id', _invoiceDoc('awaiting_transfer'));

        await expectLater(
          store.cancel(id, 'staff-1', 'Quá hạn', expectedStatus: 'offered'),
          throwsFormatException,
        );
        expect(
          db.store['finalPayments/$id']!.data['status'],
          'awaiting_transfer',
        );
      },
    );

    test('concurrent parent claim during cancel transaction forces retry and blocks stale cancel', () async {
      final db = _FakeFirestore();
      final store = ManualPayments(db);
      const id = 'FinalChatCase0000001';
      db.seed('finalPayments/$id', _invoiceDoc('awaiting_transfer'));

      var claimedMidTx = false;
      db.onTxRead = (path) async {
        if (!claimedMidTx && path == 'finalPayments/$id') {
          claimedMidTx = true;
          // Concurrent parent transfer claim commits before staff cancel commits.
          final entry = db.store[path]!;
          entry.data['status'] = 'awaiting_verification';
          entry.data['claimId'] = 'ManualClaim000000001';
          entry.version++;
        }
      };

      await expectLater(
        store.cancel(
          id,
          'staff-1',
          'Hủy vì hết hạn',
          expectedStatus: 'awaiting_transfer',
        ),
        throwsFormatException,
      );
      expect(db.txAttempts, 2);
      final finalDoc = db.store['finalPayments/$id']!.data;
      expect(finalDoc['status'], 'awaiting_verification');
      expect(finalDoc['claimId'], 'ManualClaim000000001');
      expect(finalDoc['amount'], 150000);
    });

    test('concurrent staff verification wins over cancel and never overwrites verified payment', () async {
      final db = _FakeFirestore();
      final store = ManualPayments(db);
      const id = 'FinalChatCase0000001';
      db.seed('finalPayments/$id', _invoiceDoc('awaiting_transfer'));

      var verifiedMidTx = false;
      db.onTxRead = (path) async {
        if (!verifiedMidTx && path == 'finalPayments/$id') {
          verifiedMidTx = true;
          final entry = db.store[path]!;
          entry.data['status'] = 'verified';
          entry.data['verifiedBy'] = 'staff-2';
          entry.data['classId'] = ManualPayments.classId(id);
          entry.version++;
        }
      };

      await expectLater(
        store.cancel(id, 'staff-1', 'Hủy nhầm'),
        throwsFormatException,
      );
      final finalDoc = db.store['finalPayments/$id']!.data;
      expect(finalDoc['status'], 'verified');
      expect(finalDoc['verifiedBy'], 'staff-2');
      expect(finalDoc['amount'], 150000);
    });
  });
}
