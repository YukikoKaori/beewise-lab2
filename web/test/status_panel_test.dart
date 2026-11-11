import 'package:beewise_admin/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('error panel exposes a retry action', (tester) async {
    var retry = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusPanel(
            title: 'Không tải được số liệu',
            detail: 'Kiểm tra kết nối.',
            action: () => retry++,
          ),
        ),
      ),
    );
    expect(find.text('Không tải được số liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retry, 1);
  });
}
