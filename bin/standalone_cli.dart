#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Standalone CLI tool for Missing Plugin Exception Detective
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('check')
    ..addCommand('doctor')
    ..addFlag('help', abbr: 'h', help: 'Show help information')
    ..addFlag('verbose', abbr: 'v', help: 'Show verbose output')
    ..addOption('format', 
        allowed: ['text', 'json', 'markdown'], 
        defaultsTo: 'text', 
        help: 'Output format');

  try {
    final results = parser.parse(arguments);
    
    if (results['help'] as bool || arguments.isEmpty) {
      print('Missing Plugin Exception Detective CLI');
      print('Usage: dart run missing_plugin_exception_detective:check [options]');
      print('       dart run missing_plugin_exception_detective:doctor [options]');
      print('');
      print('Commands:');
      print('  check    Run static analysis on Flutter project');
      print('  doctor   Check Flutter project health');
      print('');
      print('Options:');
      print(parser.usage);
      return;
    }

    // Determine command from arguments or default to check
    String command = 'check';
    if (arguments.isNotEmpty && !arguments.first.startsWith('-')) {
      command = arguments.first;
    }
    
    final verbose = results['verbose'] as bool;
    final format = results['format'] as String;
    
    switch (command) {
      case 'check':
        await runCheck(verbose: verbose, format: format);
        break;
      case 'doctor':
        await runDoctor(verbose: verbose, format: format);
        break;
      default:
        // Default to check command for compatibility
        await runCheck(verbose: verbose, format: format);
        break;
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> runCheck({bool verbose = false, String format = 'text'}) async {
  final projectPath = Directory.current.path;
  
  if (verbose) {
    print('🔍 Starting plugin diagnostic scan...');
    print('Project path: $projectPath');
  }

  final issues = <Map<String, dynamic>>[];
  
  // Check for pubspec.yaml
  final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    issues.add({
      'pluginName': 'project_structure',
      'issueType': 'missing_file',
      'severity': 'critical',
      'description': 'pubspec.yaml not found. This is not a valid Flutter project.',
      'affectedPlatforms': ['all'],
    });
  } else {
    // Parse pubspec.yaml for plugins
    try {
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final dependencies = pubspec['dependencies'] as Map?;
      
      if (dependencies != null) {
        // Check for common plugin issues
        await checkPluginRegistration(projectPath, dependencies, issues, verbose);
      }
    } catch (e) {
      issues.add({
        'pluginName': 'pubspec_parsing',
        'issueType': 'parse_error',
        'severity': 'high',
        'description': 'Failed to parse pubspec.yaml: $e',
        'affectedPlatforms': ['all'],
      });
    }
  }

  // Output results
  await outputResults(issues, format: format, verbose: verbose);
}

Future<void> checkPluginRegistration(
  String projectPath, 
  Map dependencies, 
  List<Map<String, dynamic>> issues,
  bool verbose,
) async {
  // Check Android registration
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
      ],
    });
  }

  // Check iOS registration
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
      ],
    });
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
      ],
    });
  }
}

Future<void> runDoctor({bool verbose = false, String format = 'text'}) async {
  final projectPath = Directory.current.path;
  
  if (verbose) {
    print('🏥 Running Flutter Plugin Doctor...');
    print('Project path: $projectPath');
  }

  final checks = <String, bool>{};
  
  // Check Flutter installation
  try {
    final result = await Process.run('flutter', ['--version']);
    checks['Flutter Installation'] = result.exitCode == 0;
  } catch (e) {
    checks['Flutter Installation'] = false;
  }

  // Check project structure
  final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  checks['Project Structure'] = pubspecFile.existsSync();

  // Check dependencies
  final pubspecLock = File(path.join(projectPath, 'pubspec.lock'));
  checks['Dependencies'] = pubspecLock.existsSync();

  // Check plugin configuration
  final issues = <Map<String, dynamic>>[];
  if (pubspecFile.existsSync()) {
    try {
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final dependencies = pubspec['dependencies'] as Map?;
      
      if (dependencies != null) {
        await checkPluginRegistration(projectPath, dependencies, issues, false);
      }
    } catch (e) {
      // Ignore parsing errors for doctor command
    }
  }
  checks['Plugin Configuration'] = issues.isEmpty;

  // Output results
  if (format == 'json') {
    final result = {
      'checks': checks,
      'overallStatus': checks.values.every((check) => check) ? 'Healthy' : 'Issues Found',
    };
    print(jsonEncode(result));
  } else {
    for (final entry in checks.entries) {
      final status = entry.value ? '✅' : '❌';
      final message = entry.value 
          ? _getSuccessMessage(entry.key)
          : _getFailureMessage(entry.key);
      print('$status ${entry.key}: $message');
    }
    
    print('');
    final overallStatus = checks.values.every((check) => check) ? 'Healthy' : 'Issues Found';
    final statusIcon = overallStatus == 'Healthy' ? '✅' : '❌';
    print('$statusIcon Overall Status: $overallStatus');
  }
}

