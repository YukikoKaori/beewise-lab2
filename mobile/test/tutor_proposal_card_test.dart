import 'package:beewise/screens/tutor_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Exactly what backend/src/consultant-service.js writes into message.payload.
  final trial = <String, dynamic>{
    'tutorName': 'Hoàng Thu Trang',
    'subject': 'Toán lớp 8',
    'date': '10/11/2026',
    'time': '19:00',
    'mode': 'Trực tuyến',
    'location': 'Google Meet',
    'status': 'pending',
  };
  final revision = <String, dynamic>{
    'subject': 'Toán lớp 8',
    'schedule': 'Thứ 3, Thứ 5',
    'time': '19:00 - 20:30',
    'location': 'Google Meet',
    'status': 'pending',
  };

  test('summary line uses the fields each proposal kind really has', () {
    expect(
      tutorProposalSummaryLine(trial, isTrial: true),
      'Toán lớp 8 · 10/11/2026 lúc 19:00 · Google Meet',
    );
    expect(
      tutorProposalSummaryLine(revision, isTrial: false),
      'Toán lớp 8 · Thứ 3, Thứ 5 · 19:00 - 20:30 · Google Meet',
    );
    expect(tutorProposalSummaryLine(const {}, isTrial: true), isEmpty);
    expect(
      tutorProposalSummaryLine({'subject': '  ', 'location': 7}, isTrial: true),
      isEmpty,
    );
  });

  test('every backend response status has its own label', () {
    String label(String? status, {Object? expiresAt, DateTime? now}) =>
        tutorProposalStatus({
          ...trial,
          'status': status,
          'expiresAt': expiresAt,
        }, now: now).label;

    expect(label('pending'), 'Chờ phụ huynh phản hồi');
    expect(label('accepted'), 'Phụ huynh đã đồng ý');
    expect(label('confirmed'), 'Phụ huynh đã xác nhận');
    expect(label('alternate_requested'), 'Phụ huynh đề xuất giờ khác');
    expect(label('adjustment_requested'), 'Phụ huynh yêu cầu điều chỉnh');
    expect(label('superseded'), 'Đã có đề xuất mới');
  });

  test('an unanswered proposal past its expiry is shown as expired', () {
    final now = DateTime.utc(2026, 11, 9);
    final past = Timestamp.fromDate(DateTime.utc(2026, 11, 8));
    final future = Timestamp.fromDate(DateTime.utc(2026, 11, 12));
    expect(
      tutorProposalStatus({
        'status': 'pending',
        'expiresAt': past,
      }, now: now).label,
      'Đề xuất đã hết hạn',
    );
    expect(
      tutorProposalStatus({
        'status': 'pending',
        'expiresAt': future,
      }, now: now).label,
      'Chờ phụ huynh phản hồi',
    );
    // A response that already happened wins over a past expiry.
    expect(
      tutorProposalStatus({
        'status': 'accepted',
        'expiresAt': past,
      }, now: now).label,
      'Phụ huynh đã đồng ý',
    );
  });
}
