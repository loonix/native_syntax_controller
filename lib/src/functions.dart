import 'dart:math';

// ---------------------------------------------------------------------------
// BUILT-IN FUNCTIONS
// ---------------------------------------------------------------------------

/// Converts a value to a number, returning 0 if conversion fails
num _toNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

/// Conditional function: returns trueVal if condition is true, otherwise falseVal
dynamic if_(dynamic condition, dynamic trueVal, dynamic falseVal) => condition ? trueVal : falseVal;

/// Sine function
num sin_(dynamic x) => sin(_toNum(x));

/// Cosine function
num cos_(dynamic x) => cos(_toNum(x));

/// Pi constant
num get pi_ => pi;

/// Average function: calculates the average of provided values
num average(dynamic a, [dynamic b, dynamic c, dynamic d]) {
  final values = [a, b, c, d].where((v) => v != null).map(_toNum).toList();
  if (values.isEmpty) return 0;
  final sum = values.fold<num>(0, (acc, v) => acc + v);
  return sum / values.length;
}

/// Sum function: calculates the sum of provided values
num sum(dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
  final values = [a, b, c, d, e].where((v) => v != null).map(_toNum).toList();
  return values.fold<num>(0, (acc, v) => acc + v);
}

/// Array any function: checks if any item in the array matches the condition
bool arrayAny(dynamic array, String field, dynamic value) {
  if (array is! List) return false;
  return array.any((item) => item is Map && item[field] == value);
}

/// Array all function: checks if all items in the array match the condition
bool arrayAll(dynamic array, String field, dynamic value) {
  if (array is! List) return false;
  return array.every((item) => item is Map && item[field] == value);
}