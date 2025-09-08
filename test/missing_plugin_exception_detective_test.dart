import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective.dart';
import 'package:path/path.dart' as path;

void main() {
  group('MissingPluginExceptionDetective Integration Tests', () {
    late Directory tempDir;
    late MissingPluginExceptionDetective detective;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('detective_integration_test');
      detective = MissingPluginExceptionDetective();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should diagnose a healthy Flutter project', () async {
      await _createHealthyFlutterProject(tempDir);

      final result = await detective.diagnose(projectPath: tempDir.path);

      expect(result.status, equals(DiagnosticStatus.healthy));
      expect(result.issues, isEmpty);
      expect(result.scannedPlugins, isNotEmpty);
      expect(result.scanDuration.inMilliseconds, greaterThan(0));
    });

    test('should diagnose a project with plugin issues', () async {
      await _createProjectWithPluginIssues(tempDir);

      final result = await detective.diagnose(projectPath: tempDir.path);

      expect(result.status, isNot(equals(DiagnosticStatus.healthy)));
      expect(result.hasIssues, isTrue);
      expect(result.issues, isNotEmpty);
    });

    test('should handle invalid project path gracefully', () async {
      final nonExistentPath = path.join(tempDir.path, 'nonexistent');

      final result = await detective.diagnose(projectPath: nonExistentPath);

      expect(result.status, equals(DiagnosticStatus.failed));
      expect(result.issues, isNotEmpty);
      expect(result.issues.first.issueType, equals(IssueType.initializationFailure));
    });

    test('should respect configuration options', () async {
      await _createHealthyFlutterProject(tempDir);

      final config = DetectiveConfig(
        includePlatforms: ['android'],
        enableRuntimeDetection: false,
        performanceMode: true,
      );
      
      final configuredDetective = MissingPluginExceptionDetective(config: config);
      final result = await configuredDetective.diagnose(projectPath: tempDir.path);

      expect(result.status, equals(DiagnosticStatus.healthy));
      expect(result.scanDuration.inMilliseconds, lessThan(1000)); // Performance mode should be faster
    });

    test('should generate resolution guides when requested', () async {
      await _createProjectWithPluginIssues(tempDir);

      final result = await detective.diagnose(
        projectPath: tempDir.path,
        includeResolutions: true,
      );

      expect(result.hasIssues, isTrue);
      // Resolution guides would be generated internally
    });

    test('should handle multiple platform analysis', () async {
      await _createMultiPlatformProject(tempDir);

      final result = await detective.diagnose(projectPath: tempDir.path);

      expect(result.scannedPlugins, isA<List<String>>());
      expect(result.status, isA<DiagnosticStatus>());
      // Should analyze multiple platforms without errors
    });

    test('should monitor runtime issues', () async {
      final issueStream = detective.monitorRuntime();
      
      expect(issueStream, isA<Stream<PluginIssue>>());
      
      // In a real scenario, this would detect runtime issues
      // For testing, we just verify the stream is created
    });
  });

  group('DetectiveConfig', () {
    test('should create config with default values', () {
      const config = DetectiveConfig();

      expect(config.enableRuntimeDetection, isTrue);
      expect(config.enableStaticAnalysis, isTrue);
      expect(config.enableResolutionGuides, isTrue);
      expect(config.performanceMode, isFalse);
      expect(config.maxScanDuration, equals(const Duration(seconds: 30)));
      expect(config.includePlatforms, contains('android'));
      expect(config.includePlatforms, contains('ios'));
      expect(config.excludePlugins, isEmpty);
      expect(config.verboseLogging, isFalse);
    });

    test('should create config with custom values', () {
      const config = DetectiveConfig(
        enableRuntimeDetection: false,
        performanceMode: true,
        maxScanDuration: Duration(seconds: 10),
        includePlatforms: ['android'],
        excludePlugins: ['test_plugin'],
        verboseLogging: true,
      );

      expect(config.enableRuntimeDetection, isFalse);
      expect(config.performanceMode, isTrue);
      expect(config.maxScanDuration, equals(const Duration(seconds: 10)));
      expect(config.includePlatforms, equals(['android']));
      expect(config.excludePlugins, equals(['test_plugin']));
      expect(config.verboseLogging, isTrue);
    });
  });
}

// Helper functions for creating test project structures

Future<void> _createHealthyFlutterProject(Directory dir) async {
  await _createPubspecYaml(dir, []);
  await _createPubspecLock(dir);
  await _createAndroidRegistrant(dir, []);
  await _createIosRegistrant(dir, []);
}

Future<void> _createProjectWithPluginIssues(Directory dir) async {
  await _createPubspecYaml(dir, ['camera', 'geolocator']);
  // Don't create registrant files - this will cause issues
}

Future<void> _createMultiPlatformProject(Directory dir) async {
  await _createPubspecYaml(dir, ['camera']);
  await _createPubspecLock(dir);
  await _createAndroidRegistrant(dir, ['camera']);
  await _createIosRegistrant(dir, ['camera']);
  await _createWebIndex(dir);
}

Future<void> _createPubspecYaml(Directory dir, List<String> plugins) async {
  final pubspecFile = File(path.join(dir.path, 'pubspec.yaml'));
  final pluginDeps = plugins.map((plugin) => '  $plugin: ^1.0.0').join('\n');
  
  final content = '''
name: test_project
description: A test Flutter project

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
$pluginDeps

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''';

  await pubspecFile.writeAsString(content);
}

Future<void> _createPubspecLock(Directory dir) async {
  final lockFile = File(path.join(dir.path, 'pubspec.lock'));
  const content = '''
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

  await lockFile.writeAsString(content);
}

Future<void> _createAndroidRegistrant(Directory dir, List<String> plugins) async {
  final androidDir = Directory(path.join(
    dir.path, 'android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'
  ));
  await androidDir.create(recursive: true);
  
  final registrantFile = File(path.join(androidDir.path, 'GeneratedPluginRegistrant.java'));
  final pluginRegistrations = plugins
      .map((plugin) => '    ${plugin}Plugin.registerWith(registry.registrarFor("${plugin}Plugin"));')
      .join('\n');
  
  final content = '''
package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;

@Keep
public final class GeneratedPluginRegistrant {
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
$pluginRegistrations
  }
}
''';

  await registrantFile.writeAsString(content);
}

Future<void> _createIosRegistrant(Directory dir, List<String> plugins) async {
  final iosDir = Directory(path.join(dir.path, 'ios', 'Runner'));
  await iosDir.create(recursive: true);
  
  final registrantFile = File(path.join(iosDir.path, 'GeneratedPluginRegistrant.m'));
  final pluginRegistrations = plugins
      .map((plugin) => '  [${plugin}Plugin registerWithRegistrar:[registry registrarForPlugin:@"${plugin}Plugin"]];')
      .join('\n');
  
  final content = '''
#import "GeneratedPluginRegistrant.h"

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
$pluginRegistrations
}

@end
''';

  await registrantFile.writeAsString(content);
}

Future<void> _createWebIndex(Directory dir) async {
  final webDir = Directory(path.join(dir.path, 'web'));
  await webDir.create(recursive: true);
  
  final indexFile = File(path.join(webDir.path, 'index.html'));
  const content = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>test_project</title>
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
''';

  await indexFile.writeAsString(content);
}
