import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../core/plugin_issue.dart';

/// Analyzes Flutter project files to detect plugin configuration issues
class StaticAnalyzer {
  /// Creates a new static analyzer instance
  const StaticAnalyzer();

  /// Analyzes the Flutter project for plugin configuration issues
  Future<List<PluginIssue>> analyze({
    required String projectPath,
    List<String> includePlatforms = const ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
    List<String> excludePlugins = const <String>[],
  }) async {
    final issues = <PluginIssue>[];
    
    try {
      // Parse pubspec.yaml to get declared plugins
      final declaredPlugins = await _parsePubspecPlugins(projectPath);
      
      // Filter out excluded plugins
      final filteredPlugins = declaredPlugins
          .where((plugin) => !excludePlugins.contains(plugin))
          .toList();
      
      // Check for platform-specific registration issues
      for (final platform in includePlatforms) {
        final platformIssues = await _analyzePlatform(
          projectPath,
          platform,
          filteredPlugins,
        );
        issues.addAll(platformIssues);
      }
      
      // Check for version mismatches
      final versionIssues = await _analyzeVersionMismatches(
        projectPath,
        filteredPlugins,
      );
      issues.addAll(versionIssues);
      
      // Check for missing dependencies
      final dependencyIssues = await _analyzeDependencies(
        projectPath,
        filteredPlugins,
      );
      issues.addAll(dependencyIssues);
      
    } catch (e) {
      issues.add(
        PluginIssue(
          pluginName: 'static_analyzer',
          issueType: IssueType.initializationFailure,
          severity: IssueSeverity.high,
          description: 'Static analysis failed: ${e.toString()}',
          affectedPlatforms: includePlatforms,
          detectedAt: DateTime.now(),
          additionalContext: {'error': e.toString()},
        ),
      );
    }
    
    return issues;
  }

