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
  if (array.isEmpty) return false;
  return array.every((item) => item is Map && item[field] == value);
}

/// Contains function: checks if the first string contains the second string
bool contains_(dynamic str, dynamic substr) {
  if (str is! String || substr is! String) return false;
  return str.contains(substr);
}

/// Upper function: converts a value to uppercase string
String upper(dynamic text) {
  return text?.toString().toUpperCase() ?? '';
}

/// Lower function: converts a value to lowercase string
String lower(dynamic text) {
  return text?.toString().toLowerCase() ?? '';
}

/// Trim function: removes leading and trailing whitespace
String trim(dynamic text) {
  return text?.toString().trim() ?? '';
}

/// Length function: returns the length of a string or list
int length(dynamic value) {
  if (value is String) return value.length;
  if (value is List) return value.length;
  return 0;
}

/// Len function: alias for length
int len(dynamic value) => length(value);

/// In function: checks if a value exists in a list
bool in_(dynamic value, dynamic array) {
  if (array is! List) return false;
  return array.contains(value);
}

/// Now function: returns the current date/time
DateTime now_() => DateTime.now();

/// Date diff function: returns the difference between two dates
int dateDiff(dynamic date1, dynamic date2, dynamic unit) {
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
}

/// Date add function: adds time to a date
DateTime? dateAdd(dynamic date, dynamic amount, dynamic unit) {
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
}

/// Is empty function: checks if a value is null or empty
bool isEmpty_(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.isEmpty;
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

/// Coalesce function: returns the first non-null value
dynamic coalesce(dynamic value1, dynamic value2) {
  return value1 ?? value2;
}

/// Absolute value function
num abs_(dynamic x) => _toNum(x).abs();

/// Square root function
num sqrt_(dynamic x) => sqrt(_toNum(x));

/// Minimum function: returns the minimum of provided values
num min_(dynamic a, [dynamic b, dynamic c, dynamic d]) {
  final values = [a, b, c, d].where((v) => v != null).map(_toNum).toList();
  if (values.isEmpty) return 0;
  return values.reduce((curr, next) => curr < next ? curr : next);
}

/// Maximum function: returns the maximum of provided values
num max_(dynamic a, [dynamic b, dynamic c, dynamic d]) {
  final values = [a, b, c, d].where((v) => v != null).map(_toNum).toList();
  if (values.isEmpty) return 0;
  return values.reduce((curr, next) => curr > next ? curr : next);
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
