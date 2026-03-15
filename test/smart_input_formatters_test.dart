import 'package:flutter_test/flutter_test.dart';
import 'package:smart_input_formatters/smart_input_formatters.dart';

void main() {
  group('SmartAmountFormatter Integration Tests', () {
    test('Should format large numbers with group separators', () {
      final formatter = SmartAmountFormatter(
        decimalSep: '.',
        groupSep: ',',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '1000');

      var result = newValue;
      for (var f in formatter.formatters) {
        result = f.formatEditUpdate(oldValue, result);
      }

      expect(result.text, '1,000');
    });

    test('Should handle math expressions without breaking grouping', () {
      final formatter = SmartAmountFormatter(
        decimalSep: '.',
        groupSep: ',',
      );

      const newValue = TextEditingValue(text: '1000+500');

      var result = newValue;
      for (var f in formatter.formatters) {
        result = f.formatEditUpdate(TextEditingValue.empty, result);
      }

      // Logic: 1000 becomes 1,000 and 500 stays 500
      expect(result.text, '1,000+500');
    });
  });
}
