#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Flutter-compatible CLI tool for Missing Plugin Exception Detective
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show help information')
    ..addFlag('verbose', abbr: 'v', help: 'Show verbose output')
    ..addFlag('no-fix', help: 'Hide resolution guides')
    ..addOption('format', 
        allowed: ['text', 'json', 'markdown'], 
        defaultsTo: 'text', 
        help: 'Output format')
    ..addMultiOption('platforms', 
        allowed: ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
        help: 'Filter by platforms')
    ..addMultiOption('exclude', 
        help: 'Exclude specific plugins from analysis');

  try {
    final results = parser.parse(arguments);
    
    if (results['help'] as bool) {
      print('Missing Plugin Exception Detective - Check Command');
      print('Usage: flutter pub run missing_plugin_exception_detective:check [options]');
      print('');
      print('Options:');
      print(parser.usage);
      return;
    }

    final verbose = results['verbose'] as bool;
    final format = results['format'] as String;
    final noFix = results['no-fix'] as bool;
    final platforms = results['platforms'] as List<String>;
    final excludePlugins = results['exclude'] as List<String>;
    
    await runPluginCheck(
      verbose: verbose, 
      format: format, 
      showFix: !noFix,
      platforms: platforms,
      excludePlugins: excludePlugins,
    );
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> runPluginCheck({
  bool verbose = false, 
  String format = 'text',
  bool showFix = true,
  List<String> platforms = const [],
  List<String> excludePlugins = const [],
}) async {
  final projectPath = Directory.current.path;
  final startTime = DateTime.now();
  
  if (verbose) {
    print('🔍 Starting plugin diagnostic scan...');
    print('Project path: $projectPath');
    if (platforms.isNotEmpty) {
      print('Platforms: ${platforms.join(', ')}');
    }
  }

  final issues = <Map<String, dynamic>>[];
  final scannedPlugins = <String>[];
  
  // Check for pubspec.yaml
  final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    issues.add({
      'pluginName': 'project_structure',
      'issueType': 'missing_file',
      'severity': 'critical',
      'description': 'pubspec.yaml not found. This is not a valid Flutter project.',
      'affectedPlatforms': ['all'],
      'resolutionSteps': [
        {
          'title': 'Navigate to Flutter Project',
          'description': 'Ensure you are running this command from a Flutter project directory',
          'action': 'showInfo',
        },
        {
          'title': 'Create Flutter Project',
          'description': 'If this is not a Flutter project, create one first',
          'action': 'runCommand',
          'command': 'flutter create my_app',
        },
      ],
    });
  } else {
    // Parse pubspec.yaml for plugins
    try {
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final dependencies = pubspec['dependencies'] as Map?;
      
      if (dependencies != null) {
        // Find Flutter plugins
        for (final entry in dependencies.entries) {
          final pluginName = entry.key as String;
          if (pluginName != 'flutter' && !excludePlugins.contains(pluginName)) {
            scannedPlugins.add(pluginName);
          }
        }
        
        await checkPluginRegistration(
          projectPath, 
          dependencies, 
          issues, 
          verbose,
          platforms: platforms,
          excludePlugins: excludePlugins,
        );
      }
    } catch (e) {
      issues.add({
        'pluginName': 'pubspec_parsing',
        'issueType': 'parse_error',
        'severity': 'high',
        'description': 'Failed to parse pubspec.yaml: $e',
        'affectedPlatforms': ['all'],
        'resolutionSteps': [
          {
            'title': 'Fix YAML Syntax',
            'description': 'Check pubspec.yaml for syntax errors',
            'action': 'showInfo',
          },
        ],
      });
    }
  }

  final duration = DateTime.now().difference(startTime);
  
  // Output results
  await outputResults(
    issues, 
    scannedPlugins: scannedPlugins,
    format: format, 
    verbose: verbose,
    showFix: showFix,
    duration: duration,
  );
  
  // Exit with appropriate code
  exit(issues.any((issue) => issue['severity'] == 'critical') ? 1 : 0);
}