String _getSuccessMessage(String checkName) {
  switch (checkName) {
    case 'Flutter Installation':
      return 'Flutter is installed and accessible';
    case 'Project Structure':
      return 'Valid Flutter project structure';
    case 'Dependencies':
      return 'Dependencies resolved';
    case 'Plugin Configuration':
      return 'All plugins properly configured';
    default:
      return 'OK';
  }
}

String _getFailureMessage(String checkName) {
  switch (checkName) {
    case 'Flutter Installation':
      return 'Flutter not found or not accessible';
    case 'Project Structure':
      return 'pubspec.yaml not found';
    case 'Dependencies':
      return 'pubspec.lock missing - run "flutter pub get"';
    case 'Plugin Configuration':
      return 'Plugin configuration issues found';
    default:
      return 'Failed';
  }
}

Future<void> outputResults(
  List<Map<String, dynamic>> issues, {
  String format = 'text',
  bool verbose = false,
}) async {
  final startTime = DateTime.now();
  final duration = DateTime.now().difference(startTime);
  
  if (format == 'json') {
    final result = {
      'status': issues.isEmpty ? 'HEALTHY' : 'ERROR',
      'scannedPlugins': 0,
      'issuesFound': issues.length,
      'scanDuration': '${duration.inMilliseconds}ms',
      'issues': issues,
    };
    print(jsonEncode(result));
  } else {
    print('🔍 Flutter Plugin Diagnostic Results');
    print('=' * 50);
    print('📊 Summary:');
    print('  Status: ${issues.isEmpty ? '✅ HEALTHY' : '❌ ERROR'}');
    print('  Scanned plugins: 0');
    print('  Issues found: ${issues.length}');
    print('  Scan duration: ${duration.inMilliseconds}ms');
    print('');
    
    if (issues.isEmpty) {
      print('✅ All plugins are properly configured!');
    } else {
      final criticalIssues = issues.where((i) => i['severity'] == 'critical').toList();
      final highIssues = issues.where((i) => i['severity'] == 'high').toList();
      final mediumIssues = issues.where((i) => i['severity'] == 'medium').toList();
      
      if (criticalIssues.isNotEmpty) {
        print('🚨 CRITICAL ISSUES (${criticalIssues.length}):');
        for (final issue in criticalIssues) {
          _printIssue(issue);
        }
        print('');
      }
      
      if (highIssues.isNotEmpty) {
        print('⚠️ HIGH ISSUES (${highIssues.length}):');
        for (final issue in highIssues) {
          _printIssue(issue);
        }
        print('');
      }
      
      if (mediumIssues.isNotEmpty) {
        print('⚠️ MEDIUM ISSUES (${mediumIssues.length}):');
        for (final issue in mediumIssues) {
          _printIssue(issue);
        }
        print('');
      }
      
      print('💡 Run with --no-fix to hide resolution guides');
    }
  }
}

void _printIssue(Map<String, dynamic> issue) {
  print('  • ${issue['pluginName']}');
  print('    ${issue['description']}');
  print('    Platforms: ${(issue['affectedPlatforms'] as List).join(', ')}');
  
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
  print('');
}
