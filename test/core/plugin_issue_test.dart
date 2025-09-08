import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/src/core/plugin_issue.dart';

void main() {
  group('PluginIssue', () {
    test('should create a plugin issue with required fields', () {
      final issue = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      expect(issue.pluginName, equals('test_plugin'));
      expect(issue.issueType, equals(IssueType.missingRegistration));
      expect(issue.severity, equals(IssueSeverity.high));
      expect(issue.description, equals('Test description'));
      expect(issue.affectedPlatforms, equals(['android', 'ios']));
      expect(issue.stackTrace, isNull);
      expect(issue.detectedAt, isNull);
      expect(issue.additionalContext, isEmpty);
    });

    test('should create a plugin issue with all fields', () {
      final stackTrace = StackTrace.current;
      final detectedAt = DateTime.now();
      final additionalContext = {'key': 'value'};

      final issue = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
        stackTrace: stackTrace,
        detectedAt: detectedAt,
        additionalContext: additionalContext,
      );

      expect(issue.pluginName, equals('test_plugin'));
      expect(issue.issueType, equals(IssueType.missingRegistration));
      expect(issue.severity, equals(IssueSeverity.high));
      expect(issue.description, equals('Test description'));
      expect(issue.affectedPlatforms, equals(['android', 'ios']));
      expect(issue.stackTrace, equals(stackTrace));
      expect(issue.detectedAt, equals(detectedAt));
      expect(issue.additionalContext, equals(additionalContext));
    });

    test('should create a copy with updated fields', () {
      final originalIssue = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      final copiedIssue = originalIssue.copyWith(
        severity: IssueSeverity.critical,
        description: 'Updated description',
      );

      expect(copiedIssue.pluginName, equals('test_plugin'));
      expect(copiedIssue.issueType, equals(IssueType.missingRegistration));
      expect(copiedIssue.severity, equals(IssueSeverity.critical));
      expect(copiedIssue.description, equals('Updated description'));
      expect(copiedIssue.affectedPlatforms, equals(['android', 'ios']));
    });

    test('should convert to JSON correctly', () {
      final detectedAt = DateTime.parse('2023-01-01T00:00:00.000Z');
      final issue = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
        detectedAt: detectedAt,
        additionalContext: {'key': 'value'},
      );

      final json = issue.toJson();

      expect(json['pluginName'], equals('test_plugin'));
      expect(json['issueType'], equals('missingRegistration'));
      expect(json['severity'], equals('high'));
      expect(json['description'], equals('Test description'));
      expect(json['affectedPlatforms'], equals(['android', 'ios']));
      expect(json['detectedAt'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['additionalContext'], equals({'key': 'value'}));
    });

    test('should create from JSON correctly', () {
      final json = {
        'pluginName': 'test_plugin',
        'issueType': 'missingRegistration',
        'severity': 'high',
        'description': 'Test description',
        'affectedPlatforms': ['android', 'ios'],
        'detectedAt': '2023-01-01T00:00:00.000Z',
        'additionalContext': {'key': 'value'},
      };

      final issue = PluginIssue.fromJson(json);

      expect(issue.pluginName, equals('test_plugin'));
      expect(issue.issueType, equals(IssueType.missingRegistration));
      expect(issue.severity, equals(IssueSeverity.high));
      expect(issue.description, equals('Test description'));
      expect(issue.affectedPlatforms, equals(['android', 'ios']));
      expect(issue.detectedAt, equals(DateTime.parse('2023-01-01T00:00:00.000Z')));
      expect(issue.additionalContext, equals({'key': 'value'}));
    });

    test('should handle equality correctly', () {
      final issue1 = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      final issue2 = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      final issue3 = PluginIssue(
        pluginName: 'different_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      expect(issue1, equals(issue2));
      expect(issue1.hashCode, equals(issue2.hashCode));
      expect(issue1, isNot(equals(issue3)));
    });

    test('should have proper string representation', () {
      final issue = PluginIssue(
        pluginName: 'test_plugin',
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.high,
        description: 'Test description',
        affectedPlatforms: ['android', 'ios'],
      );

      final stringRep = issue.toString();

      expect(stringRep, contains('test_plugin'));
      expect(stringRep, contains('missingRegistration'));
      expect(stringRep, contains('high'));
      expect(stringRep, contains('Test description'));
    });
  });

  group('IssueSeverity', () {
    test('should have correct enum values', () {
      expect(IssueSeverity.values, hasLength(4));
      expect(IssueSeverity.values, contains(IssueSeverity.critical));
      expect(IssueSeverity.values, contains(IssueSeverity.high));
      expect(IssueSeverity.values, contains(IssueSeverity.medium));
      expect(IssueSeverity.values, contains(IssueSeverity.low));
    });
  });

  group('IssueType', () {
    test('should have correct enum values', () {
      expect(IssueType.values, hasLength(8));
      expect(IssueType.values, contains(IssueType.missingRegistration));
      expect(IssueType.values, contains(IssueType.missingDeclaration));
      expect(IssueType.values, contains(IssueType.versionMismatch));
      expect(IssueType.values, contains(IssueType.platformConfigMissing));
      expect(IssueType.values, contains(IssueType.initializationFailure));
      expect(IssueType.values, contains(IssueType.methodChannelNotFound));
      expect(IssueType.values, contains(IssueType.dependenciesMissing));
      expect(IssueType.values, contains(IssueType.buildConfigIssue));
    });
  });
}
