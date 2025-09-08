import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/src/analyzers/static_analyzer.dart';
import 'package:missing_plugin_exception_detective/src/core/plugin_issue.dart';
import 'package:path/path.dart' as path;

void main() {
  group('StaticAnalyzer', () {
    late Directory tempDir;
    late StaticAnalyzer analyzer;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('static_analyzer_test');
      analyzer = const StaticAnalyzer();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('analyze', () {
      test('should analyze a valid Flutter project without issues', () async {
        // Create a minimal valid Flutter project structure
        await _createValidFlutterProject(tempDir);

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        expect(issues, isEmpty);
      });

      test('should detect missing pubspec.yaml', () async {
        // Don't create pubspec.yaml

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        expect(issues, hasLength(1));
        expect(issues.first.issueType, equals(IssueType.initializationFailure));
        expect(issues.first.severity, equals(IssueSeverity.high));
      });

      test('should detect missing Android registrant file', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        // Don't create the Android registrant file

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        expect(issues, isNotEmpty);
        final registrantIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'android_registrant',
          orElse: () => throw StateError('No registrant issue found'),
        );
        expect(registrantIssue.issueType, equals(IssueType.missingRegistration));
        expect(registrantIssue.severity, equals(IssueSeverity.critical));
      });

      test('should detect missing iOS registrant file', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        // Don't create the iOS registrant file

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['ios'],
          excludePlugins: [],
        );

        expect(issues, isNotEmpty);
        final registrantIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'ios_registrant',
          orElse: () => throw StateError('No registrant issue found'),
        );
        expect(registrantIssue.issueType, equals(IssueType.missingRegistration));
        expect(registrantIssue.severity, equals(IssueSeverity.critical));
      });

      test('should detect plugin declared but not registered', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        await _createAndroidRegistrantFile(tempDir, []); // Empty registrant

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        expect(issues, isNotEmpty);
        final cameraIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'camera',
          orElse: () => throw StateError('No camera issue found'),
        );
        expect(cameraIssue.issueType, equals(IssueType.missingRegistration));
        expect(cameraIssue.severity, equals(IssueSeverity.high));
      });

      test('should exclude specified plugins from analysis', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera', 'geolocator']);
        await _createAndroidRegistrantFile(tempDir, []); // Empty registrant

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: ['camera'],
        );

        final cameraIssues = issues.where((issue) => issue.pluginName == 'camera');
        expect(cameraIssues, isEmpty);

        final geolocatorIssues = issues.where((issue) => issue.pluginName == 'geolocator');
        expect(geolocatorIssues, isNotEmpty);
      });

      test('should detect missing pubspec.lock', () async {
        await _createValidFlutterProject(tempDir);
        // Don't create pubspec.lock

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        final lockIssues = issues.where(
          (issue) => issue.pluginName == 'dependency_management',
        );
        expect(lockIssues, isNotEmpty);
        final lockIssue = lockIssues.first;
        expect(lockIssue.issueType, equals(IssueType.dependenciesMissing));
        expect(lockIssue.severity, equals(IssueSeverity.medium));
      });

      test('should analyze multiple platforms', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        // Don't create registrant files for any platform

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android', 'ios'],
          excludePlugins: [],
        );

        final androidIssues = issues.where(
          (issue) => issue.affectedPlatforms.contains('android'),
        );
        final iosIssues = issues.where(
          (issue) => issue.affectedPlatforms.contains('ios'),
        );

        expect(androidIssues, isNotEmpty);
        expect(iosIssues, isNotEmpty);
      });

      test('should handle analysis errors gracefully', () async {
        // Create a directory that will cause permission errors
        final restrictedDir = Directory(path.join(tempDir.path, 'restricted'));
        await restrictedDir.create();
        
        // Try to analyze a non-existent subdirectory
        final nonExistentPath = path.join(tempDir.path, 'nonexistent');

        final issues = await analyzer.analyze(
          projectPath: nonExistentPath,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        expect(issues, isNotEmpty);
        final errorIssue = issues.firstWhere(
          (issue) => issue.issueType == IssueType.initializationFailure,
        );
        expect(errorIssue.severity, equals(IssueSeverity.high));
      });
    });

    group('platform-specific analysis', () {
      test('should analyze Android build.gradle issues', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        await _createAndroidBuildGradle(tempDir, missingApplicationPlugin: true);

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['android'],
          excludePlugins: [],
        );

        final buildIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'android_build',
          orElse: () => throw StateError('No build issue found'),
        );
        expect(buildIssue.issueType, equals(IssueType.buildConfigIssue));
        expect(buildIssue.severity, equals(IssueSeverity.medium));
      });

      test('should analyze iOS Podfile issues', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['camera']);
        await _createIosPodfile(tempDir, missingUseFrameworks: true);

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['ios'],
          excludePlugins: [],
        );

        final buildIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'ios_build',
          orElse: () => throw StateError('No build issue found'),
        );
        expect(buildIssue.issueType, equals(IssueType.buildConfigIssue));
        expect(buildIssue.severity, equals(IssueSeverity.medium));
      });

      test('should analyze web index.html issues', () async {
        await _createFlutterProjectWithPlugins(tempDir, ['firebase_core_web']);
        await _createWebIndexHtml(tempDir, missingScripts: true);

        final issues = await analyzer.analyze(
          projectPath: tempDir.path,
          includePlatforms: ['web'],
          excludePlugins: [],
        );

        final webIssue = issues.firstWhere(
          (issue) => issue.pluginName == 'firebase_core_web',
          orElse: () => throw StateError('No web issue found'),
        );
        expect(webIssue.issueType, equals(IssueType.platformConfigMissing));
        expect(webIssue.severity, equals(IssueSeverity.medium));
      });
    });
  });
}

