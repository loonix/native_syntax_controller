/// A high-performance syntax highlighting controller using Flutter's native text rendering (TextSpan).
///
/// This package provides two main features:
/// 1. Formula evaluation using the expressions package with enhanced Map support
/// 2. Syntax highlighting for formula text input with customizable colors
///
/// ## Features
///
/// ### Formula Evaluation
/// - Evaluate mathematical and logical expressions
/// - Support for custom functions (SUM, AVERAGE, IF, CONTAINS, LENGTH, LEN, UPPER, LOWER, TRIM, IN, NOW, DATE_DIFF, DATE_ADD, IS_EMPTY, COALESCE, ABS, SQRT, MIN, MAX, etc.)
/// - Enhanced Map property access (both .property and ['property'] syntax)
/// - Array operations (ARRAY_ANY, ARRAY_ALL, IN)
///
/// ### Syntax Highlighting
/// - Automatic highlighting of functions, operators, numbers, and strings
/// - Customizable colors through the SyntaxHighlightingController
/// - Real-time highlighting as you type
///
/// ## Example
///
/// ```dart
/// import 'package:native_syntax_controller/native_syntax_controller.dart';
///
/// // Evaluate a formula
/// final result = evaluateFormula({'a': 5, 'b': 3}, 'a * b + SUM(a, b)');
///
/// // Create a controller with custom highlighting colors
/// final controller = SyntaxHighlightingController(
///   customStyles: {
///     'function': TextStyle(color: Colors.red),
///     'operator': TextStyle(color: Colors.blue),
///   },
/// );
/// ```

// Export the evaluation functionality
export 'src/evaluation.dart';

// Export the highlighting functionality
export 'src/highlighting.dart';

// Export the built-in functions
export 'src/functions.dart';
