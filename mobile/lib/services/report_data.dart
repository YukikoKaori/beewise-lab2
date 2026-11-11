import 'dart:convert';
import 'dart:typed_data';

/// Bounds shared with firestore.rules. The 4 KiB allowance exceeds the bounded
/// metadata, document name and Firestore field overhead for this schema.
class ReportData {
  static const maxPdfBytes = 500 * 1024;
  static const maxEncodedLength = 682668;
  static const maxEstimatedDocumentBytes = 768 * 1024;
  static const contentType = 'application/pdf';

  static void validatePdf(List<int> bytes) {
    if (bytes.length < 5 ||
        bytes.length > maxPdfBytes ||
        ascii.decode(bytes.take(5).toList(), allowInvalid: true) != '%PDF-') {
      throw const ExportException('PDF không hợp lệ hoặc lớn hơn 500 KiB.');
    }
  }

  static String encode(List<int> bytes) {
    validatePdf(bytes);
    final encoded = base64Encode(bytes);
    if (encoded.length > maxEncodedLength) {
      throw const ExportException('PDF vượt giới hạn lưu trữ.');
    }
    return encoded;
  }

  static Uint8List decode(Map<String, dynamic> data) {
    final encoded = data['base64Data'];
    final size = data['sizeBytes'];
    if (data['contentType'] != contentType ||
        data['encoding'] != 'base64' ||
        encoded is! String ||
        encoded.isEmpty ||
        encoded.length > maxEncodedLength ||
        size is! int ||
        size <= 0 ||
        size > maxPdfBytes) {
      throw const ExportException('Dữ liệu PDF trên server không hợp lệ.');
    }
    try {
      final bytes = base64Decode(encoded);
      validatePdf(bytes);
      if (bytes.length != size || base64Encode(bytes) != encoded) {
        throw const ExportException('Dữ liệu PDF bị hỏng.');
      }
      return bytes;
    } on FormatException {
      throw const ExportException('Dữ liệu PDF bị hỏng.');
    }
  }

  static int estimatedDocumentBytes(Map<String, dynamic> data, String path) =>
      data.entries.fold<int>(
        utf8.encode(path).length + 4096,
        (size, field) =>
            size +
            utf8.encode(field.key).length +
            (field.value is String
                ? utf8.encode(field.value as String).length
                : 16),
      );
}

class ExportException implements Exception {
  const ExportException(this.message);
  final String message;
  @override
  String toString() => message;
}
