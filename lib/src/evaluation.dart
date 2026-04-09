import 'package:expressions/expressions.dart';
import 'dart:math';

// ---------------------------------------------------------------------------
// EVALUATION LOGIC
// ---------------------------------------------------------------------------

/// Custom exception for formula evaluation errors with position information
class FormulaEvaluationException implements Exception {
  final String message;
  final String originalFormula;
  final int? position;
  final String? errorType;
  final List<Map<String, dynamic>>? multipleErrors;

  FormulaEvaluationException(this.message, this.originalFormula, {this.position, this.errorType, this.multipleErrors});

  @override
  String toString() {
    final buffer = StringBuffer();

    if (multipleErrors != null && multipleErrors!.isNotEmpty) {
      buffer.write('Multiple Errors:');
      for (final error in multipleErrors!) {
        buffer.write('\n- ${error['message']}');
        if (error['position'] != null) {
          buffer.write(' at position ${error['position']}');
        }
      }
    } else {
      if (errorType != null) {
        buffer.write('$errorType:');
      } else {
        buffer.write('Parse Error:');
      }
      buffer.write('\n- $message');
      if (position != null && position! >= 0 && position! < originalFormula.length) {
        buffer.write(' at position $position');
      }
    }

    return buffer.toString();
  }
}

num _toNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  if (date is DateTime) return date;
  if (date is String) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }
  return null;
}

