import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/tutor.dart';

class ExportedReport {
  const ExportedReport({required this.file, required this.sizeBytes});
  final File file;
  final int sizeBytes;
}

class UploadResult {
  const UploadResult(this.downloadUrl, this.storagePath);
  final String downloadUrl;
  final String storagePath;
}

class ExportService {
  ExportService(this._storage);
  final FirebaseStorage? _storage;

  Future<ExportedReport> buildTutorSummary(Tutor tutor) async {
    final fontData = await rootBundle.load(
      'assets/fonts/BeVietnamPro-Regular.ttf',
    );
    final boldData = await rootBundle.load(
      'assets/fonts/BeVietnamPro-Bold.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final bold = pw.Font.ttf(boldData);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'BeeWise - Thông tin gia sư',
            style: pw.TextStyle(font: bold, fontSize: 22),
          ),
          pw.SizedBox(height: 16),
          pw.Text(tutor.name, style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 8),
          _row('Chuyên môn', tutor.subjects.join(', '), font, bold),
          _row('Lớp', tutor.grades.join(', '), font, bold),
          _row('Học phí', '${tutor.hourlyFee}đ/giờ', font, bold),
          _row('Khu vực', tutor.areas.join(', '), font, bold),
          _row('Hình thức', tutor.teachingModes.join(', '), font, bold),
          _row('Lịch rảnh', tutor.availability, font, bold),
          _row('Kinh nghiệm', '${tutor.experienceYears} năm', font, bold),
          _row(
            'Xác minh',
            tutor.verified ? 'Đã xác minh' : 'Chưa xác minh',
            font,
            bold,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            tutor.introduction,
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thông tin được lấy từ hồ sơ gia sư BeeWise tại thời điểm xuất.',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
    final bytes = await document.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/beewise-tutor-${tutor.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return ExportedReport(file: file, sizeBytes: bytes.length);
  }

  pw.Widget _row(String label, String value, pw.Font regular, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 115,
              child: pw.Text(
                label,
                style: pw.TextStyle(font: bold, fontSize: 11),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? 'Chưa có thông tin' : value,
                style: pw.TextStyle(font: regular, fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Future<UploadResult> upload({
    required String uid,
    required ExportedReport report,
    required void Function(double progress) onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw const ExportException('Cloud Storage chưa được cấu hình.');
    }
    final path = 'reports/$uid/${report.file.uri.pathSegments.last}';
    final reference = storage.ref(path);
    final task = reference.putFile(
      report.file,
      SettableMetadata(contentType: 'application/pdf'),
    );
    TaskState? finalState;
    await for (final snapshot in task.snapshotEvents) {
      finalState = snapshot.state;
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    }
    if (finalState != TaskState.success) {
      throw const ExportException('Tải tệp chưa hoàn tất. Hãy thử lại.');
    }
    return UploadResult(await reference.getDownloadURL(), path);
  }
}

class ExportException implements Exception {
  const ExportException(this.message);
  final String message;
  @override
  String toString() => message;
}
