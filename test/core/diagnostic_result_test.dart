import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/src/core/diagnostic_result.dart';
import 'package:missing_plugin_exception_detective/src/core/plugin_issue.dart';

void main() {
  group('DiagnosticResult', () {
    test('should create a diagnostic result with required fields', () {
      final result = DiagnosticResult(
        status: DiagnosticStatus.healthy,
        issues: const [],
        scannedPlugins: const ['plugin1', 'plugin2'],
        scanDuration: const Duration(milliseconds: 100),
      );

      expect(result.status, equals(DiagnosticStatus.healthy));
      expect(result.issues, isEmpty);
      expect(result.scannedPlugins, equals(['plugin1', 'plugin2']));
      expect(result.scanDuration, equals(const Duration(milliseconds: 100)));
      expect(result.hasIssues, isFalse);
      expect(result.hasCriticalIssues, isFalse);
    });

    test('should create a diagnostic result with issues', () {
      final issues = [
        PluginIssue(
          pluginName: 'test_plugin',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Critical issue',
          affectedPlatforms: const ['android'],
        ),
        PluginIssue(
          pluginName: 'another_plugin',
          issueType: IssueType.versionMismatch,
          severity: IssueSeverity.medium,
          description: 'Medium issue',
          affectedPlatforms: const ['ios'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: issues,
        scannedPlugins: const ['test_plugin', 'another_plugin'],
        scanDuration: const Duration(milliseconds: 200),
      );

      expect(result.status, equals(DiagnosticStatus.error));
      expect(result.issues, hasLength(2));
      expect(result.hasIssues, isTrue);
      expect(result.hasCriticalIssues, isTrue);
    });

    test('should group issues by severity correctly', () {
      final issues = [
        PluginIssue(
          pluginName: 'plugin1',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Critical issue 1',
          affectedPlatforms: const ['android'],
        ),
        PluginIssue(
          pluginName: 'plugin2',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Critical issue 2',
          affectedPlatforms: const ['ios'],
        ),
        PluginIssue(
          pluginName: 'plugin3',
          issueType: IssueType.versionMismatch,
          severity: IssueSeverity.medium,
          description: 'Medium issue',
          affectedPlatforms: const ['web'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: issues,
        scannedPlugins: const ['plugin1', 'plugin2', 'plugin3'],
        scanDuration: const Duration(milliseconds: 150),
      );

      final issuesBySeverity = result.issuesBySeverity;

      expect(issuesBySeverity[IssueSeverity.critical], hasLength(2));
      expect(issuesBySeverity[IssueSeverity.medium], hasLength(1));
      expect(issuesBySeverity[IssueSeverity.high], isNull);
      expect(issuesBySeverity[IssueSeverity.low], isNull);
    });

    test('should group issues by plugin correctly', () {
      final issues = [
        PluginIssue(
          pluginName: 'plugin1',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Issue 1',
          affectedPlatforms: const ['android'],
        ),
        PluginIssue(
          pluginName: 'plugin1',
          issueType: IssueType.versionMismatch,
          severity: IssueSeverity.medium,
          description: 'Issue 2',
          affectedPlatforms: const ['ios'],
        ),
        PluginIssue(
          pluginName: 'plugin2',
          issueType: IssueType.initializationFailure,
          severity: IssueSeverity.high,
          description: 'Issue 3',
          affectedPlatforms: const ['web'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: issues,
        scannedPlugins: const ['plugin1', 'plugin2'],
        scanDuration: const Duration(milliseconds: 150),
      );

      final issuesByPlugin = result.issuesByPlugin;

      expect(issuesByPlugin['plugin1'], hasLength(2));
      expect(issuesByPlugin['plugin2'], hasLength(1));
    });

    test('should group issues by type correctly', () {
      final issues = [
        PluginIssue(
          pluginName: 'plugin1',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Issue 1',
          affectedPlatforms: const ['android'],
        ),
        PluginIssue(
          pluginName: 'plugin2',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.high,
          description: 'Issue 2',
          affectedPlatforms: const ['ios'],
        ),
        PluginIssue(
          pluginName: 'plugin3',
          issueType: IssueType.versionMismatch,
          severity: IssueSeverity.medium,
          description: 'Issue 3',
          affectedPlatforms: const ['web'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: issues,
        scannedPlugins: const ['plugin1', 'plugin2', 'plugin3'],
        scanDuration: const Duration(milliseconds: 150),
      );

      final issuesByType = result.issuesByType;

      expect(issuesByType[IssueType.missingRegistration], hasLength(2));
      expect(issuesByType[IssueType.versionMismatch], hasLength(1));
    });

    test('should generate correct summary for healthy result', () {
      final result = DiagnosticResult(
        status: DiagnosticStatus.healthy,
        issues: const [],
        scannedPlugins: const ['plugin1', 'plugin2', 'plugin3'],
        scanDuration: const Duration(milliseconds: 100),
      );

      expect(result.summary, equals('All 3 plugins are properly configured.'));
    });

    test('should generate correct summary for result with issues', () {
      final issues = [
        PluginIssue(
          pluginName: 'plugin1',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.critical,
          description: 'Critical issue',
          affectedPlatforms: const ['android'],
        ),
        PluginIssue(
          pluginName: 'plugin2',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.high,
          description: 'High issue',
          affectedPlatforms: const ['ios'],
        ),
        PluginIssue(
          pluginName: 'plugin3',
          issueType: IssueType.versionMismatch,
          severity: IssueSeverity.medium,
          description: 'Medium issue',
          affectedPlatforms: const ['web'],
        ),
        PluginIssue(
          pluginName: 'plugin4',
          issueType: IssueType.dependenciesMissing,
          severity: IssueSeverity.low,
          description: 'Low issue',
          affectedPlatforms: const ['windows'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: issues,
        scannedPlugins: const ['plugin1', 'plugin2', 'plugin3', 'plugin4'],
        scanDuration: const Duration(milliseconds: 200),
      );

      expect(result.summary, equals('Found 4 issues: 1 critical, 1 high, 1 medium, 1 low priority.'));
    });

    test('should convert to JSON correctly', () {
      final scanTimestamp = DateTime.parse('2023-01-01T00:00:00.000Z');
      final issues = [
        PluginIssue(
          pluginName: 'test_plugin',
          issueType: IssueType.missingRegistration,
          severity: IssueSeverity.high,
          description: 'Test issue',
          affectedPlatforms: const ['android'],
        ),
      ];

      final result = DiagnosticResult(
        status: DiagnosticStatus.warning,
        issues: issues,
        scannedPlugins: const ['test_plugin'],
        scanDuration: const Duration(milliseconds: 150),
        scanTimestamp: scanTimestamp,
        projectPath: '/test/path',
        flutterVersion: '3.0.0',
        dartVersion: '2.17.0',
        additionalMetadata: const {'key': 'value'},
      );

      final json = result.toJson();

      expect(json['status'], equals('warning'));
      expect(json['issues'], hasLength(1));
      expect(json['scannedPlugins'], equals(['test_plugin']));
      expect(json['scanDuration'], equals(150));
      expect(json['scanTimestamp'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['projectPath'], equals('/test/path'));
      expect(json['flutterVersion'], equals('3.0.0'));
      expect(json['dartVersion'], equals('2.17.0'));
      expect(json['additionalMetadata'], equals({'key': 'value'}));
      expect(json['summary'], isA<String>());
    });

    test('should create from JSON correctly', () {
      final json = {
        'status': 'warning',
        'issues': [
          {
            'pluginName': 'test_plugin',
            'issueType': 'missingRegistration',
            'severity': 'high',
            'description': 'Test issue',
            'affectedPlatforms': ['android'],
            'additionalContext': <String, dynamic>{},
          }
        ],
        'scannedPlugins': ['test_plugin'],
        'scanDuration': 150,
        'scanTimestamp': '2023-01-01T00:00:00.000Z',
        'projectPath': '/test/path',
        'flutterVersion': '3.0.0',
        'dartVersion': '2.17.0',
        'additionalMetadata': {'key': 'value'},
      };

      final result = DiagnosticResult.fromJson(json);

      expect(result.status, equals(DiagnosticStatus.warning));
      expect(result.issues, hasLength(1));
      expect(result.scannedPlugins, equals(['test_plugin']));
      expect(result.scanDuration, equals(const Duration(milliseconds: 150)));
      expect(result.scanTimestamp, equals(DateTime.parse('2023-01-01T00:00:00.000Z')));
      expect(result.projectPath, equals('/test/path'));
      expect(result.flutterVersion, equals('3.0.0'));
      expect(result.dartVersion, equals('2.17.0'));
      expect(result.additionalMetadata, equals({'key': 'value'}));
    });

    test('should handle equality correctly', () {
      final result1 = DiagnosticResult(
        status: DiagnosticStatus.healthy,
        issues: const [],
        scannedPlugins: const ['plugin1'],
        scanDuration: const Duration(milliseconds: 100),
      );

      final result2 = DiagnosticResult(
        status: DiagnosticStatus.healthy,
        issues: const [],
        scannedPlugins: const ['plugin1'],
        scanDuration: const Duration(milliseconds: 100),
      );

      final result3 = DiagnosticResult(
        status: DiagnosticStatus.error,
        issues: const [],
        scannedPlugins: const ['plugin1'],
        scanDuration: const Duration(milliseconds: 100),
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
    });

    test('should have proper string representation', () {
      final result = DiagnosticResult(
        status: DiagnosticStatus.warning,
        issues: const [],
        scannedPlugins: const ['plugin1', 'plugin2'],
        scanDuration: const Duration(milliseconds: 150),
      );

      final stringRep = result.toString();

      expect(stringRep, contains('warning'));
      expect(stringRep, contains('0'));
      expect(stringRep, contains('2'));
      expect(stringRep, contains('150ms'));
    });
  });

  group('DiagnosticStatus', () {
    test('should have correct enum values', () {
      expect(DiagnosticStatus.values, hasLength(4));
      expect(DiagnosticStatus.values, contains(DiagnosticStatus.healthy));
      expect(DiagnosticStatus.values, contains(DiagnosticStatus.warning));
      expect(DiagnosticStatus.values, contains(DiagnosticStatus.error));
      expect(DiagnosticStatus.values, contains(DiagnosticStatus.failed));
    });
  });
}
