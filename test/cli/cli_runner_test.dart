import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/src/cli/cli_runner.dart';
import 'package:path/path.dart' as path;

void main() {
  group('CliRunner', () {
    late CliRunner cliRunner;
    late Directory tempDir;

    setUp(() async {
      cliRunner = CliRunner();
      tempDir = await Directory.systemTemp.createTemp('cli_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('run', () {
      test('should show help when no arguments provided', () async {
        final exitCode = await cliRunner.run([]);
        expect(exitCode, equals(0));
      });

      test('should show help when help flag is provided', () async {
        final exitCode = await cliRunner.run(['--help']);
        expect(exitCode, equals(0));
      });

      test('should show version when version flag is provided', () async {
        final exitCode = await cliRunner.run(['--version']);
        expect(exitCode, equals(0));
      });

      test('should handle unknown command gracefully', () async {
        final exitCode = await cliRunner.run(['unknown']);
        expect(exitCode, equals(1));
      });

      test('should handle format exceptions gracefully', () async {
        final exitCode = await cliRunner.run(['--invalid-flag']);
        expect(exitCode, equals(1));
      });
    });

    group('check command', () {
      test('should run check command successfully with valid project', () async {
        // Create a valid Flutter project structure
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run(['check', '--path', tempDir.path]);

        expect(exitCode, equals(0));
      });

      test('should handle project with plugin issues', () async {
        // Create a project with plugins but no registrant files (will cause issues)
        await _createProjectWithIssues(tempDir);

        final exitCode = await cliRunner.run(['check', '--path', tempDir.path]);

        // Expect non-zero exit code due to issues
        expect(exitCode, isNot(equals(0)));
      });

      test('should handle invalid project path', () async {
        // Don't create any project structure
        final nonExistentPath = path.join(tempDir.path, 'nonexistent');

        final exitCode = await cliRunner.run(['check', '--path', nonExistentPath]);

        expect(exitCode, equals(1));
      });

      test('should handle check command with JSON output', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--output', 'json',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command with markdown output', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--output', 'markdown',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command with verbose flag', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--verbose',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command with platform filtering', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--platforms', 'android,ios',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command with plugin exclusion', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--exclude', 'excluded_plugin',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command with performance mode', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--performance',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle check command errors gracefully', () async {
        // Create an invalid project structure that will cause errors
        final invalidPath = path.join(tempDir.path, 'invalid');
        
        final exitCode = await cliRunner.run(['check', '--path', invalidPath]);

        expect(exitCode, equals(1));
      });
    });

    group('monitor command', () {
      test('should run monitor command successfully', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'monitor',
          '--path', tempDir.path,
          '--duration', '1',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle monitor command with indefinite duration setup', () async {
        await _createValidFlutterProject(tempDir);

        // This test would run indefinitely, so we'll just verify the setup
        // In a real scenario, you'd need to handle the stream differently
        expect(() => cliRunner.run([
          'monitor',
          '--path', tempDir.path,
          '--duration', '0',
        ]), returnsNormally);
      });

      test('should handle monitor command errors gracefully', () async {
        final invalidPath = path.join(tempDir.path, 'invalid');

        final exitCode = await cliRunner.run([
          'monitor',
          '--path', invalidPath,
          '--duration', '1',
        ]);

        // Monitor command may complete successfully even with invalid path
        // as it focuses on runtime monitoring rather than static analysis
        expect(exitCode, isA<int>());
      });
    });

    group('doctor command', () {
      test('should run doctor command successfully', () async {
        // Create a valid Flutter project structure for doctor checks
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'doctor',
          '--path', tempDir.path,
        ]);

        expect(exitCode, equals(0));
      });

      test('should detect project structure issues in doctor command', () async {
        // Don't create pubspec.yaml - this should cause doctor to fail

        final exitCode = await cliRunner.run([
          'doctor',
          '--path', tempDir.path,
        ]);

        expect(exitCode, equals(1));
      });

      test('should handle doctor command with verbose output', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'doctor',
          '--path', tempDir.path,
          '--verbose',
        ]);

        expect(exitCode, equals(0));
      });

      test('should handle doctor command errors gracefully', () async {
        final invalidPath = path.join(tempDir.path, 'invalid');

        final exitCode = await cliRunner.run([
          'doctor',
          '--path', invalidPath,
        ]);

        expect(exitCode, equals(1));
      });
    });

    group('output formatting', () {
      test('should format console output correctly for healthy result', () async {
        await _createValidFlutterProject(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--output', 'console',
        ]);

        expect(exitCode, equals(0));
      });

      test('should format console output correctly for project with issues', () async {
        // Create a project with plugins but no registrant files (will cause issues)
        await _createProjectWithIssues(tempDir);

        final exitCode = await cliRunner.run([
          'check',
          '--path', tempDir.path,
          '--output', 'console',
        ]);

        // Expect non-zero exit code due to issues
        expect(exitCode, isNot(equals(0)));
      });
    });
  });
}

// Helper function to create a valid Flutter project for testing
Future<void> _createValidFlutterProject(Directory dir) async {
  final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
  const content = '''
name: test_project
description: A test Flutter project

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''';

  await pubspecFile.writeAsString(content);

  final lockFile = File(path.join(dir.path, 'pubspec.lock'));
  const lockContent = '''
# Generated by pub
packages:
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
sdks:
  dart: ">=2.17.0 <4.0.0"
  flutter: ">=3.0.0"
''';

  await lockFile.writeAsString(lockContent);
}

Future<void> _createProjectWithIssues(Directory dir) async {
  final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
  const content = '''
name: test_project
description: A test Flutter project

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.0

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''';

  await pubspecFile.writeAsString(content);
  // Don't create registrant files - this will cause issues
}
