# Smart Input Formatters

A robust set of Flutter `TextInputFormatter`s designed for financial applications.  
Handle currency formatting, mathematical expressions, and auto-decimal shifting with industry-level cursor stability.

---

## Features

- **🧮 Expression Support**  
  Formats numbers dynamically even inside math expressions.  
  Example: `1000+500` → `1,000+500`.

- **🎯 Cursor Stability**  
  Prevents cursor jumping by intelligently preserving selection position when separators are inserted or removed.

- **🏦 Auto-Decimal Shifting**  
  Ideal for POS and banking apps.  
  Example:
    - Typing `5` → `0.05`
    - Typing `50` → `0.50`

- **🌍 Locale-Aware**  
  Fully configurable decimal and grouping separators to support any regional currency format.

- **🧹 Clean Input**  
  Automatically normalizes mathematical operators and trims unnecessary leading zeros.  
  Example:
    - `x` → `*`
    - `000123` → `123`

---

# Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  smart_input_formatters: ^0.0.1
```

Then import it:

```dart
import 'package:smart_input_formatters/smart_input_formatters.dart';
```

---

# Usage

The easiest way to use this package is through the **`SmartAmountFormatter` wrapper**, which automatically manages the correct order of formatters.

---

## Classic Calculator Mode

Use this for standard price inputs where you want thousands separators and math expression support.

```dart
TextFormField(
  inputFormatters: SmartAmountFormatter(
    decimalSep: '.',
    groupSep: ',',
    autoDec: false, // Default
  ).formatters,
  keyboardType: TextInputType.text,
  decoration: InputDecoration(
    labelText: 'Amount',
  ),
);
```

Example inputs:

| Input | Output |
|------|------|
| `1000` | `1,000` |
| `1000+500` | `1,000+500` |
| `20000*3` | `20,000*3` |

---

## Banking / Auto-Decimal Mode

Common in POS systems and banking applications where digits are entered continuously and the decimal shifts from the right.

```dart
TextFormField(
  inputFormatters: SmartAmountFormatter(
    decimalSep: '.',
    groupSep: ',',
    autoDec: true,
    decimalDigits: 2,
  ).formatters,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    hintText: '0.00',
  ),
);
```

Example behavior:

| Input | Output |
|------|------|
| `5` | `0.05` |
| `50` | `0.50` |
| `500` | `5.00` |
| `12345` | `123.45` |

---

# How It Works (Formatting Pipeline)

`SmartAmountFormatter` runs a sequence of specialized formatters in a controlled pipeline to ensure clean and predictable input.

### 1. CalculatorNormalizer
Standardizes operators and separators.

Examples:
- `x` → `*`
- `.` ↔ `,` depending on locale

---

### 2. LeadingZeroIntegerTrimmer
Removes redundant leading zeros.

Examples:
- `000123` → `123`
- `0000` → `0`

---

### 3. AutoDecimalShiftFormatter *(optional)*

Applies fixed-point decimal shifting when `autoDec` is enabled.

Example with `decimalDigits = 2`:

| Raw Input | Output |
|----------|--------|
| `5` | `0.05` |
| `50` | `0.50` |
| `500` | `5.00` |

---

### 4. GroupSeparatorFormatter

Injects thousands separators while preserving cursor position.

Examples:

| Input | Output |
|------|------|
| `1000` | `1,000` |
| `1000000` | `1,000,000` |

Cursor position remains stable even when commas are inserted.

---

# Additional Information

## Contributions

This package was created to solve production currency-input challenges in the **Oinkoin** project.

Contributions, suggestions, and bug reports are welcome.

You can contribute by:

- Opening issues
- Submitting pull requests
- Improving documentation

---

# License

MIT License — free for personal and commercial use.

---

⭐ If you find this package useful, consider starring the repository!
