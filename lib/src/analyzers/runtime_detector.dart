import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import '../core/plugin_issue.dart';

/// Detects plugin issues at runtime by monitoring exceptions and method channel calls
class RuntimeDetector {
  /// Creates a new runtime detector instance
  RuntimeDetector({
    this.enableStackTraceAnalysis = true,
    this.enableMethodChannelMonitoring = true,
    this.maxIssueHistory = 100,
  });

  /// Whether to analyze stack traces for plugin-related errors
  final bool enableStackTraceAnalysis;

  /// Whether to monitor method channel calls for missing plugins
  final bool enableMethodChannelMonitoring;

  /// Maximum number of issues to keep in history
  final int maxIssueHistory;

  final List<PluginIssue> _detectedIssues = [];
  final StreamController<PluginIssue> _issueController = StreamController.broadcast();

  /// Stream of plugin issues detected at runtime
  Stream<PluginIssue> get issueStream => _issueController.stream;

  /// List of all detected issues
  List<PluginIssue> get detectedIssues => List.unmodifiable(_detectedIssues);

  /// Detects plugin issues in the given project
  Future<List<PluginIssue>> detect({
    required String projectPath,
    List<String> includePlatforms = const ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
    List<String> excludePlugins = const <String>[],
  }) async {
    final issues = <PluginIssue>[];
    
    try {
      // Analyze existing log files for plugin errors
      final logIssues = await _analyzeLogFiles(projectPath, excludePlugins);
      issues.addAll(logIssues);
      
      // Check for common runtime patterns
      final patternIssues = await _analyzeCommonPatterns(projectPath, excludePlugins);
      issues.addAll(patternIssues);
      
    } catch (e) {
      issues.add(
        PluginIssue(
          pluginName: 'runtime_detector',
          issueType: IssueType.initializationFailure,
          severity: IssueSeverity.medium,
          description: 'Runtime detection failed: ${e.toString()}',
          affectedPlatforms: includePlatforms,
          detectedAt: DateTime.now(),
          additionalContext: {'error': e.toString()},
        ),
      );
    }
    
    return issues;
  }

  /// Starts monitoring runtime for plugin issues
  Stream<PluginIssue> monitor() {
    if (enableMethodChannelMonitoring) {
      _startMethodChannelMonitoring();
    }
    
    if (enableStackTraceAnalysis) {
      _startExceptionMonitoring();
    }
    
    return issueStream;
  }

  /// Stops monitoring and cleans up resources
  void dispose() {
    _issueController.close();
  }

  /// Analyzes log files for plugin-related errors
  Future<List<PluginIssue>> _analyzeLogFiles(
    String projectPath,
    List<String> excludePlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // Check Flutter logs directory
    final logsDir = Directory(Platform.isWindows 
        ? '${Platform.environment['APPDATA']}\\flutter\\logs'
        : '${Platform.environment['HOME']}/.flutter/logs');
    
    if (await logsDir.exists()) {
      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();
      
      for (final logFile in logFiles) {
        try {
          final content = await logFile.readAsString();
          final logIssues = _parseLogContent(content, excludePlugins);
          issues.addAll(logIssues);
        } catch (e) {
          // Skip files that can't be read
          continue;
        }
      }
    }
    
    return issues;
  }

  /// Analyzes common runtime error patterns
  Future<List<PluginIssue>> _analyzeCommonPatterns(
    String projectPath,
    List<String> excludePlugins,
  ) async {
    final issues = <PluginIssue>[];
    
    // This would typically involve checking for:
    // 1. Missing platform implementations
    // 2. Unregistered method channels
    // 3. Plugin initialization failures
    
    return issues;
  }

  /// Parses log content for plugin-related errors
  List<PluginIssue> _parseLogContent(String content, List<String> excludePlugins) {
    final issues = <PluginIssue>[];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Look for MissingPluginException
      if (line.contains('MissingPluginException')) {
        final issue = _parseMissingPluginException(line, lines, i);
        if (issue != null && !excludePlugins.contains(issue.pluginName)) {
          issues.add(issue);
        }
      }
      
      // Look for PlatformException related to plugins
      if (line.contains('PlatformException') && _isPluginRelated(line)) {
        final issue = _parsePlatformException(line, lines, i);
        if (issue != null && !excludePlugins.contains(issue.pluginName)) {
          issues.add(issue);
        }
      }
      
      // Look for method channel errors
      if (line.contains('No implementation found for method')) {
        final issue = _parseMethodChannelError(line, lines, i);
        if (issue != null && !excludePlugins.contains(issue.pluginName)) {
          issues.add(issue);
        }
      }
    }
    
