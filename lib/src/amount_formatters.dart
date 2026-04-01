import 'package:flutter/services.dart';

/// A composable formatter that assembles a pipeline of [TextInputFormatter]s
/// for currency and numeric input fields.
///
/// Use [formatters] to obtain the assembled list and pass it directly to
/// [TextField.inputFormatters] or [TextFormField.inputFormatters].
///
/// ## Basic usage
///
/// ```dart
/// TextField(
///   inputFormatters: SmartAmountFormatter(
///     decimalSep: '.',
///     groupSep: ',',
///   ).formatters,
/// )
/// ```
///
/// ## Auto-decimal mode
///
/// When [autoDec] is `true`, digits are shifted right as the user types so
/// the decimal point is inserted automatically:
///
/// ```dart
/// SmartAmountFormatter(
///   decimalSep: '.',
///   groupSep: ',',
///   decimalDigits: 2,
///   autoDec: true,
/// )
/// // Typing "599" produces "5.99"
/// ```
///
/// ## Locale-aware separators
///
/// Pass the locale's decimal and grouping characters to support formats such
/// as European `1.234,56`:
///
/// ```dart
/// SmartAmountFormatter(
///   decimalSep: ',',
///   groupSep: '.',
///   overwriteDot: true,
///   overwriteComma: false,
/// )
/// ```
/// ## Disabling expression input
///
/// By default, math operators (`+`, `-`, `*`, `/`, `%`) are permitted so the
/// field can be used as a calculator input. Pass [allowExpression] as `false`
/// for plain currency fields where only a single numeric value is expected:
///
/// ```dart
/// SmartAmountFormatter(
///   decimalSep: '.',
///   groupSep: ',',
///   allowExpression: false,
/// )
/// // Input "12+5" is rejected — only "12.50" style values are accepted.
/// ```
/// ## Pipeline order
///
/// The formatters are applied in this sequence:
///
/// 1. [CalculatorNormalizer] — normalises raw input (`x` → `*`, remaps `.`/`,`).
/// 2. [LeadingZeroIntegerTrimmerFormatter] — strips redundant leading zeros.
/// 3. [AutoDecimalShiftFormatter] *(when [autoDec] is `true`)* — shifts digits
///    to insert the decimal point automatically.
/// 4. [GroupSeparatorFormatter] *(when [autoDec] is `false`)* — inserts
///    thousands separators and manages cursor stability.
///
/// See also:
///
/// * [AutoDecimalShiftFormatter], for the auto-decimal shift behaviour.
/// * [GroupSeparatorFormatter], for thousands-separator and cursor logic.
class SmartAmountFormatter {
  final String decimalSep;
  final String groupSep;
  final int decimalDigits;
  final bool autoDec;
  final bool overwriteDot;
  final bool overwriteComma;
  final bool allowExpression;

  /// Creates a [SmartAmountFormatter] with the given separator configuration.
  ///
  /// The [decimalSep] and [groupSep] are required and must not be equal to
  /// each other, as the underlying formatters use them to distinguish integer
  /// and fractional parts.
  ///
  /// ### Parameters
  ///
  /// - [decimalSep] — the character used to separate the integer part from the
  ///   fractional part (e.g. `'.'` for `1234.56`, `','` for `1234,56`).
  ///
  /// - [groupSep] — the character used to group digits in the integer part
  ///   (e.g. `','` for `1,234,567`, `'.'` for `1.234.567`).
  ///
  /// - [decimalDigits] — the number of fractional digits. Defaults to `2`.
  ///   Only meaningful when [autoDec] is `true`; ignored by
  ///   [GroupSeparatorFormatter].
  ///
  /// - [autoDec] — when `true`, digits are automatically shifted so the
  ///   decimal separator is inserted at the position determined by
  ///   [decimalDigits] (cash-register style). When `false` (the default),
  ///   the user places the decimal separator manually and thousands separators
  ///   are inserted visually by [GroupSeparatorFormatter].
  ///
  /// - [overwriteDot] — when `true` (the default), a typed `'.'` is silently
  ///   replaced with [decimalSep]. Set to `false` if the host keyboard already
  ///   emits the correct separator.
  ///
  /// - [overwriteComma] — when `true` (the default), a typed `','` is silently
  ///   replaced with [decimalSep]. Set to `false` to treat `','` as a literal
  ///   character (e.g. when [decimalSep] is `','` and [groupSep] is `'.'`).
  ///
  /// - [allowExpression] — when `true` (the default), the operator characters
  ///   `+`, `-`, `*`, `/`, and `%` are included in the allowed input set,
  ///   enabling calculator-style expressions such as `12.50+3.00`. Set to
  ///   `false` for plain currency fields where only a single numeric value is
  ///   expected; any operator character will be rejected before reaching the
  ///   downstream formatters.
  ///
  /// ### Throws
  ///
  /// Does not throw directly, but passing identical values for [decimalSep]
  /// and [groupSep] will produce undefined formatting behaviour at runtime.
  SmartAmountFormatter({
    required this.decimalSep,
    required this.groupSep,
    this.decimalDigits = 2,
    this.autoDec = false,
    this.overwriteDot = true,
    this.overwriteComma = true,
    this.allowExpression = true,
  });

