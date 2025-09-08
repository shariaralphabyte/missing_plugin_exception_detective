#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Simple plugin checker script that can be run directly
Future<void> main(List<String> arguments) async {
  final verbose = arguments.contains('--verbose') || arguments.contains('-v');
  final help = arguments.contains('--help') || arguments.contains('-h');
  
  if (help) {
    print('Flutter Plugin Checker');
    print('Usage: dart check_plugins.dart [--verbose] [--help]');
    print('');
    print('Options:');
    print('  --verbose, -v    Show verbose output');
    print('  --help, -h       Show this help message');
    return;
  }

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
  print('🔍 Flutter Plugin Diagnostic Results');
  print('=' * 50);
  print('📊 Summary:');
  print('  Status: ${issues.isEmpty ? '✅ HEALTHY' : '❌ ERROR'}');
  print('  Scanned plugins: 0');
  print('  Issues found: ${issues.length}');
  print('');
  
  if (issues.isEmpty) {
    print('✅ All plugins are properly configured!');
  } else {
    final criticalIssues = issues.where((i) => i['severity'] == 'critical').toList();
    final mediumIssues = issues.where((i) => i['severity'] == 'medium').toList();
    
    if (criticalIssues.isNotEmpty) {
      print('🚨 CRITICAL ISSUES (${criticalIssues.length}):');
      for (final issue in criticalIssues) {
        _printIssue(issue);
      }
    }
    
    if (mediumIssues.isNotEmpty) {
      print('⚠️ MEDIUM ISSUES (${mediumIssues.length}):');
      for (final issue in mediumIssues) {
        _printIssue(issue);
      }
    }
  }
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
    });
  }
}

void _printIssue(Map<String, dynamic> issue) {
  print('  • ${issue['pluginName']}');
  print('    ${issue['description']}');
  print('    Platforms: ${(issue['affectedPlatforms'] as List).join(', ')}');
  print('    💡 Resolution: Run "flutter clean && flutter pub get"');
  print('');
}