Future<void> checkPluginRegistration(
  String projectPath, 
  Map dependencies, 
  List<Map<String, dynamic>> issues,
  bool verbose, {
  List<String> platforms = const [],
  List<String> excludePlugins = const [],
}) async {
  final checkPlatforms = platforms.isEmpty ? ['android', 'ios'] : platforms;
  
  // Check Android registration
  if (checkPlatforms.contains('android')) {
    final androidRegistrant = File(path.join(
      projectPath, 
      'android', 
      'app', 
      'src', 
      'main', 
      'java', 
      'io', 
      'flutter', 
      'plugins', 
      'GeneratedPluginRegistrant.java'
    ));
    
    if (!androidRegistrant.existsSync()) {
      issues.add({
        'pluginName': 'android_registrant',
        'issueType': 'missing_registration',
        'severity': 'critical',
        'description': 'GeneratedPluginRegistrant.java is missing for Android platform',
        'affectedPlatforms': ['android'],
        'resolutionSteps': [
          {
            'title': 'Clean Flutter Project',
            'description': 'Clean the Flutter project to remove build artifacts',
            'action': 'runCommand',
            'command': 'flutter clean',
          },
          {
            'title': 'Get Dependencies',
            'description': 'Fetch project dependencies',
            'action': 'runCommand',
            'command': 'flutter pub get',
          },
          {
            'title': 'Regenerate Android Plugin Registration',
            'description': 'Build the project to regenerate plugin registration files',
            'action': 'runCommand',
            'command': 'flutter build apk --debug',
          },
          {
            'title': 'Rebuild Project',
            'description': 'Rebuild the project completely',
            'action': 'runCommand',
            'command': 'flutter build apk --debug',
          },
        ],
      });
    }
  }

  // Check iOS registration
  if (checkPlatforms.contains('ios')) {
    final iosRegistrant = File(path.join(
      projectPath, 
      'ios', 
      'Runner', 
      'GeneratedPluginRegistrant.m'
    ));
    
    if (!iosRegistrant.existsSync()) {
      issues.add({
        'pluginName': 'ios_registrant',
        'issueType': 'missing_registration',
        'severity': 'critical',
        'description': 'GeneratedPluginRegistrant.m is missing for iOS platform',
        'affectedPlatforms': ['ios'],
        'resolutionSteps': [
          {
            'title': 'Clean Flutter Project',
            'description': 'Clean the Flutter project to remove build artifacts',
            'action': 'runCommand',
            'command': 'flutter clean',
          },
          {
            'title': 'Get Dependencies',
            'description': 'Fetch project dependencies',
            'action': 'runCommand',
            'command': 'flutter pub get',
          },
          {
            'title': 'Update iOS Pods',
            'description': 'Update iOS CocoaPods dependencies',
            'action': 'runCommand',
            'command': 'cd ios && pod install --repo-update',
          },
          {
            'title': 'Rebuild Project',
            'description': 'Rebuild the project completely',
            'action': 'runCommand',
            'command': 'flutter build ios --debug',
          },
        ],
      });
    }
  }

  // Check pubspec.lock
  final pubspecLock = File(path.join(projectPath, 'pubspec.lock'));
  if (!pubspecLock.existsSync()) {
    issues.add({
      'pluginName': 'dependency_management',
      'issueType': 'missing_lock_file',
      'severity': 'medium',
      'description': 'pubspec.lock file is missing. Run "flutter pub get" to resolve dependencies.',
      'affectedPlatforms': ['all'],
      'resolutionSteps': [
        {
          'title': 'Install Dependencies',
          'description': 'Install project dependencies',
          'action': 'runCommand',
          'command': 'flutter pub get',
        },
        {
          'title': 'Check Dependency Conflicts',
          'description': 'Check for dependency conflicts',
          'action': 'runCommand',
          'command': 'flutter pub deps',
        },
        {
          'title': 'Resolve Conflicts',
          'description': 'Manually resolve any dependency conflicts in pubspec.yaml',
          'action': 'showInfo',
        },
      ],
    });
  }
}

Future<void> outputResults(
  List<Map<String, dynamic>> issues, {
  List<String> scannedPlugins = const [],
  String format = 'text',
  bool verbose = false,
  bool showFix = true,
  Duration? duration,
}) async {
  final scanDuration = duration?.inMilliseconds ?? 0;
  
  if (format == 'json') {
    final result = {
      'status': issues.isEmpty ? 'HEALTHY' : (issues.any((i) => i['severity'] == 'critical') ? 'ERROR' : 'WARNING'),
      'scannedPlugins': scannedPlugins.length,
      'issuesFound': issues.length,
      'scanDuration': '${scanDuration}ms',
      'issues': issues,
      'summary': issues.isEmpty 
          ? 'All ${scannedPlugins.length} plugins are properly configured.'
          : '${issues.length} issues found across ${scannedPlugins.length} scanned plugins.',
    };
    print(jsonEncode(result));
  } else if (format == 'markdown') {
    print('# Flutter Plugin Diagnostic Report');
    print('');
    print('## Summary');
    print('');
    print('| Metric | Value |');
    print('|--------|-------|');
    print('| Status | ${issues.isEmpty ? 'HEALTHY' : 'ISSUES FOUND'} |');
    print('| Scanned Plugins | ${scannedPlugins.length} |');
    print('| Issues Found | ${issues.length} |');
    print('| Scan Duration | ${scanDuration}ms |');
    print('');
    
    if (issues.isEmpty) {
      print('✅ **All plugins are properly configured!**');
    } else {
      _printMarkdownIssues(issues, showFix);
    }
  } else {
    print('🔍 Flutter Plugin Diagnostic Results');
    print('=' * 50);
    print('📊 Summary:');
    print('  Status: ${issues.isEmpty ? '✅ HEALTHY' : (issues.any((i) => i['severity'] == 'critical') ? '💥 FAILED' : '⚠️ WARNING')}');
    print('  Scanned plugins: ${scannedPlugins.length}');
    print('  Issues found: ${issues.length}');
    print('  Scan duration: ${scanDuration}ms');
    print('');
    
    if (issues.isEmpty) {
      print('✅ All plugins are properly configured!');
    } else {
      _printTextIssues(issues, showFix);
    }
  }
}

