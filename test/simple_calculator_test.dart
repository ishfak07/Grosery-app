import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/utils/simple_calculator.dart';

void main() {
  test('adds two numbers', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '5');
    state = SimpleCalculator.inputOperator(state, '+');
    state = SimpleCalculator.inputDigit(state, '3');
    state = SimpleCalculator.equals(state);

    expect(state.display, '8');
  });

  test('subtracts, multiplies, and divides', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '9');
    state = SimpleCalculator.inputOperator(state, '-');
    state = SimpleCalculator.inputDigit(state, '4');
    state = SimpleCalculator.equals(state);
    expect(state.display, '5');

    state = SimpleCalculator.clear();
    state = SimpleCalculator.inputDigit(state, '6');
    state = SimpleCalculator.inputOperator(state, '×');
    state = SimpleCalculator.inputDigit(state, '7');
    state = SimpleCalculator.equals(state);
    expect(state.display, '42');

    state = SimpleCalculator.clear();
    state = SimpleCalculator.inputDigit(state, '9');
    state = SimpleCalculator.inputOperator(state, '÷');
    state = SimpleCalculator.inputDigit(state, '2');
    state = SimpleCalculator.equals(state);
    expect(state.display, '4.5');
  });

  test('percent applies relative to the stored value when chained', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '5');
    state = SimpleCalculator.inputDigit(state, '0');
    state = SimpleCalculator.inputDigit(state, '0');
    state = SimpleCalculator.inputOperator(state, '+');
    state = SimpleCalculator.inputDigit(state, '1');
    state = SimpleCalculator.inputDigit(state, '0');
    state = SimpleCalculator.percent(state);
    state = SimpleCalculator.equals(state);

    expect(state.display, '550');
  });

  test('standalone percent divides the current value by 100', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '5');
    state = SimpleCalculator.inputDigit(state, '0');
    state = SimpleCalculator.percent(state);

    expect(state.display, '0.5');
  });

  test('division by zero produces an error state that clears cleanly', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '5');
    state = SimpleCalculator.inputOperator(state, '÷');
    state = SimpleCalculator.inputDigit(state, '0');
    state = SimpleCalculator.equals(state);
    expect(state.display, 'Error');

    state = SimpleCalculator.inputDigit(state, '2');
    expect(state.display, '2');
  });

  test('backspace and clear reset input as expected', () {
    var state = SimpleCalculator.initial;
    state = SimpleCalculator.inputDigit(state, '1');
    state = SimpleCalculator.inputDigit(state, '2');
    state = SimpleCalculator.inputDigit(state, '3');
    state = SimpleCalculator.backspace(state);
    expect(state.display, '12');

    state = SimpleCalculator.clear();
    expect(state.display, '0');
  });
}
