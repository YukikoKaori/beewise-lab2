// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:beewise/services/export_service.dart';
import 'package:beewise/services/report_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockStore extends Mock implements FirebaseFirestore {}

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDoc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockMetadata extends Mock implements SnapshotMetadata {}

class MockTransaction extends Mock implements Transaction {}

class TestPaths extends PathProviderPlatform {
  TestPaths(this.support);

  final String support;

  @override
  Future<String?> getApplicationSupportPath() async => support;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pdf = Uint8List.fromList(
    utf8.encode('%PDF-1.4\nsynthetic test only\n%%EOF'),
  );
  const id = 'abcdefghijklmnopqrst';
  late MockStore store;
  late MockAuth auth;
  late MockUser user;
  late MockDoc document;
  late MockDoc tutor;
  late MockSnapshot existing;
  late MockSnapshot server;
  late MockSnapshot profile;
  late MockMetadata metadata;
  late MockTransaction transaction;
  late StreamController<User?> identities;
  late ExportService service;
  late ExportedReport local;
  late Map<String, dynamic> data;
  late int transactionCalls;
  late bool committed;
  Completer<void>? writeGate;
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 30));
    registerFallbackValue(const GetOptions(source: Source.server));
    registerFallbackValue((Transaction tx) async {});
    registerFallbackValue(MockDoc());
  });
  setUp(() async {
    store = MockStore();
    auth = MockAuth();
    user = MockUser();
    document = MockDoc();
    tutor = MockDoc();
    transaction = MockTransaction();
    existing = MockSnapshot();
    server = MockSnapshot();
    profile = MockSnapshot();
    metadata = MockMetadata();
    identities = StreamController<User?>.broadcast(sync: true);
    when(() => user.uid).thenReturn('alice');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => auth.currentUser).thenReturn(user);
    when(auth.authStateChanges).thenAnswer((_) => identities.stream);
    final reports = MockCollection(),
        files = MockCollection(),
        tutors = MockCollection();
    final owner = MockDoc();
    when(() => store.collection('reports')).thenReturn(reports);
    when(() => reports.doc('alice')).thenReturn(owner);
    when(() => owner.collection('files')).thenReturn(files);
    when(() => owner.collection('localFiles')).thenReturn(files);
    when(() => files.doc()).thenReturn(document);
    when(() => files.doc(id)).thenReturn(document);
    when(() => store.collection('tutors')).thenReturn(tutors);
    when(() => tutors.doc('tutor')).thenReturn(tutor);
    when(() => document.id).thenReturn(id);
    when(() => document.path).thenReturn('reports/alice/files/$id');
    when(() => transaction.get(document)).thenAnswer((_) async => existing);
    when(() => transaction.get(tutor)).thenAnswer((_) async => profile);
    when(() => existing.exists).thenReturn(false);
    when(() => profile.data()).thenReturn({'active': true, 'verified': true});
    when(() => transaction.set<Map<String, dynamic>>(document, any()))
        .thenReturn(transaction);
    transactionCalls = 0;
    committed = false;
    writeGate = null;
    when(
      () => store.runTransaction<void>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer((call) async {
      transactionCalls++;
      await (call.positionalArguments.first as TransactionHandler<void>)(
        transaction,
      );
      await writeGate?.future;
      committed = true;
    });
    data = {
      'ownerUid': 'alice',
      'reportId': id,
      'tutorId': 'tutor',
      'fileName': 'beewise-tutor-tutor.pdf',
      'contentType': 'application/pdf',
      'encoding': 'base64',
      'sizeBytes': pdf.length,
      'base64Data': base64Encode(pdf),
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1),
    };
    when(() => server.exists).thenReturn(true);
    when(() => server.data()).thenAnswer((_) => data);
    when(() => server.metadata).thenReturn(metadata);
    when(() => metadata.isFromCache).thenReturn(false);
    when(() => metadata.hasPendingWrites).thenReturn(false);
    when(() => document.get(const GetOptions(source: Source.server)))
        .thenAnswer((_) async => server);
    final directory = await Directory.systemTemp.createTemp('beewise-unit-');
    final file = await File('${directory.path}/report.pdf').writeAsBytes(pdf);
    local = ExportedReport(file: file, sizeBytes: pdf.length);
    service = ExportService(store, auth);
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPaths(directory.path);
    addTearDown(() async {
      PathProviderPlatform.instance = original;
      await identities.close();
    });
  });
  Future<SavedReport> save({ReportOperation? operation}) => service.saveReport(
    tutorId: 'tutor',
    report: local,
    operation: operation ?? ReportOperation(),
  );

  test(
    'Final persistence retains the local PDF and syncs only metadata',
    () async {
      service = ExportService(store, auth, localMetadataOnly: true);
      local = ExportedReport(
        file: local.file,
        sizeBytes: pdf.length,
        localReportId: id,
      );
      when(() => document.path).thenReturn('reports/alice/localFiles/$id');
      data.remove('encoding');
      data.remove('base64Data');
      data['fileName'] = 'beewise-report-$id.pdf';
      final result = await save();
      expect(result.localOnly, isTrue);
      final restored = await service.resolveLocalReport(
        result,
        ReportOperation(),
      );
      expect(restored.path, isNot(local.file.path));
      expect(await restored.readAsBytes(), orderedEquals(pdf));
      final written =
          verify(
                () => transaction.set<Map<String, dynamic>>(
                  document,
                  captureAny(),
                ),
              ).captured.single
              as Map;
      expect(written.keys.toSet(), data.keys.toSet());
      expect(written.containsKey('base64Data'), isFalse);

      final bob = MockUser();
      when(() => bob.uid).thenReturn('bob');
      when(() => bob.isAnonymous).thenReturn(false);
      when(() => auth.currentUser).thenReturn(bob);
      final otherOwner = MockDoc(),
          otherFiles = MockCollection(),
          otherDoc = MockDoc();
      final collection = store.collection('reports');
      when(() => collection.doc('bob')).thenReturn(otherOwner);
      when(() => otherOwner.collection('localFiles')).thenReturn(otherFiles);
      when(() => otherFiles.doc(id)).thenReturn(otherDoc);
      when(() => otherDoc.path).thenReturn('reports/bob/localFiles/$id');
      await expectLater(
        service.resolveLocalReport(result, ReportOperation()),
        throwsA(
          isA<ExportException>().having(
            (error) => error.message,
            'message',
            contains('không thuộc tài khoản'),
          ),
        ),
      );

      when(() => auth.currentUser).thenReturn(user);
      final missing = SavedReport(
        reportId: '12345678901234567890',
        documentPath: 'reports/alice/localFiles/12345678901234567890',
        sizeBytes: pdf.length,
        localOnly: true,
      );
      final missingDoc = MockDoc();
      final ownerFiles = collection.doc('alice').collection('localFiles');
      when(() => ownerFiles.doc(missing.reportId)).thenReturn(missingDoc);
      when(() => missingDoc.path).thenReturn(missing.documentPath);
      await expectLater(
        service.resolveLocalReport(missing, ReportOperation()),
        throwsA(
          isA<ExportException>().having(
            (error) => error.message,
            'message',
            contains('Không tìm thấy PDF'),
          ),
        ),
      );
    },
  );

  test('Base64 round-trip, PDF header, bounds and document estimate', () {
    final encoded = ReportData.encode(pdf);
    expect(
      ReportData.decode({...data, 'base64Data': encoded}),
      orderedEquals(pdf),
    );
    expect(
      ReportData.estimatedDocumentBytes(data, 'reports/alice/files/$id'),
      lessThan(ReportData.maxEstimatedDocumentBytes),
    );
    final maximum = Uint8List(ReportData.maxPdfBytes)
      ..setRange(0, 5, ascii.encode('%PDF-'));
    expect(ReportData.encode(maximum).length, ReportData.maxEncodedLength);
    for (final bytes in [
      <int>[],
      [1, 2],
      ascii.encode('bad PDF'),
      Uint8List(ReportData.maxPdfBytes + 1),
    ]) {
      expect(() => ReportData.encode(bytes), throwsA(isA<ExportException>()));
    }
    for (final patch in [
      {'contentType': 'text/plain'},
      {'encoding': 'raw'},
      {'sizeBytes': 1},
      {'base64Data': 'not base64!'},
      {'base64Data': ''},
      {'base64Data': base64Encode(ascii.encode('not a PDF'))},
    ]) {
      expect(
        () => ReportData.decode({...data, ...patch}),
        throwsA(isA<ExportException>()),
      );
    }
  });
  test('waits for transaction acknowledgement AND forced server read before success', () async {
    writeGate = Completer<void>();
    var complete = false;
    final future = save().then((value) {
      complete = true;
      return value;
    });
    await pumpEventQueue();
    expect(complete, isFalse);
    expect(committed, isFalse);
    verifyNever(() => document.get(any()));
    writeGate!.complete();
    final result = await future;
    expect(result.documentPath, 'reports/alice/files/$id');
    expect(committed, isTrue);
    verify(() => document.get(const GetOptions(source: Source.server)))
        .called(1);
    final map =
        verify(
              () =>
                  transaction.set<Map<String, dynamic>>(document, captureAny()),
            ).captured.single
            as Map;
    expect(map['createdAt'], isA<FieldValue>());
    expect(base64Decode(map['base64Data'] as String), orderedEquals(pdf));
    expect(map.keys.toSet(), data.keys.toSet());
  });
  test(
    'oversize, empty, invalid header and changed file fail before a write',
    () async {
      for (final bytes in [
        Uint8List(512001),
        Uint8List(0),
        Uint8List.fromList(ascii.encode('not PDF')),
      ]) {
        await local.file.writeAsBytes(bytes);
        local = ExportedReport(file: local.file, sizeBytes: bytes.length);
        await expectLater(save(), throwsA(isA<ExportException>()));
      }
      await local.file.writeAsBytes(pdf);
      await expectLater(save(), throwsA(isA<ExportException>()));
      expect(transactionCalls, 0);
    },
  );
  test('guest and anonymous cannot save/read/download', () async {
    for (final anonymous in [false, true]) {
      when(() => auth.currentUser).thenReturn(anonymous ? user : null);
      when(() => user.isAnonymous).thenReturn(anonymous);
      await expectLater(save(), throwsA(isA<ExportException>()));
      await expectLater(
        service.getReport(id, operation: ReportOperation()),
        throwsA(isA<ExportException>()),
      );
      await expectLater(
        service.downloadReport(id, operation: ReportOperation()),
        throwsA(isA<ExportException>()),
      );
    }
    expect(transactionCalls, 0);
  });
  test('offline and permission failure propagate; retry recovers', () async {
    for (final code in ['unavailable', 'permission-denied']) {
      when(() => document.get(any()))
          .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: code));
      await expectLater(
        service.getReport(id, operation: ReportOperation()),
        throwsA(isA<FirebaseException>()),
      );
    }
    when(() => document.get(any())).thenAnswer((_) async => server);
    expect(
      (await service.getReport(id, operation: ReportOperation()))['reportId'],
      id,
    );
  });
  test('write rejection never requests a server result', () async {
    when(
      () => store.runTransaction<void>(
        any(),
        timeout: any(named: 'timeout'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await expectLater(save(), throwsA(isA<FirebaseException>()));
    verifyNever(() => document.get(any()));
  });
  test('existing ID and ineligible actual tutors cannot be overwritten/exported to cloud', () async {
    when(() => existing.exists).thenReturn(true);
    await expectLater(save(), throwsA(isA<ExportException>()));
    when(() => existing.exists).thenReturn(false);
    for (final profileData in [
      {'active': true, 'verified': false},
      {'active': false, 'verified': true},
      {'active': true, 'verified': true, 'syntheticTestFixture': true},
    ]) {
      when(() => profile.data()).thenReturn(profileData);
      await expectLater(save(), throwsA(isA<ExportException>()));
    }
    verifyNever(() => transaction.set<Map<String, dynamic>>(document, any()));
  });
  test(
    'cancellation during save and A -> B -> A prevent late exposure',
    () async {
      for (final switchAccount in [false, true]) {
        writeGate = Completer<void>();
        final operation = ReportOperation();
        final future = save(operation: operation);
        final expectation = expectLater(
          future,
          throwsA(isA<ExportException>()),
        );
        await pumpEventQueue();
        if (switchAccount) {
          final b = MockUser();
          when(() => b.uid).thenReturn('bob');
          when(() => b.isAnonymous).thenReturn(false);
          identities.add(b);
          identities.add(user);
        } else {
          operation.cancel();
        }
        writeGate!.complete();
        await expectation;
      }
      verifyNever(() => document.get(any()));
    },
  );
  test('logout during save never exposes a report or fetches it', () async {
    writeGate = Completer<void>();
    final future = save();
    final expectation = expectLater(future, throwsA(isA<ExportException>()));
    await pumpEventQueue();
    when(() => auth.currentUser).thenReturn(null);
    identities.add(null);
    writeGate!.complete();
    await expectation;
    verifyNever(() => document.get(any()));
  });
  test(
    'timeout cancels late callbacks, not falsely claiming success',
    () async {
      service = ExportService(
        store,
        auth,
        timeout: const Duration(milliseconds: 10),
      );
      writeGate = Completer<void>();
      await expectLater(save(), throwsA(isA<ExportException>()));
      writeGate!.complete();
      await pumpEventQueue();
      verifyNever(() => document.get(any()));
    },
  );
  test('cache, pending writes, missing document and corruption cannot prove persistence', () async {
    when(() => metadata.isFromCache).thenReturn(true);
    await expectLater(save(), throwsA(isA<ExportException>()));
    when(() => metadata.isFromCache).thenReturn(false);
    when(() => metadata.hasPendingWrites).thenReturn(true);
    await expectLater(save(), throwsA(isA<ExportException>()));
    when(() => metadata.hasPendingWrites).thenReturn(false);
    when(() => server.exists).thenReturn(false);
    await expectLater(
      service.getReport(id, operation: ReportOperation()),
      throwsA(isA<ExportException>()),
    );
    when(() => server.exists).thenReturn(true);
    data['base64Data'] = 'corrupt';
    await expectLater(
      service.downloadReport(id, operation: ReportOperation()),
      throwsA(isA<ExportException>()),
    );
  });
  test(
    'download uses server data and preserves bytes exactly in a local File',
    () async {
      final file = await service.downloadReport(
        id,
        operation: ReportOperation(),
      );
      expect(await file.readAsBytes(), orderedEquals(pdf));
      verify(() => document.get(const GetOptions(source: Source.server)))
          .called(1);
    },
  );
}
