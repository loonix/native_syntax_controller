import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:native_syntax_controller/native_syntax_controller.dart';
import 'dart:convert';

void main() {
  test('evaluateFormula basic arithmetic', () {
    final result = evaluateFormula({}, '3 + 4');
    expect(result, 7);
  });

  test('evaluateFormula with context', () {
    final result = evaluateFormula({'a': 5, 'b': 3}, 'a * b');
    expect(result, 15);
  });

  test('evaluateFormula with custom functions', () {
    final result = evaluateFormula({'x': 10, 'y': 20}, 'SUM(x, y)');
    expect(result, 30);
  });

  test('evaluateFormula with map access', () {
    final json = {
      'defects': [
        {'status': 'Pass', 'severity': 'High'},
        {'status': 'Fail', 'severity': 'Low'},
      ],
    };
    final result = evaluateFormula(json, "defects[0].status");
    expect(result, 'Pass');
  });

  group('Built-in Functions', () {
    test('if_ function', () {
      expect(if_(true, 'yes', 'no'), 'yes');
      expect(if_(false, 'yes', 'no'), 'no');
      expect(if_(1 > 0, 42, 0), 42);
      expect(if_(0 > 1, 42, 0), 0);
    });

    test('sin_ function', () {
      expect(sin_(0), closeTo(0, 0.001));
      expect(sin_(pi_ / 2), closeTo(1, 0.001));
      expect(sin_(pi_), closeTo(0, 0.001));
      expect(sin_('1.57'), closeTo(1, 0.001)); // String to num conversion
    });

    test('cos_ function', () {
      expect(cos_(0), closeTo(1, 0.001));
      expect(cos_(pi_ / 2), closeTo(0, 0.001));
      expect(cos_(pi_), closeTo(-1, 0.001));
      expect(cos_('0'), closeTo(1, 0.001)); // String to num conversion
    });

    test('pi_ constant', () {
      expect(pi_, closeTo(3.14159, 0.00001));
    });

    test('average function', () {
      expect(average(10), 10);
      expect(average(10, 20), 15);
      expect(average(10, 20, 30), 20);
      expect(average(10, 20, 30, 40), 25);
      expect(average('10', '20'), 15); // String conversion
      expect(average(null, 10, null, 20), 15); // Null handling
    });

    test('sum function', () {
      expect(sum(1), 1);
      expect(sum(1, 2), 3);
      expect(sum(1, 2, 3), 6);
      expect(sum(1, 2, 3, 4), 10);
      expect(sum(1, 2, 3, 4, 5), 15);
      expect(sum('1', '2', '3'), 6); // String conversion
      expect(sum(null, 1, null, 2, null), 3); // Null handling
    });

    test('arrayAny function', () {
      final array = [
        {'status': 'pass', 'id': 1},
        {'status': 'fail', 'id': 2},
        {'status': 'pass', 'id': 3},
      ];

      expect(arrayAny(array, 'status', 'fail'), true);
      expect(arrayAny(array, 'status', 'pass'), true);
      expect(arrayAny(array, 'status', 'unknown'), false);
      expect(arrayAny(array, 'id', 2), true);
      expect(arrayAny(array, 'id', 99), false);
      expect(arrayAny(null, 'status', 'pass'), false);
      expect(arrayAny([], 'status', 'pass'), false);
      expect(arrayAny('not an array', 'status', 'pass'), false);
    });

    test('arrayAll function', () {
      final array = [
        {'status': 'pass', 'id': 1},
        {'status': 'pass', 'id': 1},
        {'status': 'pass', 'id': 1},
      ];

      expect(arrayAll(array, 'status', 'pass'), true);
      expect(arrayAll(array, 'status', 'fail'), false);
      expect(arrayAll(array, 'id', 1), true); // All have id=1
      expect(arrayAll(null, 'status', 'pass'), false);
      expect(arrayAll([], 'status', 'pass'), false);
      expect(arrayAll('not an array', 'status', 'pass'), false);
    });
  });

  group('SyntaxHighlightingController', () {
    testWidgets('highlights functions', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = 'AVERAGE(C7,D7)';

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);
      expect(spans.children!.length, greaterThan(1)); // Should have multiple spans

      // Check that AVERAGE is highlighted as function
      final functionSpan = spans.children!.firstWhere((span) => (span as TextSpan).text == 'AVERAGE') as TextSpan;
      expect(functionSpan.text, 'AVERAGE');
      expect(functionSpan.style!.color, const Color(0xFF64B5F6)); // Function color
      expect(functionSpan.style!.fontWeight, FontWeight.bold);
    });

    testWidgets('highlights operators', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = '3 + 4';

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);
      // Should have spans for 3, space, +, space, 4

      // Find the + span
      final plusSpan = spans.children!.firstWhere((span) => (span as TextSpan).text == '+') as TextSpan;
      expect(plusSpan.style!.color, const Color(0xFFE57373)); // Operator color
      expect(plusSpan.style!.fontWeight, FontWeight.bold);
    });

    testWidgets('highlights numbers', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = '42';

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);
      expect(spans.children!.length, 1);

      final numberSpan = spans.children![0] as TextSpan;
      expect(numberSpan.text, '42');
      expect(numberSpan.style!.color, const Color(0xFF81C784)); // Number color
    });

    testWidgets('highlights strings', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = "'hello'";

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);
      expect(spans.children!.length, 1);

      final stringSpan = spans.children![0] as TextSpan;
      expect(stringSpan.text, "'hello'");
      expect(stringSpan.style!.color, const Color(0xFFCE93D8)); // String color
    });

    testWidgets('handles empty text', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = '';

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.text, '');
      expect(spans.children, isNull);
    });

    testWidgets('handles mixed content', (WidgetTester tester) async {
      final controller = SyntaxHighlightingController();
      controller.text = "IF(score > 50, 'Pass', 'Fail')";

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);
      expect(spans.children!.length, greaterThan(1));

      // Check that IF is highlighted as function
      final ifSpan = spans.children!.firstWhere((span) => (span as TextSpan).text == 'IF') as TextSpan;
      expect(ifSpan.style!.color, const Color(0xFF64B5F6));
    });

    testWidgets('supports custom colors', (WidgetTester tester) async {
      final customStyles = {
        'function': const TextStyle(color: Colors.red, fontWeight: FontWeight.normal),
        'operator': const TextStyle(color: Colors.blue, fontWeight: FontWeight.normal),
        'number': const TextStyle(color: Colors.green),
        'string': const TextStyle(color: Colors.purple),
      };

      final controller = SyntaxHighlightingController(customStyles: customStyles);
      controller.text = 'SUM(42)';

      final spans = controller.buildTextSpan(context: tester.element(find.byType(Container)), style: const TextStyle(), withComposing: false);

      expect(spans.children, isNotNull);

      // Check that SUM is highlighted with custom function color
      final sumSpan = spans.children!.firstWhere((span) => (span as TextSpan).text == 'SUM') as TextSpan;
      expect(sumSpan.style!.color, Colors.red);
      expect(sumSpan.style!.fontWeight, FontWeight.normal); // Should not be bold

      // Check that 42 is highlighted with custom number color
      final numberSpan = spans.children!.firstWhere((span) => (span as TextSpan).text == '42') as TextSpan;
      expect(numberSpan.style!.color, Colors.green);
    });
  });

  group('evaluateFormula with examples', () {
    final examples = [
      {'formula': "3+AVERAGE(C7,D7) > 10", 'json': '{"C7": 4, "D7": 10}', 'expected': false},
      {'formula': "vehicle_type == 'car' && mileage > 10000", 'json': '{"vehicle_type": "car", "mileage": 15000}', 'expected': true},
      {'formula': "IF(score > 50, 'Pass', 'Fail')", 'json': '{"score": 75}', 'expected': 'Pass'},
      {'formula': "vehicle_type == 'car' || vehicle_type == 'truck'", 'json': '{"vehicle_type": "car"}', 'expected': true},
      {'formula': "base_price * 1.15 + delivery_fee", 'json': '{"base_price": 100, "delivery_fee": 10}', 'expected': closeTo(125.0, 0.01)},
      {'formula': "IF(vehicle_age > 5, base_price * 0.8, base_price)", 'json': '{"vehicle_age": 7, "base_price": 100}', 'expected': 80.0},
      {'formula': "SUM(item_1_price, item_2_price, item_3_price)", 'json': '{"item_1_price": 50, "item_2_price": 30, "item_3_price": 20}', 'expected': 100},
      {'formula': "field_a + field_b * 0.15 > 100", 'json': '{"field_a": 80, "field_b": 200}', 'expected': true},
      {'formula': "defects[0].status == 'Pass'", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}', 'expected': true},
      {'formula': "defects[1].status == 'Fail'", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}', 'expected': true},
      {'formula': "inspection.passed && defects[0].severity == 'High'", 'json': '{"inspection": {"passed": true}, "defects": [{"status": "Pass", "severity": "High"}]}', 'expected': true},
      {'formula': "ARRAY_ANY(defects, 'status', 'Fail')", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}', 'expected': true},
      {'formula': "ARRAY_ALL(defects, 'status', 'Pass')", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Pass", "severity": "Low"}]}', 'expected': true},
      {
        'formula': "IF(ARRAY_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'High'), 'Critical Failure', 'Minor Failure'), 'All Passed')",
        'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "High"}]}',
        'expected': 'Critical Failure',
      },
      {
        'formula':
            "IF(vehicle_age > 10 && !ARRAY_ANY(defects, 'status', 'Fail'), IF(mileage < 50000, 'Excellent Condition', 'Good Condition'), IF(ARRAY_ALL(defects, 'severity', 'Low'), 'Needs Minor Repair', 'Needs Major Repair'))",
        'json': '{"vehicle_age": 12, "mileage": 30000, "defects": [{"status": "Pass", "severity": "Low"}]}',
        'expected': 'Excellent Condition',
      },
      {
        'formula':
            "IF(user_role == 'inspector' && inspection_date != null, IF(ARRAY_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'Critical'), 'Reject Vehicle', IF(vehicle_age > 15, 'Conditional Approval', 'Approve with Repairs')), IF(mileage > 100000, 'Schedule Maintenance', 'Full Approval')), 'Access Denied')",
        'json': '{"user_role": "inspector", "inspection_date": "2025-12-11", "vehicle_age": 8, "mileage": 60000, "defects": [{"status": "Pass", "severity": "Low"}]}',
        'expected': 'Full Approval',
      },
    ];

    for (int idx = 0; idx < examples.length; idx++) {
      final example = examples[idx];
      test('example ${idx + 1}: ${example['formula']}', () {
        final formula = example['formula'] as String;
        final jsonString = example['json'] as String;
        final expected = example['expected'];

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final result = evaluateFormula(json, formula);

        expect(result, expected);
      });
    }
  });

  group('Error handling', () {
    test('parsing error with position information', () {
      expect(() => evaluateFormula({}, '3 + '), throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Parse Error:'))));
    });

    test('evaluation error with position information', () {
      expect(() => evaluateFormula({}, 'undefined_variable + 1'), throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Evaluation Error:'))));
    });

    test('invalid syntax error shows position', () {
      expect(() => evaluateFormula({}, '3 + (4 * 2'), throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Parse Error:'))));
    });

    test('undefined function error', () {
      expect(() => evaluateFormula({}, 'UNKNOWN_FUNCTION(5)'), throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Evaluation Error:'))));
    });

    test('division by zero returns infinity', () {
      final result = evaluateFormula({}, '5 / 0');
      expect(result, double.infinity);
    });

    test('typo in number should show helpful error', () {
      expect(
        () => evaluateFormula(
          {},
          "IF(user_role == 'inspector' && inspection_date != null, IF(ARRAYs_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'Critical'), 'Reject Vehicle', IF(vehiclse_age > 15ss, 'Conditional Approval', 'Approve with Repairs')), IF(mileasge > 1000a00, 'Schedule Maintenance', 'Full Approval')), 'Access Denied')",
        ),
        throwsA(
          isA<FormulaEvaluationException>().having(
            (e) => e.toString(),
            'error message',
            allOf([
              contains('Multiple Errors:'),
              contains('Invalid number format: "15ss"'),
              contains('Invalid number format: "1000a00"'),
              contains("Undefined function or variable 'ARRAYs_ANY'"),
              contains("Undefined function or variable 'vehiclse_age'"),
              contains("Undefined function or variable 'mileasge'"),
            ]),
          ),
        ),
      );
    });

    test('check what happens with invalid number syntax', () {
      expect(() => evaluateFormula({}, '15ss'), throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Parse Error:'))));
    });

    test('malformed decimal number should show helpful error', () {
      expect(
        () => evaluateFormula({}, 'IF(vehicle_age > 5, base_price * 0.d8, base_price)'),
        throwsA(isA<FormulaEvaluationException>().having((e) => e.toString(), 'error message', contains('Multiple Errors:'))),
      );
    });

    test('multiple invalid numbers should show all errors', () {
      expect(
        () => evaluateFormula({}, 'IF(vehicle_age > 5s, base_price * 0.ss8, base_price)'),
        throwsA(
          isA<FormulaEvaluationException>()
              .having((e) => e.toString(), 'error message', contains('Multiple Errors:'))
              .having((e) => e.toString(), 'error message', contains('Invalid number format: "5s"'))
              .having((e) => e.toString(), 'error message', contains('Invalid number format: "0.ss8"')),
        ),
      );
    });
  });
}
