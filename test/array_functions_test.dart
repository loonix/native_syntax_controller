import 'package:flutter_test/flutter_test.dart';
import 'package:native_syntax_controller/native_syntax_controller.dart';

void main() {
  group('ARRAY Functions Tests', () {
    test('ARRAY_LENGTH should return correct count', () {
      final testData = {
        'skills': [
          {'name': 'JavaScript', 'level': 'expert'},
          {'name': 'Dart', 'level': 'intermediate'},
          {'name': 'Python', 'level': 'beginner'},
        ]
      };

      // Test basic length
      final result1 = evaluateFormula(testData, 'ARRAY_LENGTH(skills)');
      expect(result1, equals(3));

      // Test empty array
      final emptyData = {'skills': []};
      final result2 = evaluateFormula(emptyData, 'ARRAY_LENGTH(skills)');
      expect(result2, equals(0));

      // Test non-array
      final nonArrayData = {'skills': 'not an array'};
      final result3 = evaluateFormula(nonArrayData, 'ARRAY_LENGTH(skills)');
      expect(result3, equals(0));
    });

    test('ARRAY_LENGTH with condition should filter correctly', () {
      final testData = {
        'skills': [
          {'name': 'JavaScript', 'level': 'expert'},
          {'name': 'Dart', 'level': 'intermediate'},
          {'name': 'Python', 'level': 'expert'},
          {'name': 'Go', 'level': 'beginner'},
        ]
      };

      // Count expert level skills
      final result = evaluateFormula(testData, 'ARRAY_LENGTH(skills, "level == \\"expert\\"")');
      expect(result, equals(2));
    });

    test('ARRAY_ANY should detect matching conditions', () {
      final testData = {
        'skills': [
          {'name': 'JavaScript', 'level': 'expert'},
          {'name': 'Dart', 'level': 'intermediate'},
          {'name': 'Python', 'level': 'beginner'},
        ]
      };

      // Should find expert level
      final result1 = evaluateFormula(testData, 'ARRAY_ANY(skills, "level == \\"expert\\"")');
      expect(result1, equals(true));

      // Should not find master level
      final result2 = evaluateFormula(testData, 'ARRAY_ANY(skills, "level == \\"master\\"")');
      expect(result2, equals(false));

      // Empty array should return false
      final emptyData = {'skills': []};
      final result3 = evaluateFormula(emptyData, 'ARRAY_ANY(skills, "level == \\"expert\\"")');
      expect(result3, equals(false));
    });

    test('ARRAY_ALL should validate all items match condition', () {
      final testData = {
        'skills': [
          {'name': 'JavaScript', 'level': 'expert'},
          {'name': 'Dart', 'level': 'expert'},
          {'name': 'Python', 'level': 'expert'},
        ]
      };

      // All are expert level
      final result1 = evaluateFormula(testData, 'ARRAY_ALL(skills, "level == \\"expert\\"")');
      expect(result1, equals(true));

      // Add one that's not expert
      testData['skills']!.add({'name': 'Go', 'level': 'beginner'});
      final result2 = evaluateFormula(testData, 'ARRAY_ALL(skills, "level == \\"expert\\"")');
      expect(result2, equals(false));

      // Empty array should return false
      final emptyData = {'skills': []};
      final result3 = evaluateFormula(emptyData, 'ARRAY_ALL(skills, "level == \\"expert\\"")');
      expect(result3, equals(false));
    });

    test('Complex ARRAY conditions should work', () {
      final testData = {
        'skills': [
          {'name': 'JavaScript', 'level': 'expert', 'years': 5},
          {'name': 'Dart', 'level': 'intermediate', 'years': 2},
          {'name': 'Python', 'level': 'expert', 'years': 8},
          {'name': 'Go', 'level': 'beginner', 'years': 1},
        ]
      };

      // Find experts with 5+ years experience
      final result1 = evaluateFormula(testData, 'ARRAY_ANY(skills, "level == \\"expert\\" && years >= 5")');
      expect(result1, equals(true));

      // Count skills with more than 3 years
      final result2 = evaluateFormula(testData, 'ARRAY_LENGTH(skills, "years > 3")');
      expect(result2, equals(2));
    });

    test('ARRAY functions should handle errors gracefully', () {
      final testData = {'skills': [{'name': 'test'}]};

      // Invalid condition syntax should return false/0
      final result1 = evaluateFormula(testData, 'ARRAY_ANY(skills, "invalid syntax...")');
      expect(result1, equals(false));

      final result2 = evaluateFormula(testData, 'ARRAY_LENGTH(skills, "invalid syntax...")');
      expect(result2, equals(0));

      final result3 = evaluateFormula(testData, 'ARRAY_ALL(skills, "invalid syntax...")');
      expect(result3, equals(false));
    });
  });
}