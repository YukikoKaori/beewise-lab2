// Explicit debug-only entrypoint for owner-authorized native read checks.
// Not imported by lib/main.dart or included in the submitted APK entrypoint.
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:beewise/main.dart' as app;
import 'package:beewise/services/tutor_application_service.dart';

Future<void> main() async {
  if (!kDebugMode) throw StateError('Live probe requires debug mode');
  await app.main();
  registerExtension('ext.beewise.clientReadCheck', (_, args) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final foreignUid = args['foreignUid'];
    if (Firebase.app().options.projectId != 'beewise-lab-3' ||
        user == null ||
        user.isAnonymous ||
        args['expectedUid'] != user.uid ||
        foreignUid == null ||
        !RegExp(r'^[A-Za-z0-9_-]{20,128}$').hasMatch(foreignUid) ||
        foreignUid == user.uid) {
      return ServiceExtensionResponse.result(
        jsonEncode({
          'status': 'BLOCKED',
          'reason': 'Invalid project/session/foreign test identity',
        }),
      );
    }
    final store = FirebaseFirestore.instance;
    final own = await store
        .collection('parents')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    final outcomes = <String, String>{};
    final reads = <String, Future<Object> Function()>{
      'foreign_parent_read': () => store
          .collection('parents')
          .doc(foreignUid)
          .get(const GetOptions(source: Source.server)),
      'foreign_application_read': () => store
          .collection('tutorApplications')
          .doc(foreignUid)
          .get(const GetOptions(source: Source.server)),
      'foreign_devices_query': () => store
          .collection('parents')
          .doc(foreignUid)
          .collection('devices')
          .get(const GetOptions(source: Source.server)),
    };
    for (final entry in reads.entries) {
      try {
        // Never return document contents, even if rules unexpectedly allow it.
        await entry.value().timeout(const Duration(seconds: 15));
        outcomes[entry.key] = 'FAIL unexpectedly allowed';
      } on FirebaseException catch (error) {
        outcomes[entry.key] = error.code == 'permission-denied'
            ? 'PASS permission-denied'
            : 'BLOCKED ${error.code}';
      } catch (_) {
        outcomes[entry.key] = 'BLOCKED transport/timeout';
      }
    }
    return ServiceExtensionResponse.result(
      jsonEncode({
        'client': 'Android Firebase Auth + Firestore SDK; no IAM/Admin bypass',
        'ownParentServerRead': own.exists,
        'outcomes': outcomes,
        'status':
            own.exists &&
                outcomes.values.every((v) => v == 'PASS permission-denied')
            ? 'PASS'
            : 'FAIL/BLOCKED',
        'rawIdentityOrDataExported': false,
      }),
    );
  });
  registerExtension('ext.beewise.roleRead', (_, _) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return ServiceExtensionResponse.result(
        jsonEncode({'status': 'BLOCKED guest'}),
      );
    }
    try {
      final applicant = await TutorApplicationService(
        FirebaseAuth.instance,
        FirebaseFirestore.instance,
      ).hasApplication(user.uid);
      return ServiceExtensionResponse.result(
        jsonEncode({'status': 'server-confirmed', 'applicant': applicant}),
      );
    } on FirebaseException catch (error) {
      return ServiceExtensionResponse.result(
        jsonEncode({
          'status': 'fail-closed',
          'parentGranted': false,
          'errorCode': error.code,
        }),
      );
    } catch (_) {
      return ServiceExtensionResponse.result(
        jsonEncode({
          'status': 'fail-closed',
          'parentGranted': false,
          'errorCode': 'timeout/transport',
        }),
      );
    }
  });
}