void _printTextIssues(List<Map<String, dynamic>> issues, bool showFix) {
  final criticalIssues = issues.where((i) => i['severity'] == 'critical').toList();
  final highIssues = issues.where((i) => i['severity'] == 'high').toList();
  final mediumIssues = issues.where((i) => i['severity'] == 'medium').toList();
  
  if (criticalIssues.isNotEmpty) {
    print('🚨 CRITICAL ISSUES (${criticalIssues.length}):');
    for (final issue in criticalIssues) {
      _printIssue(issue, showFix);
    }
    print('');
  }
  
  if (highIssues.isNotEmpty) {
    print('⚠️ HIGH ISSUES (${highIssues.length}):');
    for (final issue in highIssues) {
      _printIssue(issue, showFix);
    }
    print('');
  }
  
  if (mediumIssues.isNotEmpty) {
    print('⚠️ MEDIUM ISSUES (${mediumIssues.length}):');
    for (final issue in mediumIssues) {
      _printIssue(issue, showFix);
    }
    print('');
  }
  
  if (showFix) {
    print('💡 Run with --no-fix to hide resolution guides');
  }
}

void _printMarkdownIssues(List<Map<String, dynamic>> issues, bool showFix) {
  final criticalIssues = issues.where((i) => i['severity'] == 'critical').toList();
  final highIssues = issues.where((i) => i['severity'] == 'high').toList();
  final mediumIssues = issues.where((i) => i['severity'] == 'medium').toList();
  
  if (criticalIssues.isNotEmpty) {
    print('## 🚨 Critical Issues (${criticalIssues.length})');
    print('');
    for (final issue in criticalIssues) {
      _printMarkdownIssue(issue, showFix);
    }
  }
  
  if (highIssues.isNotEmpty) {
    print('## ⚠️ High Priority Issues (${highIssues.length})');
    print('');
    for (final issue in highIssues) {
      _printMarkdownIssue(issue, showFix);
    }
  }
  
  if (mediumIssues.isNotEmpty) {
    print('## ⚠️ Medium Priority Issues (${mediumIssues.length})');
    print('');
    for (final issue in mediumIssues) {
      _printMarkdownIssue(issue, showFix);
    }
  }
}

void _printIssue(Map<String, dynamic> issue, bool showFix) {
  print('  • ${issue['pluginName']}');
  print('    ${issue['description']}');
  print('    Platforms: ${(issue['affectedPlatforms'] as List).join(', ')}');
  
  if (showFix) {
    final resolutionSteps = issue['resolutionSteps'] as List?;
    if (resolutionSteps != null && resolutionSteps.isNotEmpty) {
      print('    💡 Resolution:');
      for (int i = 0; i < resolutionSteps.length; i++) {
        final step = resolutionSteps[i] as Map<String, dynamic>;
        print('       ${i + 1}. ${step['title']}');
        if (step['command'] != null) {
          print('          Run: ${step['command']}');
        }
      }
    }
  }
  print('');
}

void _printMarkdownIssue(Map<String, dynamic> issue, bool showFix) {
  print('### ${issue['pluginName']}');
  print('');
  print('**Description:** ${issue['description']}');
  print('');
  print('**Affected Platforms:** ${(issue['affectedPlatforms'] as List).join(', ')}');
  print('');
  
  if (showFix) {
    final resolutionSteps = issue['resolutionSteps'] as List?;
    if (resolutionSteps != null && resolutionSteps.isNotEmpty) {
      print('**Resolution Steps:**');
      print('');
      for (int i = 0; i < resolutionSteps.length; i++) {
        final step = resolutionSteps[i] as Map<String, dynamic>;
        print('${i + 1}. **${step['title']}**');
        if (step['command'] != null) {
          print('   ```bash');
          print('   ${step['command']}');
          print('   ```');
        }
        print('');
      }
    }
  }
}
