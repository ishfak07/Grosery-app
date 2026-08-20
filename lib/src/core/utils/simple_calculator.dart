/// Immutable state for [SimpleCalculator] — a basic one-operation-at-a-time
/// calculator (not a full expression parser), matching how a physical
/// pocket calculator behaves.
class CalculatorState {
  const CalculatorState({
    this.display = '0',
    this.storedValue,
    this.pendingOperator,
    this.shouldResetDisplay = false,
  });

  final String display;
  final double? storedValue;

  /// One of '+', '-', '×', '÷', or null when no operation is pending.
  final String? pendingOperator;

  /// True right after an operator/equals/percent press, so the next digit
  /// typed starts a fresh number instead of appending to [display].
  final bool shouldResetDisplay;

  CalculatorState copyWith({
    String? display,
    double? storedValue,
    bool clearStoredValue = false,
    String? pendingOperator,
    bool clearPendingOperator = false,
    bool? shouldResetDisplay,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      storedValue:
          clearStoredValue ? null : (storedValue ?? this.storedValue),
      pendingOperator: clearPendingOperator
          ? null
          : (pendingOperator ?? this.pendingOperator),
      shouldResetDisplay: shouldResetDisplay ?? this.shouldResetDisplay,
    );
  }
}

/// Pure, side-effect-free calculator logic kept separate from any widget so
/// it can be unit tested directly. Every method takes the current state and
/// returns the next state.
class SimpleCalculator {
  const SimpleCalculator._();

  static const initial = CalculatorState();

  static CalculatorState inputDigit(CalculatorState state, String digit) {
    if (state.display == 'Error') {
      return CalculatorState(display: digit);
    }
    if (state.shouldResetDisplay || state.display == '0') {
      return state.copyWith(display: digit, shouldResetDisplay: false);
    }
    return state.copyWith(display: state.display + digit);
  }

  static CalculatorState inputDecimal(CalculatorState state) {
    if (state.display == 'Error' || state.shouldResetDisplay) {
      return state.copyWith(display: '0.', shouldResetDisplay: false);
    }
    if (state.display.contains('.')) {
      return state;
    }
    return state.copyWith(display: '${state.display}.');
  }

  static CalculatorState backspace(CalculatorState state) {
    if (state.display == 'Error' || state.shouldResetDisplay) {
      return state.copyWith(display: '0', shouldResetDisplay: false);
    }
    final trimmed = state.display.substring(0, state.display.length - 1);
    return state.copyWith(display: trimmed.isEmpty ? '0' : trimmed);
  }

  static CalculatorState clear() => initial;

  static CalculatorState inputOperator(CalculatorState state, String operator) {
    if (state.display == 'Error') {
      return CalculatorState(pendingOperator: operator, storedValue: 0);
    }
    final current = double.tryParse(state.display) ?? 0;
    if (state.pendingOperator != null && !state.shouldResetDisplay) {
      final result = _apply(
        state.storedValue ?? 0,
        current,
        state.pendingOperator!,
      );
      if (result == null) {
        return const CalculatorState(display: 'Error');
      }
      return CalculatorState(
        display: _format(result),
        storedValue: result,
        pendingOperator: operator,
        shouldResetDisplay: true,
      );
    }
    return state.copyWith(
      storedValue: current,
      pendingOperator: operator,
      shouldResetDisplay: true,
    );
  }

  static CalculatorState equals(CalculatorState state) {
    if (state.display == 'Error' ||
        state.pendingOperator == null ||
        state.storedValue == null) {
      return state;
    }
    final current = double.tryParse(state.display) ?? 0;
    final result = _apply(state.storedValue!, current, state.pendingOperator!);
    if (result == null) {
      return const CalculatorState(display: 'Error');
    }
    return CalculatorState(
      display: _format(result),
      shouldResetDisplay: true,
    );
  }

  /// Retail-calculator style percentage: with a pending operator (e.g.
  /// `500 + 10%`), `%` treats the current number as a percentage of the
  /// stored value (10% of 500 = 50). Standalone, it just divides by 100.
  static CalculatorState percent(CalculatorState state) {
    if (state.display == 'Error') {
      return state;
    }
    final current = double.tryParse(state.display) ?? 0;
    final percentValue = state.pendingOperator != null
        ? (state.storedValue ?? 0) * current / 100
        : current / 100;
    return state.copyWith(
      display: _format(percentValue),
      shouldResetDisplay: true,
    );
  }

  static double? _apply(double a, double b, String operator) {
    switch (operator) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) {
          return null;
        }
        return a / b;
      default:
        return b;
    }
  }

  static String _format(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    var text = value.toStringAsFixed(6);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }
}