    return issues;
  }

  /// Parses MissingPluginException from log line
  PluginIssue? _parseMissingPluginException(
    String line,
    List<String> lines,
    int lineIndex,
  ) {
    // Extract plugin name and method from the exception
    final pluginMatch = RegExp(r'No implementation found for method (\w+) on channel (\S+)')
        .firstMatch(line);
    
    if (pluginMatch != null) {
      final method = pluginMatch.group(1) ?? 'unknown';
      final channel = pluginMatch.group(2) ?? 'unknown';
      final pluginName = _extractPluginNameFromChannel(channel);
      
      // Get stack trace from following lines
      final stackTraceLines = <String>[];
      for (int i = lineIndex + 1; i < lines.length && i < lineIndex + 20; i++) {
        if (lines[i].trim().startsWith('at ') || lines[i].trim().startsWith('#')) {
          stackTraceLines.add(lines[i]);
        } else if (stackTraceLines.isNotEmpty) {
          break;
        }
      }
      
      return PluginIssue(
        pluginName: pluginName,
        issueType: IssueType.missingRegistration,
        severity: IssueSeverity.critical,
        description: 'MissingPluginException: No implementation found for method $method on channel $channel',
        affectedPlatforms: _detectPlatformFromLog(line),
        stackTrace: stackTraceLines.isNotEmpty 
            ? StackTrace.fromString(stackTraceLines.join('\n'))
            : null,
        detectedAt: DateTime.now(),
        additionalContext: {
          'method': method,
          'channel': channel,
          'logLine': line,
        },
      );
    }
    
    return null;
  }

  /// Parses PlatformException from log line
  PluginIssue? _parsePlatformException(
    String line,
    List<String> lines,
    int lineIndex,
  ) {
    // Extract plugin information from platform exception
    final pluginName = _extractPluginNameFromLine(line);
    
    if (pluginName.isNotEmpty) {
      return PluginIssue(
        pluginName: pluginName,
        issueType: IssueType.initializationFailure,
        severity: IssueSeverity.high,
        description: 'PlatformException occurred in plugin $pluginName',
        affectedPlatforms: _detectPlatformFromLog(line),
        detectedAt: DateTime.now(),
        additionalContext: {
          'logLine': line,
        },
      );
    }
    
    return null;
  }

  /// Parses method channel error from log line
  PluginIssue? _parseMethodChannelError(
    String line,
    List<String> lines,
    int lineIndex,
  ) {
    final methodMatch = RegExp(r'No implementation found for method (\w+)')
        .firstMatch(line);
    
    if (methodMatch != null) {
      final method = methodMatch.group(1) ?? 'unknown';
      final pluginName = _extractPluginNameFromLine(line);
      
      return PluginIssue(
        pluginName: pluginName.isNotEmpty ? pluginName : 'unknown_plugin',
        issueType: IssueType.methodChannelNotFound,
        severity: IssueSeverity.high,
        description: 'No implementation found for method $method',
        affectedPlatforms: _detectPlatformFromLog(line),
        detectedAt: DateTime.now(),
        additionalContext: {
          'method': method,
          'logLine': line,
        },
      );
    }
    
    return null;
  }

  /// Starts monitoring method channel calls
  void _startMethodChannelMonitoring() {
    // This would require hooking into Flutter's method channel system
    // For now, we'll simulate this with a timer that checks for issues
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForMethodChannelIssues();
    });
  }

  /// Starts monitoring exceptions
  void _startExceptionMonitoring() {
    // Monitor uncaught exceptions
    developer.log('Starting exception monitoring for plugin issues');
    
    // This would typically involve setting up error handlers
    // that can capture and analyze exceptions in real-time
  }

  /// Checks for method channel issues
  void _checkForMethodChannelIssues() {
    // This would involve checking the current state of method channels
    // and detecting any that are failing or missing implementations
  }

  /// Extracts plugin name from method channel name
  String _extractPluginNameFromChannel(String channel) {
    // Common patterns for plugin channels
    if (channel.contains('/')) {
      final parts = channel.split('/');
      return parts.first;
    }
    
    if (channel.contains('.')) {
      final parts = channel.split('.');
      return parts.last;
    }
    
    return channel;
  }

  /// Extracts plugin name from log line
  String _extractPluginNameFromLine(String line) {
    // Look for common plugin name patterns in log lines
    final patterns = [
      RegExp(r'(\w+)Plugin'),
      RegExp(r'plugin\.(\w+)'),
      RegExp(r'(\w+)_plugin'),
      RegExp(r'com\.(\w+)\.(\w+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1) ?? match.group(2) ?? '';
      }
    }
    
    return '';
  }

  /// Detects platform from log line
  List<String> _detectPlatformFromLog(String line) {
    final platforms = <String>[];
    
    if (line.contains('android') || line.contains('Android')) {
      platforms.add('android');
    }
    if (line.contains('ios') || line.contains('iOS')) {
      platforms.add('ios');
    }
    if (line.contains('web') || line.contains('Web')) {
      platforms.add('web');
    }
    if (line.contains('windows') || line.contains('Windows')) {
      platforms.add('windows');
    }
    if (line.contains('macos') || line.contains('macOS')) {
      platforms.add('macos');
    }
    if (line.contains('linux') || line.contains('Linux')) {
      platforms.add('linux');
    }
    
    return platforms.isEmpty ? ['unknown'] : platforms;
  }

  /// Checks if a log line is plugin-related
  bool _isPluginRelated(String line) {
    final pluginIndicators = [
      'plugin',
      'Plugin',
      'channel',
      'method',
      'implementation',
      'registrant',
    ];
    
    return pluginIndicators.any((indicator) => line.contains(indicator));
  }

  /// Adds an issue to the detected issues list
  void _addIssue(PluginIssue issue) {
    _detectedIssues.add(issue);
    
    // Keep only the most recent issues
    if (_detectedIssues.length > maxIssueHistory) {
      _detectedIssues.removeAt(0);
    }
    
    _issueController.add(issue);
  }
}
