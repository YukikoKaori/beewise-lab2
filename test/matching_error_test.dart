import 'dart:async';

import 'package:beewise/viewmodels/controllers.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native provider errors offer recovery without exposing raw payload',
    () {
      for (final error in [
        ServerException('FirebaseAIServer Error [500]: {"private":"payload"}'),
        FirebaseAIException('internal provider configuration'),
      ]) {
        final message = friendlyError(error);
        expect(message, contains('thử lại'));
        expect(message, contains('tự tìm gia sư'));
        expect(message, isNot(contains('payload')));
        expect(message, isNot(contains('configuration')));
      }
      expect(
        friendlyError(QuotaExceeded('raw quota details')),
        contains('giới hạn'),
      );
      expect(
        friendlyError(TimeoutException('raw request')),
        contains('vẫn được giữ'),
      );
    },
  );
}