  List<TextInputFormatter> get formatters {
    final escapedDecimal = RegExp.escape(decimalSep);
    final escapedGroup = RegExp.escape(groupSep);

    final operators = allowExpression ? r'\+\-\*/%' : '';

    final allowedRegex = RegExp(
      '[^0-9$operators$escapedDecimal$escapedGroup]',
    );
    return [
      FilteringTextInputFormatter.deny(allowedRegex),
      CalculatorNormalizer(
        overwriteDot: overwriteDot,
        overwriteComma: overwriteComma,
        decimalSep: decimalSep,
        groupSep: groupSep,
      ),
      LeadingZeroIntegerTrimmerFormatter(
        decimalSep: decimalSep,
        groupSep: groupSep,
      ),
      if (autoDec)
        AutoDecimalShiftFormatter(
          decimalDigits: decimalDigits,
          decimalSep: decimalSep,
          groupSep: groupSep,
        ),
      if (!autoDec)
        GroupSeparatorFormatter(
          decimalSep: decimalSep,
          groupSep: groupSep,
        ),
    ];
  }
}

/// Automatically shifts digits to create decimal numbers based on the configured
/// number of decimal places.
///
/// This formatter assumes the user is typing the entire number including decimal
/// places, and automatically inserts the decimal separator at the correct position.
///
/// Example with 2 decimal places:
/// - Typing "5" becomes "0.05"
/// - Typing "50" becomes "0.50"
/// - Typing "5099" becomes "50.99"
///
/// The formatter also supports mathematical expressions and preserves operators:
/// - "50+25" becomes "0.50+0.25"
///
/// Note: This formatter always places the cursor at the end of the text after
/// formatting. It should be used before GroupSeparatorFormatter in the inputFormatters
/// list to ensure proper group separator insertion.
class AutoDecimalShiftFormatter extends TextInputFormatter {
  /// The number of decimal digits to shift (e.g., 2 for cents)
  final int decimalDigits;

  /// The decimal separator character (e.g., "." or ",")
  final String decimalSep;

  /// The grouping separator character (e.g., "," or ".")
  final String groupSep;

  AutoDecimalShiftFormatter({
    required this.decimalDigits,
    required this.decimalSep,
    required this.groupSep,
  });

  bool _isOp(String c) =>
      c == '+' || c == '-' || c == '*' || c == '/' || c == '%';

