# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.2] - 2026-04-01

### Added

- `allowExpression` parameter on `SmartAmountFormatter` — controls whether
  math operators (`+`, `-`, `*`, `/`, `%`) are accepted as valid input.
  Defaults to `true` to preserve existing behaviour.
- `FilteringTextInputFormatter.deny` is now inserted as the first step in the
  formatter pipeline, rejecting any character outside the allowed set (digits,
  configured separators, and optionally operators) before any downstream
  formatter processes the input.

### Fixed

- Junk characters (letters, symbols) could previously pass through the pipeline
  unchecked. The new deny filter closes this gap.

---

## [0.0.1] - 2026-03-15

Initial release.

### Added

- `SmartAmountFormatter` — composable entry point that assembles a
  `List<TextInputFormatter>` for currency and numeric input fields.
- `CalculatorNormalizer` — normalises raw input by mapping `x` → `*` and
  remapping `.` or `,` to the configured `decimalSep`.
- `LeadingZeroIntegerTrimmerFormatter` — strips redundant leading zeros from
  the integer part of simple numeric values.
- `AutoDecimalShiftFormatter` — cash-register style decimal shifting; digits
  are shifted right as the user types so the decimal separator is inserted
  automatically at the configured `decimalDigits` position.
- `GroupSeparatorFormatter` — inserts thousands separators into the integer
  part of each numeric segment with cursor-stable offset recalculation.
- Support for locale-aware separator configuration via `decimalSep` and
  `groupSep` parameters.
- Support for expression input (`12.50+3.00`) across all formatters.