dynamic evaluateFormula(Map<String, dynamic> json, String formula, {Map<String, dynamic>? customFunctions}) {
  final List<Map<String, dynamic>> allErrors = [];

  try {
    // Preprocess the formula to convert .property access to ['property'] for Map support
    final processedFormula = formula.replaceAllMapped(RegExp(r'(?<!\d)\.(\w+)'), (match) => "['${match.group(1)}']");

    // Check for invalid number formats - collect all errors
    // Find all invalid decimal numbers
    final invalidDecimalRegex = RegExp(r'\b\d+\.\d*[a-zA-Z]+\w*\b');
    for (final match in invalidDecimalRegex.allMatches(processedFormula)) {
      final invalidToken = match.group(0)!;
      final position = processedFormula.indexOf(invalidToken);
      allErrors.add({
        'token': invalidToken,
        'position': position,
        'message': 'Invalid number format: "$invalidToken" - decimal numbers cannot contain letters',
        'description': 'Invalid decimal',
        'type': 'number',
      });
    }

    // Find all invalid numbers (not decimals) - avoid duplicates
    final invalidNumberRegex = RegExp(r'\b\d+[a-zA-Z]+\w*\b');
    for (final match in invalidNumberRegex.allMatches(processedFormula)) {
      final invalidToken = match.group(0)!;
      final position = processedFormula.indexOf(invalidToken);

      // Check if this token was already caught as a decimal error
      final alreadyReported = allErrors.any((error) => error['token'] == invalidToken);
      if (!alreadyReported) {
        allErrors.add({
          'token': invalidToken,
          'position': position,
          'message': 'Invalid number format: "$invalidToken" - numbers cannot contain letters',
          'description': 'Invalid number',
          'type': 'number',
        });
      }
    }

    Expression? expression;
    try {
      expression = Expression.parse(processedFormula);
    } catch (parseError) {
      // Try to find the position of the parsing error
      int? errorPosition;
      String errorMessage = 'Invalid formula syntax';

      if (parseError is FormatException) {
        errorMessage = parseError.message;

        // Try to extract position from the error message
        final offsetMatch = RegExp(r'offset (\d+)').firstMatch(parseError.message);
        if (offsetMatch != null) {
          errorPosition = int.tryParse(offsetMatch.group(1)!);
        } else {
          // For expressions package, try to detect common syntax errors
          if (parseError.message.contains('end of input expected')) {
            // Look for invalid number syntax like "15ss" or "1000a00"
            final invalidNumberMatch = RegExp(r'\b(\d+[a-zA-Z]+\w*)\b').firstMatch(processedFormula);
            if (invalidNumberMatch != null) {
              final invalidToken = invalidNumberMatch.group(1)!;
              errorPosition = processedFormula.indexOf(invalidToken);
              errorMessage = 'Invalid number format: "$invalidToken" - numbers cannot contain letters';

              // Check if this number error was already caught by pre-validation
              final alreadyReported = allErrors.any((error) => error['type'] == 'number' && error['token'] == invalidToken);
              if (alreadyReported) {
                // Don't add duplicate error, but still mark as parse error if no other parse errors
                errorMessage = 'Invalid formula syntax';
                errorPosition = null;
              }
            }
          }
        }
      } else if (parseError.toString().contains('position')) {
        // Try to extract position from generic error messages
        final posMatch = RegExp(r'position (\d+)').firstMatch(parseError.toString());
        if (posMatch != null) {
          errorPosition = int.tryParse(posMatch.group(1)!);
        }
      }

      // Only add parse error if we haven't already identified specific syntax issues
      // that would cause parsing to fail
      final hasSpecificSyntaxErrors = allErrors.any((error) => error['type'] == 'number');
      if (!hasSpecificSyntaxErrors) {
        allErrors.add({'message': errorMessage, 'position': errorPosition, 'type': 'parse'});
      }
    }

    // NOTE: Pre-validation of undefined functions/variables was removed in v1.5.2
    // It had bugs with string literals in quotes (e.g., "Adult", "Minor")
    // The actual evaluation phase catches real errors, so pre-validation is unnecessary

    // If parsing succeeded and we have no parse errors, try evaluation
    if (expression != null && !allErrors.any((e) => e['type'] == 'parse')) {
      final context = <String, dynamic>{};

      json.forEach((key, value) {
        context[key] = value;
      });

      context.addAll({
        'AVERAGE': (dynamic a, [dynamic b, dynamic c, dynamic d]) {
          // Handle case where a is a list (AVERAGE(items))
          if (a is List && b == null) {
            final values = a.map(_toNum).toList();
            if (values.isEmpty) return 0;
            final sum = values.fold<num>(0, (acc, v) => acc + v);
            return sum / values.length;
          }
          // Handle case where arguments are individual values (AVERAGE(a, b, c, ...))
          final values = [a, if (b != null) b, if (c != null) c, if (d != null) d].map(_toNum).toList();
          if (values.isEmpty) return 0;
          final sum = values.fold<num>(0, (acc, v) => acc + v);
          return sum / values.length;
        },
        'SUM': (dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
          // Handle case where a is a list (SUM(items))
          if (a is List && b == null) {
            final values = a.map(_toNum).toList();
            return values.fold<num>(0, (acc, v) => acc + v);
          }
          // Handle case where arguments are individual values (SUM(a, b, c, ...))
          final values = [a, if (b != null) b, if (c != null) c, if (d != null) d, if (e != null) e].map(_toNum).toList();
          return values.fold<num>(0, (acc, v) => acc + v);
        },
        'ARRAY_LENGTH': (dynamic array, [String? condition]) {
          if (array is! List) return 0;
          if (condition == null) {
            return array.length;
          }
          // If condition is provided, count items that match the condition
          try {
            int count = 0;
            for (final item in array) {
              if (item is Map) {
                final itemContext = Map<String, dynamic>.from(item);
                final conditionExpression = Expression.parse(condition);
                const conditionEvaluator = ExpressionEvaluator();
                final result = conditionEvaluator.eval(conditionExpression, itemContext);
                if (result is bool && result) count++;
              }
            }
            return count;
          } catch (e) {
            return 0; // Return 0 if condition evaluation fails
          }
        },
        'ARRAY_ANY': (dynamic array, String condition) {
          if (array is! List) return false;
          if (array.isEmpty) return false;
          try {
            for (final item in array) {
              if (item is Map) {
                final itemContext = Map<String, dynamic>.from(item);
                final conditionExpression = Expression.parse(condition);
                const conditionEvaluator = ExpressionEvaluator();
                final result = conditionEvaluator.eval(conditionExpression, itemContext);
                if (result is bool && result) return true;
              }
            }
            return false;
          } catch (e) {
            return false; // Return false if condition evaluation fails
          }
        },
        'ARRAY_ALL': (dynamic array, String condition) {
          if (array is! List) return false;
          if (array.isEmpty) return false;
          try {
            for (final item in array) {
              if (item is Map) {
                final itemContext = Map<String, dynamic>.from(item);
                final conditionExpression = Expression.parse(condition);
                const conditionEvaluator = ExpressionEvaluator();
                final result = conditionEvaluator.eval(conditionExpression, itemContext);
                if (!(result is bool && result)) return false;
              }
            }
            return true;
          } catch (e) {
            return false; // Return false if condition evaluation fails
          }
        },
        'IF': (dynamic condition, dynamic trueVal, dynamic falseVal) => condition ? trueVal : falseVal,
        'SIN': (dynamic x) => sin(_toNum(x)),
        'COS': (dynamic x) => cos(_toNum(x)),
        'PI': pi,
        'CONTAINS': (dynamic str, dynamic substr) {
          if (str is! String || substr is! String) return false;
          return str.contains(substr);
        },
        'LENGTH': (dynamic value) {
          if (value is String) return value.length;
          if (value is List) return value.length;
          return 0;
        },
        'LEN': (dynamic value) {
          if (value is String) return value.length;
          if (value is List) return value.length;
          return 0;
        },
        'UPPER': (dynamic text) => text?.toString().toUpperCase() ?? '',
        'LOWER': (dynamic text) => text?.toString().toLowerCase() ?? '',
        'TRIM': (dynamic text) => text?.toString().trim() ?? '',
        'IN': (dynamic value, dynamic array) {
          if (array is! List) return false;
          return array.contains(value);
        },
        'NOW': () => DateTime.now(),
        'DATE_DIFF': (dynamic date1, dynamic date2, dynamic unit) {
          final d1 = _parseDate(date1);
          final d2 = _parseDate(date2);

          if (d1 == null || d2 == null) return 0;

          final difference = d1.difference(d2);
          final normalizedUnit = unit?.toString().toLowerCase() ?? 'days';

          switch (normalizedUnit) {
            case 'days':
              return difference.inDays;
            case 'hours':
              return difference.inHours;
            case 'minutes':
              return difference.inMinutes;
            case 'seconds':
              return difference.inSeconds;
            default:
              return difference.inDays;
          }
        },
        'DATE_ADD': (dynamic date, dynamic amount, dynamic unit) {
          final parsedDate = _parseDate(date);
          if (parsedDate == null) return null;

          final normalizedUnit = unit?.toString().toLowerCase() ?? 'days';
          final amountValue = _toNum(amount).toInt();

          switch (normalizedUnit) {
            case 'days':
              return parsedDate.add(Duration(days: amountValue));
            case 'hours':
              return parsedDate.add(Duration(hours: amountValue));
            case 'minutes':
              return parsedDate.add(Duration(minutes: amountValue));
            case 'seconds':
              return parsedDate.add(Duration(seconds: amountValue));
            default:
              return parsedDate.add(Duration(days: amountValue));
          }
        },
        'IS_EMPTY': (dynamic value) {
          if (value == null) return true;
          if (value is String) return value.isEmpty;
          if (value is List) return value.isEmpty;
          if (value is Map) return value.isEmpty;
          return false;
        },
        'COALESCE': (dynamic value1, dynamic value2) => value1 ?? value2,
        'ROUND': (dynamic x, dynamic decimals) {
          final num value = _toNum(x);
          if (decimals == null) return value.round();
          final int dec = _toNum(decimals).toInt();
          if (dec == 0) return value.round();
          final multiplier = pow(10, dec);
          return (value * multiplier).round() / multiplier;
        },
        'CEIL': (dynamic x) => _toNum(x).ceil(),
        'FLOOR': (dynamic x) => _toNum(x).floor(),
        'CONCAT': (dynamic a, dynamic b, [dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h]) {
          return [a, b, c, d, e, f, g, h]
              .where((v) => v != null)
              .map((v) => v.toString())
              .join();
        },
        'ABS': (dynamic x) => _toNum(x).abs(),
        'SQRT': (dynamic x) => sqrt(_toNum(x)),
        'MIN': (dynamic a, [dynamic b, dynamic c, dynamic d]) {
          // Handle case where a is a list (MIN(items))
          if (a is List && b == null) {
            final values = a.map(_toNum).toList();
            if (values.isEmpty) return 0;
            return values.reduce((curr, next) => curr < next ? curr : next);
          }
          // Handle case where arguments are individual values (MIN(a, b, c, ...))
          final values = [a, if (b != null) b, if (c != null) c, if (d != null) d].map(_toNum).toList();
          if (values.isEmpty) return 0;
          return values.reduce((curr, next) => curr < next ? curr : next);
        },
        'MAX': (dynamic a, [dynamic b, dynamic c, dynamic d]) {
          // Handle case where a is a list (MAX(items))
          if (a is List && b == null) {
            final values = a.map(_toNum).toList();
            if (values.isEmpty) return 0;
            return values.reduce((curr, next) => curr > next ? curr : next);
          }
          // Handle case where arguments are individual values (MAX(a, b, c, ...))
          final values = [a, b, if (c != null) c, if (d != null) d].map(_toNum).toList();
          if (values.isEmpty) return 0;
          return values.reduce((curr, next) => curr > next ? curr : next);
        },
      });

      // Add custom functions if provided
      if (customFunctions != null) {
        context.addAll(customFunctions);
      }

      try {
        const evaluator = ExpressionEvaluator();
        return evaluator.eval(expression, context);
      } catch (evalError) {
        // If evaluation fails, provide specific error information
        if (!allErrors.any((e) => e['message'].toString().contains('Undefined function or variable'))) {
          String errorMessage = 'Evaluation error';
          int? errorPosition;

          if (evalError.toString().contains('TypeError')) {
            errorMessage = 'Type mismatch in operation';
          } else if (evalError.toString().contains('RangeError')) {
            errorMessage = 'Array index out of bounds';
          } else if (evalError.toString().contains('ArgumentError')) {
            errorMessage = 'Invalid function arguments';
          } else if (evalError.toString().contains('NoSuchMethodError')) {
            errorMessage = 'Undefined function or variable';
          }

          allErrors.add({'message': errorMessage, 'position': errorPosition, 'type': 'evaluation'});
        }
      }
    }

    // If we have any errors, throw with all of them
    if (allErrors.isNotEmpty) {
      if (allErrors.length == 1) {
        final error = allErrors.first;
        throw FormulaEvaluationException(error['message'] as String, formula, position: error['position'] as int?, errorType: error['type'] == 'evaluation' ? 'Evaluation Error' : 'Parse Error');
      } else {
        // Group errors by type for better display
        final numberErrors = allErrors.where((e) => e['type'] == 'number').toList();
        final parseErrors = allErrors.where((e) => e['type'] == 'parse').toList();
        final evalErrors = allErrors.where((e) => e['type'] == 'evaluation').toList();

        final combinedErrors = [...numberErrors, ...parseErrors, ...evalErrors];

        throw FormulaEvaluationException('Multiple errors found', formula, errorType: 'Parse Error', multipleErrors: combinedErrors);
      }
    }
  } catch (e) {
    if (e is FormulaEvaluationException) {
      rethrow;
    }
    // Fallback for any other unexpected errors
    throw FormulaEvaluationException('Unexpected error: ${e.toString()}', formula, errorType: 'Unknown Error');
  }
}