  /// Strips all non-digit characters (including separators) to get clean digits
  String _onlyDigits(String s) {
    return s
        .replaceAll(groupSep, '')
        .replaceAll(decimalSep, '')
        .replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Formats a string of digits by inserting the decimal separator
  /// at the position determined by decimalDigits
  String _formatDigits(String digits) {
    if (digits.isEmpty) return '';

    String left;
    String right;

    if (digits.length <= decimalDigits) {
      // Not enough digits: pad with leading zeros
      left = '0';
      right = digits.padLeft(decimalDigits, '0');
    } else {
      // Split digits at the decimal position from the right
      final cut = digits.length - decimalDigits;
      left = digits.substring(0, cut);
      right = digits.substring(cut);
    }

    // Remove unnecessary leading zeros from integer part, but keep at least one
    left = left.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (left.isEmpty) left = '0';

    return '$left$decimalSep$right';
  }

  /// Formats a number token (potentially with unary sign)
  String _formatNumberToken(String token) {
    if (token.isEmpty) return '';

    final hasSign = token.startsWith('-') || token.startsWith('+');
    final sign = hasSign ? token[0] : '';
    final body = hasSign ? token.substring(1) : token;

    final digits = _onlyDigits(body);
    final formatted = _formatDigits(digits);

    if (formatted.isEmpty) return sign;

    return '$sign$formatted';
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Skip formatting if no decimal places configured
    if (decimalDigits <= 0) return newValue;

    final input = newValue.text;
    if (input.isEmpty) return newValue;

    final s = input.trimLeft();

    // Handle global sign at the start
    final globalSign = (s.startsWith('-') || s.startsWith('+')) ? s[0] : '';
    final body = globalSign.isEmpty ? s : s.substring(1);

    // Tokenize the input, respecting operators and unary signs
    final tokens = <String>[];
    var cur = '';

    for (var i = 0; i < body.length; i++) {
      final c = body[i];

      if (_isOp(c)) {
        // Check if this is a unary operator (+- after another operator or at start)
        final prevIsOp =
            tokens.isNotEmpty && _isOp(tokens.last) && tokens.last.length == 1;
        final unary = (c == '-' || c == '+') &&
            cur.isEmpty &&
            (tokens.isEmpty || prevIsOp);

        if (unary) {
          cur += c;
          continue;
        }

        if (cur.isNotEmpty) {
          tokens.add(cur);
          cur = '';
        }
        tokens.add(c);
      } else {
        cur += c;
      }
    }
    if (cur.isNotEmpty) tokens.add(cur);

    // Build the output string
    final out = StringBuffer();
    if (globalSign.isNotEmpty) out.write(globalSign);

    for (final t in tokens) {
      if (t.length == 1 && _isOp(t)) {
        out.write(t);
      } else {
        out.write(_formatNumberToken(t));
      }
    }

    final outStr = out.toString();

    // Always place cursor at the end (user is typing sequentially)
    return TextEditingValue(
      text: outStr,
      selection: TextSelection.collapsed(offset: outStr.length),
    );
  }
}

/// Removes unnecessary leading zeros from the integer part of a number.
///
/// This formatter trims leading zeros from the integer portion while preserving
/// the decimal part and signs. It only processes simple numbers, not mathematical
/// expressions (those are passed through unchanged).
///
/// Examples:
/// - "005" becomes "5"
/// - "000" becomes "0"
/// - "005.50" becomes "5.50"
/// - "005+003" stays "005+003" (expressions not modified)
///
/// This formatter should run after GroupSeparatorFormatter in the inputFormatters
/// list to ensure group separators are handled correctly.
class LeadingZeroIntegerTrimmerFormatter extends TextInputFormatter {
  /// The decimal separator character (e.g., "." or ",")
  final String decimalSep;

  /// The grouping separator character (e.g., "," or ".")
  final String groupSep;

