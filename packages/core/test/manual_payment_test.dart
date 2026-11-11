import 'package:beewise_core/beewise_core.dart';
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
}
