## 1.5.1

* Fixed TypeError on Flutter Web with optional function parameters
* `ROUND(number, decimals)` - decimals parameter is now required (pass `null` or `0` for integer rounding)
* `COALESCE(value1, value2)` - reverted to 2 arguments (chain calls for more: `COALESCE(COALESCE(a, b), c)`)
* `CONCAT(a, b, ...)` - first two arguments are now required

## 1.5.0

* Added new math functions:
  - `ROUND(number, [decimals])` - Rounds to nearest integer, or to specified decimal places
  - `CEIL(number)` - Rounds up to nearest integer
  - `FLOOR(number)` - Rounds down to nearest integer
* Added new text function:
  - `CONCAT(val1, val2, ...)` - Joins up to 8 values as text (auto-converts numbers to strings)
* Enhanced `COALESCE` to support up to 4 arguments (was 2)
* Added comprehensive test coverage for all new functions

## 1.4.0

* **BREAKING CHANGE**: Enhanced ARRAY_ANY and ARRAY_ALL functions to support complex conditional expressions
  - ARRAY_ANY and ARRAY_ALL now accept condition strings instead of field/value pairs
  - Example: `ARRAY_ANY(skills, "proficiency == \"expert\"")` instead of `ARRAY_ANY(skills, "proficiency", "expert")`
* Added new ARRAY_LENGTH function with optional condition filtering
  - `ARRAY_LENGTH(array)` - returns the length of an array
  - `ARRAY_LENGTH(array, "condition")` - returns count of items matching the condition
* Improved ARRAY function error handling with graceful fallbacks
* Added comprehensive test coverage for all ARRAY functions
* Enhanced documentation to reflect new ARRAY function capabilities

## 1.3.0

* Added new built-in functions: UPPER, LOWER, TRIM, LEN, IN, NOW, DATE_DIFF, DATE_ADD, IS_EMPTY, COALESCE
* Added direct access to additional built-in functions: upper, lower, trim, len, in_, now_, dateDiff, dateAdd, isEmpty_, coalesce

## 1.2.0

* Added new built-in functions: CONTAINS, LENGTH, ABS, SQRT, MIN, MAX
* Added direct access to additional built-in functions: stringContains, length, abs_, sqrt_, min_, max_
* Enhanced formula evaluation with string and mathematical operations

## 1.1.0

* Added support for custom functions in formula evaluation via the `customFunctions` parameter in `evaluateFormula`.
* Added direct access to built-in functions: `if_`, `sin_`, `cos_`, `pi_`, `average`, `sum`, `arrayAny`, `arrayAll`.

## 1.0.0

* Initial release: A high-performance syntax highlighting controller using Flutter's native text rendering (TextSpan). No overlays, no sync issues, just a pure TextEditingController extension.