  LeadingZeroIntegerTrimmerFormatter({
    required this.decimalSep,
    required this.groupSep,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;

    // Skip processing for mathematical expressions
    final bodyForOps =
        (t.startsWith('-') || t.startsWith('+')) ? t.substring(1) : t;
    if (RegExp(r'[+\-*/%]').hasMatch(bodyForOps)) return newValue;

    // Extract sign if present
    final sign = (t.startsWith('-') || t.startsWith('+')) ? t[0] : '';
    final body = sign.isEmpty ? t : t.substring(1);

    // Split into integer and fractional parts
    final decIdx = body.indexOf(decimalSep);
    final intPartRaw = decIdx >= 0 ? body.substring(0, decIdx) : body;
    final fracPart = decIdx >= 0 ? body.substring(decIdx) : '';

    // Strip group separators for processing
    var intDigits = intPartRaw.replaceAll(groupSep, '');

    if (intDigits.isEmpty) return newValue;

    // Remove leading zeros, but keep at least one digit
    intDigits = intDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intDigits.isEmpty) intDigits = '0';

    final out = '$sign$intDigits$fracPart';

    // Return unchanged if no modification needed
    if (out == t) return newValue;

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// A pre-processor that standardizes user input into a math-ready format.
class CalculatorNormalizer extends TextInputFormatter {
  final bool overwriteDot;
  final bool overwriteComma;
  final String groupSep;
  final String decimalSep;

  /// This formatter handles:
  /// * **Character Swapping:** Converts user-friendly input (e.g., 'x') into
  ///   the standard mathematical operator ('*').
  /// * **Dynamic Normalization:** Swaps '.' or ',' into the active decimal
  ///   separator based on app settings as the user types.
  /// * **Non-Destructive Editing:** Targets the [selectionIndex] only,
  ///   ensuring thousands-separators are not interfered with during input.
  CalculatorNormalizer(
      {required this.overwriteDot,
      required this.overwriteComma,
      required this.decimalSep,
      required this.groupSep});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.toLowerCase().replaceAll("x", "*");

    // We compare the length to ensure the user is adding text, not deleting
    if (newText.length > oldValue.text.length) {
      int selectionIndex = newValue.selection.baseOffset;
      if (selectionIndex > 0) {
        String charTyped =
            newText.substring(selectionIndex - 1, selectionIndex);
        if (overwriteDot && charTyped == ".") {
          newText = newText.replaceRange(
              selectionIndex - 1, selectionIndex, decimalSep);
        } else if (overwriteComma && charTyped == ",") {
          newText = newText.replaceRange(
              selectionIndex - 1, selectionIndex, decimalSep);
        }
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
    );
  }
}

/// A post-processor and decorator responsible for visual presentation
/// and numeric segment logic.
class GroupSeparatorFormatter extends TextInputFormatter {
  final String groupSep;
  final String decimalSep;

  /// This formatter handles:
  /// 1. **Expression Awareness:** Splits input strings by operators
  ///    (e.g., '1000+500' → `['1000', '500']`) to group numbers independently.
  /// 2. **Double-Decimal Prevention:** Validates numeric segments to prevent
  ///    invalid math formats like '10.5.5'.
  /// 3. **Visual Grouping:** Injects thousands-separators into integer portions
  ///    using a lookahead [RegExp].
  /// 4. **Cursor Management:** Implements custom `_calculateOffset` logic to
  ///    maintain cursor stability when separators are dynamically added or removed.
  const GroupSeparatorFormatter(
      {required this.groupSep, required this.decimalSep});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    String raw = newValue.text.replaceAll(groupSep, "");

    final segments = raw.split(RegExp(r'([+\-*/%])'));
    final operators =
        RegExp(r'[+\-*/%]').allMatches(raw).map((m) => m.group(0)).toList();

    List<String> formatted = [];
    for (var seg in segments) {
      if (seg.isEmpty) {
        formatted.add("");
        continue;
      }

      if (decimalSep.allMatches(seg).length > 1) {
        return oldValue;
      }

      // Split into Integer and Decimal
      List<String> parts = seg.split(decimalSep);
      String intPart = parts[0];

      // Apply grouping to integer part
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      intPart = intPart.replaceAllMapped(reg, (m) => '${m[1]}$groupSep');

      formatted
          .add(parts.length > 1 ? "$intPart$decimalSep${parts[1]}" : intPart);
    }

    String result = "";
    for (int i = 0; i < formatted.length; i++) {
      result += formatted[i];
      if (i < operators.length) result += operators[i]!;
    }

    int offset = _calculateOffset(newValue, result);

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  int _calculateOffset(TextEditingValue newValue, String formatted) {
    // If selection is invalid, keep cursor at end of formatted text.
    final int rawCursorPos = newValue.selection.baseOffset;
    if (rawCursorPos < 0) return formatted.length;

    final int cursorPos = rawCursorPos.clamp(0, newValue.text.length);

    // Count how many non-separator characters are before the cursor in the
    // *current* text, treating groupSep as possibly multi-character.
    int cleanCursorUnits = 0;
    int i = 0;
    while (i < cursorPos) {
      if (groupSep.isNotEmpty &&
          i + groupSep.length <= cursorPos &&
          newValue.text.startsWith(groupSep, i)) {
        i += groupSep.length;
        continue;
      }
      cleanCursorUnits++;
      i++;
    }

    // Map that clean count onto the formatted string.
    int formattedPos = 0;
    int cleanSeen = 0;
    while (formattedPos < formatted.length && cleanSeen < cleanCursorUnits) {
      if (groupSep.isNotEmpty &&
          formattedPos + groupSep.length <= formatted.length &&
          formatted.startsWith(groupSep, formattedPos)) {
        formattedPos += groupSep.length;
        continue;
      }
      cleanSeen++;
      formattedPos++;
    }

    return formattedPos.clamp(0, formatted.length);
  }
}
