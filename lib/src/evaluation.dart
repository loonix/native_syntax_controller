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

    // Proactively scan for undefined functions/variables before evaluation
    // This catches issues even when parsing fails due to other syntax errors
    if (!allErrors.any((e) => e['message'].toString().contains('Undefined function or variable'))) {
      // Extract all potential identifiers from the formula
      final identifierRegex = RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\b');
      final allMatches = identifierRegex.allMatches(processedFormula);

      // Filter out identifiers that appear to be inside quotes
      final allIdentifiers = <String>{};
      for (final match in allMatches) {
        final identifier = match.group(1)!;
        final start = match.start;

        // Check if this identifier is inside single or double quotes
        bool insideQuotes = false;
        for (int i = 0; i < start; i++) {
          if ((processedFormula[i] == "'" || processedFormula[i] == '"') && (i == 0 || processedFormula[i - 1] != '\\')) {
            insideQuotes = !insideQuotes;
          }
        }

        if (!insideQuotes) {
          allIdentifiers.add(identifier);
        }
      }

      // Remove known functions and keywords
      final knownFunctions = {'IF', 'SIN', 'COS', 'PI', 'AVERAGE', 'SUM', 'ARRAY_ANY', 'ARRAY_ALL', 'true', 'false', 'null', ...?customFunctions?.keys};

      final potentialUndefined = allIdentifiers.where((id) => !knownFunctions.contains(id)).toList();

      // Check each potential undefined identifier
      for (final identifier in potentialUndefined) {
        // Skip if it's already in the provided json context
        if (!json.containsKey(identifier)) {
          final position = processedFormula.indexOf(identifier);
          allErrors.add({'message': "Undefined function or variable '$identifier'", 'position': position >= 0 ? position : null, 'type': 'evaluation'});
        }
      }
    }

    // If parsing succeeded and we have no parse errors, try evaluation
    if (expression != null && !allErrors.any((e) => e['type'] == 'parse')) {
      final context = <String, dynamic>{};

      json.forEach((key, value) {
        context[key] = value;
      });

      context.addAll({
        'AVERAGE': (dynamic a, dynamic b, [dynamic c, dynamic d]) {
          final values = [a, b, if (c != null) c, if (d != null) d].map(_toNum).toList();
          if (values.isEmpty) return 0;
          final sum = values.fold<num>(0, (acc, v) => acc + v);
          return sum / values.length;
        },
        'SUM': (dynamic a, dynamic b, [dynamic c, dynamic d, dynamic e]) {
          final values = [a, b, if (c != null) c, if (d != null) d, if (e != null) e].map(_toNum).toList();
          return values.fold<num>(0, (acc, v) => acc + v);
        },
        'ARRAY_ANY': (dynamic array, String field, dynamic value) {
          if (array is! List) return false;
          return array.any((item) => item is Map && item[field] == value);
        },
        'ARRAY_ALL': (dynamic array, String field, dynamic value) {
          if (array is! List) return false;
          return array.every((item) => item is Map && item[field] == value);
        },
        'IF': (dynamic condition, dynamic trueVal, dynamic falseVal) => condition ? trueVal : falseVal,
        'SIN': (dynamic x) => sin(_toNum(x)),
        'COS': (dynamic x) => cos(_toNum(x)),
        'PI': pi,
      });

      // Add custom functions if provided
      if (customFunctions != null) {
        context.addAll(customFunctions);
      }

      try {
        const evaluator = ExpressionEvaluator();
        return evaluator.eval(expression, context);
      } catch (evalError) {
        // If evaluation fails and we haven't already caught undefined variables,
        // try to provide more specific error information
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
        // If we already have undefined variable errors, don't add additional generic errors
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