  /// Parses pubspec.yaml to extract plugin dependencies
  Future<List<String>> _parsePubspecPlugins(String projectPath) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    
    if (!await pubspecFile.exists()) {
      throw FileSystemException('pubspec.yaml not found', projectPath);
    }
    
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent) as Map;
    
    final plugins = <String>[];
    
    // Check dependencies section
    final dependencies = pubspec['dependencies'] as Map?;
    if (dependencies != null) {
      for (final entry in dependencies.entries) {
        final name = entry.key as String;
        // Skip Flutter SDK and Dart SDK dependencies
        if (name != 'flutter' && name != 'cupertino_icons') {
          plugins.add(name);
        }
      }
    }
    
    // Check dev_dependencies section for plugins that might be used in development
    final devDependencies = pubspec['dev_dependencies'] as Map?;
    if (devDependencies != null) {
      for (final entry in devDependencies.entries) {
        final name = entry.key as String;
        // Only include known plugin-type dev dependencies
        if (_isLikelyPlugin(name)) {
          plugins.add(name);
        }
      }
    }
    
    return plugins;
  }

  /// Analyzes platform-specific plugin registration
  Future<List<PluginIssue>> _analyzePlatform(
    String projectPath,
    String platform,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    switch (platform) {
      case 'android':
        issues.addAll(await _analyzeAndroidPlatform(projectPath, declaredPlugins));
        break;
      case 'ios':
        issues.addAll(await _analyzeIosPlatform(projectPath, declaredPlugins));
        break;
      case 'web':
        issues.addAll(await _analyzeWebPlatform(projectPath, declaredPlugins));
        break;
      case 'windows':
        issues.addAll(await _analyzeWindowsPlatform(projectPath, declaredPlugins));
        break;
      case 'macos':
        issues.addAll(await _analyzeMacosPlatform(projectPath, declaredPlugins));
        break;
      case 'linux':
        issues.addAll(await _analyzeLinuxPlatform(projectPath, declaredPlugins));
        break;
    }
    
    return issues;
  }

  /// Analyzes Android platform plugin registration
  Future<List<PluginIssue>> _analyzeAndroidPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check GeneratedPluginRegistrant.java
    final registrantFile = File(path.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'java',
      'io',
      'flutter',
      'plugins',
      'GeneratedPluginRegistrant.java',
    ));
    
    if (await registrantFile.exists()) {
      final registrantContent = await registrantFile.readAsString();
      final registeredPlugins = _extractRegisteredPlugins(registrantContent);
      
      // Find plugins declared but not registered
      for (final plugin in declaredPlugins) {
        if (!registeredPlugins.contains(plugin) && _requiresAndroidRegistration(plugin)) {
          issues.add(
            PluginIssue(
              pluginName: plugin,
              issueType: IssueType.missingRegistration,
              severity: IssueSeverity.high,
              description: 'Plugin $plugin is declared in pubspec.yaml but not registered for Android',
              affectedPlatforms: ['android'],
              detectedAt: DateTime.now(),
              additionalContext: {
                'registrantFile': registrantFile.path,
                'registeredPlugins': registeredPlugins,
              },
            ),
          );
        }
      }
    } else {
      // GeneratedPluginRegistrant.java is missing
      if (declaredPlugins.isNotEmpty) {
        issues.add(
          PluginIssue(
            pluginName: 'android_registrant',
            issueType: IssueType.missingRegistration,
            severity: IssueSeverity.critical,
            description: 'GeneratedPluginRegistrant.java is missing for Android platform',
            affectedPlatforms: ['android'],
            detectedAt: DateTime.now(),
            additionalContext: {
              'expectedPath': registrantFile.path,
              'declaredPlugins': declaredPlugins,
            },
          ),
        );
      }
    }
    
    // Check build.gradle for plugin configurations
    final buildGradleFile = File(path.join(projectPath, 'android', 'app', 'build.gradle'));
    if (await buildGradleFile.exists()) {
      final buildGradleContent = await buildGradleFile.readAsString();
      issues.addAll(await _analyzeBuildGradle(buildGradleContent, declaredPlugins));
    }
    
    return issues;
  }

  /// Analyzes iOS platform plugin registration
  Future<List<PluginIssue>> _analyzeIosPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check GeneratedPluginRegistrant.m
    final registrantFile = File(path.join(
      projectPath,
      'ios',
      'Runner',
      'GeneratedPluginRegistrant.m',
    ));
    
    if (await registrantFile.exists()) {
      final registrantContent = await registrantFile.readAsString();
      final registeredPlugins = _extractRegisteredPlugins(registrantContent);
      
      // Find plugins declared but not registered
      for (final plugin in declaredPlugins) {
        if (!registeredPlugins.contains(plugin) && _requiresIosRegistration(plugin)) {
          issues.add(
            PluginIssue(
              pluginName: plugin,
              issueType: IssueType.missingRegistration,
              severity: IssueSeverity.high,
              description: 'Plugin $plugin is declared in pubspec.yaml but not registered for iOS',
              affectedPlatforms: ['ios'],
              detectedAt: DateTime.now(),
              additionalContext: {
                'registrantFile': registrantFile.path,
                'registeredPlugins': registeredPlugins,
              },
            ),
          );
        }
      }
    } else {
      // GeneratedPluginRegistrant.m is missing
      if (declaredPlugins.isNotEmpty) {
        issues.add(
          PluginIssue(
            pluginName: 'ios_registrant',
            issueType: IssueType.missingRegistration,
            severity: IssueSeverity.critical,
            description: 'GeneratedPluginRegistrant.m is missing for iOS platform',
            affectedPlatforms: ['ios'],
            detectedAt: DateTime.now(),
            additionalContext: {
              'expectedPath': registrantFile.path,
              'declaredPlugins': declaredPlugins,
            },
          ),
        );
      }
    }
    
    // Check Podfile for plugin configurations
    final podfile = File(path.join(projectPath, 'ios', 'Podfile'));
    if (await podfile.exists()) {
      final podfileContent = await podfile.readAsString();
      issues.addAll(await _analyzePodfile(podfileContent, declaredPlugins));
    }
    
    return issues;
  }

  /// Analyzes Web platform plugin registration
  Future<List<PluginIssue>> _analyzeWebPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check web/index.html for plugin script imports
    final indexFile = File(path.join(projectPath, 'web', 'index.html'));
    if (await indexFile.exists()) {
      final indexContent = await indexFile.readAsString();
      issues.addAll(await _analyzeWebIndex(indexContent, declaredPlugins));
    }
    
    return issues;
  }

  /// Analyzes Windows platform plugin registration
  Future<List<PluginIssue>> _analyzeWindowsPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check generated_plugin_registrant.cc
    final registrantFile = File(path.join(
      projectPath,
      'windows',
      'flutter',
      'generated_plugin_registrant.cc',
    ));
    
    if (await registrantFile.exists()) {
      final registrantContent = await registrantFile.readAsString();
      final registeredPlugins = _extractRegisteredPlugins(registrantContent);
      
      for (final plugin in declaredPlugins) {
        if (!registeredPlugins.contains(plugin) && _requiresWindowsRegistration(plugin)) {
          issues.add(
            PluginIssue(
              pluginName: plugin,
              issueType: IssueType.missingRegistration,
              severity: IssueSeverity.high,
              description: 'Plugin $plugin is declared in pubspec.yaml but not registered for Windows',
              affectedPlatforms: ['windows'],
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }
    
    return issues;
  }

  /// Analyzes macOS platform plugin registration
  Future<List<PluginIssue>> _analyzeMacosPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check GeneratedPluginRegistrant.swift
    final registrantFile = File(path.join(
      projectPath,
      'macos',
      'Flutter',
      'GeneratedPluginRegistrant.swift',
    ));
    
    if (await registrantFile.exists()) {
      final registrantContent = await registrantFile.readAsString();
      final registeredPlugins = _extractRegisteredPlugins(registrantContent);
      
      for (final plugin in declaredPlugins) {
        if (!registeredPlugins.contains(plugin) && _requiresMacosRegistration(plugin)) {
          issues.add(
            PluginIssue(
              pluginName: plugin,
              issueType: IssueType.missingRegistration,
              severity: IssueSeverity.high,
              description: 'Plugin $plugin is declared in pubspec.yaml but not registered for macOS',
              affectedPlatforms: ['macos'],
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }
    
    return issues;
  }

  /// Analyzes Linux platform plugin registration
  Future<List<PluginIssue>> _analyzeLinuxPlatform(
    String projectPath,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check generated_plugin_registrant.cc
    final registrantFile = File(path.join(
      projectPath,
      'linux',
      'flutter',
      'generated_plugin_registrant.cc',
    ));
    
    if (await registrantFile.exists()) {
      final registrantContent = await registrantFile.readAsString();
      final registeredPlugins = _extractRegisteredPlugins(registrantContent);
      
      for (final plugin in declaredPlugins) {
        if (!registeredPlugins.contains(plugin) && _requiresLinuxRegistration(plugin)) {
          issues.add(
            PluginIssue(
              pluginName: plugin,
              issueType: IssueType.missingRegistration,
              severity: IssueSeverity.high,
              description: 'Plugin $plugin is declared in pubspec.yaml but not registered for Linux',
              affectedPlatforms: ['linux'],
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }
    
    return issues;
  }

  /// Analyzes version mismatches between platforms
  Future<List<PluginIssue>> _analyzeVersionMismatches(
    String projectPath,
    List<String> plugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // This would require more sophisticated analysis of lock files
    // and platform-specific version constraints
    
    return issues;
  }

  /// Analyzes missing dependencies
  Future<List<PluginIssue>> _analyzeDependencies(
    String projectPath,
    List<String> plugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check if pubspec.lock exists and is up to date
    final lockFile = File(path.join(projectPath, 'pubspec.lock'));
    if (!await lockFile.exists()) {
      issues.add(
        PluginIssue(
          pluginName: 'dependency_management',
          issueType: IssueType.dependenciesMissing,
          severity: IssueSeverity.medium,
          description: 'pubspec.lock file is missing. Run "flutter pub get" to resolve dependencies.',
          affectedPlatforms: ['all'],
          detectedAt: DateTime.now(),
        ),
      );
    }
    
    return issues;
  }

  /// Extracts registered plugin names from registrant file content
  List<String> _extractRegisteredPlugins(String content) {
    final plugins = <String>[];
    
    // Look for plugin registration patterns
    final patterns = [
      RegExp(r'(\w+)Plugin\.register'),
      RegExp(r'registry\.registrarFor\("(\w+)"\)'),
      RegExp(r'#import <(\w+)/'),
      RegExp(r'@import (\w+);'),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        final pluginName = match.group(1);
        if (pluginName != null && !plugins.contains(pluginName)) {
          plugins.add(pluginName);
        }
      }
    }
    
    return plugins;
  }

  /// Analyzes Android build.gradle for plugin issues
  Future<List<PluginIssue>> _analyzeBuildGradle(
    String content,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check for common build configuration issues
    if (!content.contains('apply plugin: \'com.android.application\'')) {
      issues.add(
        PluginIssue(
          pluginName: 'android_build',
          issueType: IssueType.buildConfigIssue,
          severity: IssueSeverity.medium,
          description: 'Android application plugin not applied in build.gradle',
          affectedPlatforms: ['android'],
          detectedAt: DateTime.now(),
        ),
      );
    }
    
    return issues;
  }

  /// Analyzes iOS Podfile for plugin issues
  Future<List<PluginIssue>> _analyzePodfile(
    String content,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check for common Podfile issues
    if (!content.contains('use_frameworks!') && _hasSwiftPlugins(declaredPlugins)) {
      issues.add(
        PluginIssue(
          pluginName: 'ios_build',
          issueType: IssueType.buildConfigIssue,
          severity: IssueSeverity.medium,
          description: 'use_frameworks! may be required for Swift plugins in Podfile',
          affectedPlatforms: ['ios'],
          detectedAt: DateTime.now(),
        ),
      );
    }
    
    return issues;
  }

  /// Analyzes web index.html for plugin issues
  Future<List<PluginIssue>> _analyzeWebIndex(
    String content,
    List<String> declaredPlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check for web-specific plugin script imports
    for (final plugin in declaredPlugins) {
      if (_requiresWebScriptImport(plugin) && !content.contains(plugin)) {
        issues.add(
          PluginIssue(
            pluginName: plugin,
            issueType: IssueType.platformConfigMissing,
            severity: IssueSeverity.medium,
            description: 'Plugin $plugin may require script import in web/index.html',
            affectedPlatforms: ['web'],
            detectedAt: DateTime.now(),
          ),
        );
      }
    }
    
    return issues;
  }

  /// Checks if a dependency name is likely a plugin
  bool _isLikelyPlugin(String name) {
    // Common patterns for plugin names
    return name.contains('plugin') || 
           name.endsWith('_plugin') || 
           _knownPlugins.contains(name);
  }

  /// Checks if a plugin requires Android registration
  bool _requiresAndroidRegistration(String plugin) {
    return !_pureFlutterPackages.contains(plugin);
  }

  /// Checks if a plugin requires iOS registration
  bool _requiresIosRegistration(String plugin) {
    return !_pureFlutterPackages.contains(plugin);
  }

  /// Checks if a plugin requires Windows registration
  bool _requiresWindowsRegistration(String plugin) {
    return !_pureFlutterPackages.contains(plugin);
  }

  /// Checks if a plugin requires macOS registration
  bool _requiresMacosRegistration(String plugin) {
    return !_pureFlutterPackages.contains(plugin);
  }

  /// Checks if a plugin requires Linux registration
  bool _requiresLinuxRegistration(String plugin) {
    return !_pureFlutterPackages.contains(plugin);
  }

  /// Checks if any of the plugins are Swift-based
  bool _hasSwiftPlugins(List<String> plugins) {
    return plugins.any((plugin) => _swiftPlugins.contains(plugin));
  }

  /// Checks if a plugin requires web script import
  bool _requiresWebScriptImport(String plugin) {
    return _webPluginsRequiringScripts.contains(plugin);
  }

  /// Known plugin names for better detection
  static const _knownPlugins = <String>{
    'camera',
    'geolocator',
    'shared_preferences',
    'url_launcher',
    'image_picker',
    'firebase_core',
    'firebase_auth',
    'cloud_firestore',
    'firebase_messaging',
    'firebase_analytics',
    'google_maps_flutter',
    'webview_flutter',
    'video_player',
    'audioplayers',
    'flutter_local_notifications',
    'permission_handler',
    'device_info_plus',
    'package_info_plus',
    'connectivity_plus',
    'battery_plus',
    'sensors_plus',
  };

  /// Pure Flutter packages that don't require platform registration
  static const _pureFlutterPackages = <String>{
    'provider',
    'riverpod',
    'bloc',
    'flutter_bloc',
    'get',
    'dio',
    'http',
    'json_annotation',
    'freezed_annotation',
    'equatable',
    'dartz',
    'rxdart',
    'intl',
    'flutter_localizations',
  };

  /// Plugins known to be Swift-based
  static const _swiftPlugins = <String>{
    'camera',
    'image_picker',
    'video_player',
  };

  /// Web plugins that require script imports
  static const _webPluginsRequiringScripts = <String>{
    'google_maps_flutter_web',
    'firebase_core_web',
    'firebase_auth_web',
  };
}