// Helper functions for creating test project structures

Future<void> _createValidFlutterProject(Directory dir) async {
  await _createPubspecYaml(dir, []);
  await _createPubspecLock(dir);
}

Future<void> _createFlutterProjectWithPlugins(Directory dir, List<String> plugins) async {
  await _createPubspecYaml(dir, plugins);
  await _createPubspecLock(dir);
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

Future<void> _createAndroidRegistrantFile(Directory dir, List<String> plugins) async {
  final androidDir = Directory(path.join(dir.path, 'android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'));
  await androidDir.create(recursive: true);
  
  final registrantFile = File(path.join(androidDir.path, 'GeneratedPluginRegistrant.java'));
  final pluginRegistrations = plugins.map((plugin) => '    ${plugin}Plugin.registerWith(registry.registrarFor("${plugin}Plugin"));').join('\n');
  
  final content = '''
package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;

@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
$pluginRegistrations
  }
}
''';

  await registrantFile.writeAsString(content);
}

Future<void> _createAndroidBuildGradle(Directory dir, {bool missingApplicationPlugin = false}) async {
  final androidDir = Directory(path.join(dir.path, 'android', 'app'));
  await androidDir.create(recursive: true);
  
  final buildGradleFile = File(path.join(androidDir.path, 'build.gradle'));
  final applicationPlugin = missingApplicationPlugin ? '' : "apply plugin: 'com.android.application'";
  
  final content = '''
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')

$applicationPlugin

android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.example.test_project"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0"
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:\$kotlin_version"
}
''';

  await buildGradleFile.writeAsString(content);
}

Future<void> _createIosPodfile(Directory dir, {bool missingUseFrameworks = false}) async {
  final iosDir = Directory(path.join(dir.path, 'ios'));
  await iosDir.create(recursive: true);
  
  final podfile = File(path.join(iosDir.path, 'Podfile'));
  final useFrameworks = missingUseFrameworks ? '' : 'use_frameworks!';
  
  final content = '''
platform :ios, '11.0'

$useFrameworks

target 'Runner' do
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
''';

  await podfile.writeAsString(content);
}

Future<void> _createWebIndexHtml(Directory dir, {bool missingScripts = false}) async {
  final webDir = Directory(path.join(dir.path, 'web'));
  await webDir.create(recursive: true);
  
  final indexFile = File(path.join(webDir.path, 'index.html'));
  final firebaseScript = missingScripts ? '' : '<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>';
  
  final content = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A test Flutter project.">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="test_project">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <title>test_project</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  $firebaseScript
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
''';

  await indexFile.writeAsString(content);
}
