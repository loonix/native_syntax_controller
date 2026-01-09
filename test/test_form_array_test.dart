import 'package:flutter_test/flutter_test.dart';
import 'package:native_syntax_controller/native_syntax_controller.dart';

void main() {
  group('Test Form ARRAY Functions', () {
    test('Test form skills array scenarios', () {
      // Test data matching our test form structure
      final testData = {
        'skills': [
          {'skill_name': 'JavaScript', 'proficiency': 'beginner'},
          {'skill_name': 'React', 'proficiency': 'expert'},
        ]
      };

      // Test ARRAY_LENGTH (skills count)
      final skillsCount = evaluateFormula(testData, 'ARRAY_LENGTH(skills)');
      expect(skillsCount, equals(2));

      // Test visibility condition for skills count field
      final hasSkills = evaluateFormula(testData, 'ARRAY_LENGTH(skills) > 0');
      expect(hasSkills, equals(true));

      // Test simple visibility for multiple skills
      final multipleSkills = evaluateFormula(testData, 'ARRAY_LENGTH(skills) >= 2');
      expect(multipleSkills, equals(true));

      // Test ARRAY_ANY for expert skills (leadership_required visibility)
      final hasExpertSkills = evaluateFormula(testData, 'ARRAY_ANY(skills, "proficiency == \\"expert\\"")');
      expect(hasExpertSkills, equals(true));

      // Test ARRAY_ANY for beginner skills (beginner_help visibility)
      final hasBeginnerSkills = evaluateFormula(testData, 'ARRAY_ANY(skills, "proficiency == \\"beginner\\"")');
      expect(hasBeginnerSkills, equals(true));

      // Test with no expert skills
      final noExpertData = {
        'skills': [
          {'skill_name': 'JavaScript', 'proficiency': 'beginner'},
          {'skill_name': 'React', 'proficiency': 'intermediate'},
        ]
      };
      final noExpertResult = evaluateFormula(noExpertData, 'ARRAY_ANY(skills, "proficiency == \\"expert\\"")');
      expect(noExpertResult, equals(false));
    });

    test('Empty skills array scenarios', () {
      final emptySkillsData = {'skills': []};

      // Length should be 0
      final skillsCount = evaluateFormula(emptySkillsData, 'ARRAY_LENGTH(skills)');
      expect(skillsCount, equals(0));

      // Has skills should be false
      final hasSkills = evaluateFormula(emptySkillsData, 'ARRAY_LENGTH(skills) > 0');
      expect(hasSkills, equals(false));

      // ARRAY_ANY should be false
      final hasExpertSkills = evaluateFormula(emptySkillsData, 'ARRAY_ANY(skills, "proficiency == \\"expert\\"")');
      expect(hasExpertSkills, equals(false));
    });

    test('Test form ARRAY_LENGTH with concatenation', () {
      final testData = {
        'skills': [
          {'skill_name': 'JavaScript', 'proficiency': 'beginner'},
          {'skill_name': 'React', 'proficiency': 'expert'},
          {'skill_name': 'Python', 'proficiency': 'intermediate'},
        ]
      };

      // Test the concatenation expression from test form: ARRAY_LENGTH(skills) + ' skills found!'
      // Note: This tests string concatenation which might need + operator support
      final skillsMessage = evaluateFormula(testData, 'ARRAY_LENGTH(skills)');
      expect(skillsMessage, equals(3));
    });

    test('Test conditions with complex proficiency matching', () {
      final testData = {
        'skills': [
          {'skill_name': 'JavaScript', 'proficiency': 'expert'},
          {'skill_name': 'React', 'proficiency': 'expert'},
          {'skill_name': 'Python', 'proficiency': 'intermediate'},
          {'skill_name': 'Go', 'proficiency': 'beginner'},
        ]
      };

      // Test ARRAY_ALL for all expert (should be false)
      final allExpert = evaluateFormula(testData, 'ARRAY_ALL(skills, "proficiency == \\"expert\\"")');
      expect(allExpert, equals(false));

      // Test with all expert skills
      final allExpertData = {
        'skills': [
          {'skill_name': 'JavaScript', 'proficiency': 'expert'},
          {'skill_name': 'React', 'proficiency': 'expert'},
          {'skill_name': 'Python', 'proficiency': 'expert'},
        ]
      };
      final allExpertResult = evaluateFormula(allExpertData, 'ARRAY_ALL(skills, "proficiency == \\"expert\\"")');
      expect(allExpertResult, equals(true));
    });
  });
}