import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../analyzers/runtime_detector.dart';
import '../analyzers/static_analyzer.dart';
import '../resolvers/resolution_guide.dart';
import 'diagnostic_result.dart';
import 'plugin_issue.dart';

/// Configuration options for the detective
@immutable
class DetectiveConfig {
  /// Creates a new detective configuration
  const DetectiveConfig({
    this.enableRuntimeDetection = true,
    this.enableStaticAnalysis = true,
    this.enableResolutionGuides = true,
    this.performanceMode = false,
    this.maxScanDuration = const Duration(seconds: 30),
    this.includePlatforms = const ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
    this.excludePlugins = const <String>[],
    this.verboseLogging = false,
  });

  /// Whether to enable runtime detection of plugin issues
  final bool enableRuntimeDetection;

  /// Whether to enable static analysis of project files
  final bool enableStaticAnalysis;

  /// Whether to generate resolution guides for detected issues
  final bool enableResolutionGuides;

  /// Whether to prioritize performance over thoroughness
  final bool performanceMode;

  /// Maximum duration allowed for a diagnostic scan
  final Duration maxScanDuration;

  /// List of platforms to include in the analysis
  final List<String> includePlatforms;

  /// List of plugins to exclude from analysis
  final List<String> excludePlugins;

  /// Whether to enable verbose logging during analysis
  final bool verboseLogging;
}

/// Main detective class that orchestrates plugin issue detection and analysis
class MissingPluginExceptionDetective {
  /// Creates a new detective instance
  MissingPluginExceptionDetective({
    DetectiveConfig? config,
    StaticAnalyzer? staticAnalyzer,
    RuntimeDetector? runtimeDetector,
    ResolutionGuide? resolutionGuide,
  })  : _config = config ?? const DetectiveConfig(),
        _staticAnalyzer = staticAnalyzer ?? StaticAnalyzer(),
        _runtimeDetector = runtimeDetector ?? RuntimeDetector(),
        _resolutionGuide = resolutionGuide ?? ResolutionGuide();

  final DetectiveConfig _config;
  final StaticAnalyzer _staticAnalyzer;
  final RuntimeDetector _runtimeDetector;
  final ResolutionGuide _resolutionGuide;

  /// Performs a comprehensive diagnostic scan of the Flutter project
  Future<DiagnosticResult> diagnose({
    String? projectPath,
    bool includeResolutions = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final scanTimestamp = DateTime.now();
    
    try {
      // Determine project path
      final targetPath = projectPath ?? Directory.current.path;
      
      // Validate that this is a Flutter project
      await _validateFlutterProject(targetPath);
      
      // Collect project metadata
      final metadata = await _collectProjectMetadata(targetPath);
      
      // Run static analysis
      final staticIssues = _config.enableStaticAnalysis
          ? await _runStaticAnalysis(targetPath)
          : <PluginIssue>[];
      
      // Run runtime detection if enabled
      final runtimeIssues = _config.enableRuntimeDetection
          ? await _runRuntimeDetection(targetPath)
          : <PluginIssue>[];
      
      // Combine and deduplicate issues
      final allIssues = _deduplicateIssues([...staticIssues, ...runtimeIssues]);
      
      // Generate resolution guides if requested
      if (includeResolutions && _config.enableResolutionGuides) {
        await _generateResolutionGuides(allIssues);
      }
      
      // Determine overall status
      final status = _determineStatus(allIssues);
      
      stopwatch.stop();
      
      return DiagnosticResult(
        status: status,
        issues: allIssues,
        scannedPlugins: metadata['scannedPlugins'] as List<String>,
        scanDuration: stopwatch.elapsed,
        scanTimestamp: scanTimestamp,
        projectPath: targetPath,
        flutterVersion: metadata['flutterVersion'] as String?,
        dartVersion: metadata['dartVersion'] as String?,
        additionalMetadata: metadata,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      
      // Return a failed diagnostic result
      return DiagnosticResult(
        status: DiagnosticStatus.failed,
        issues: [
          PluginIssue(
            pluginName: 'diagnostic_scan',
            issueType: IssueType.initializationFailure,
            severity: IssueSeverity.critical,
            description: 'Diagnostic scan failed: ${e.toString()}',
            affectedPlatforms: _config.includePlatforms,
            stackTrace: stackTrace,
            detectedAt: scanTimestamp,
            additionalContext: {'error': e.toString()},
          ),
        ],
        scannedPlugins: const [],
        scanDuration: stopwatch.elapsed,
        scanTimestamp: scanTimestamp,
        projectPath: projectPath,
      );
    }
  }

  /// Monitors the application for runtime plugin issues
  Stream<PluginIssue> monitorRuntime() {
    if (!_config.enableRuntimeDetection) {
      return const Stream.empty();
    }
    
    return _runtimeDetector.monitor();
  }

  /// Validates that the target directory contains a Flutter project
  Future<void> _validateFlutterProject(String projectPath) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    
    if (!await pubspecFile.exists()) {
      throw ArgumentError(
        'No pubspec.yaml found at $projectPath. '
        'Please ensure you are running this from a Flutter project directory.',
      );
    }
    
    final pubspecContent = await pubspecFile.readAsString();
    if (!pubspecContent.contains('flutter:')) {
      throw ArgumentError(
        'The pubspec.yaml at $projectPath does not appear to be a Flutter project.',
      );
    }
  }

  /// Collects metadata about the Flutter project
  Future<Map<String, dynamic>> _collectProjectMetadata(String projectPath) async {
    final metadata = <String, dynamic>{
      'projectPath': projectPath,
      'scannedPlugins': <String>[],
    };
    
    try {
      // Get Flutter version
      final flutterVersionResult = await Process.run(
        'flutter',
        ['--version', '--machine'],
        workingDirectory: projectPath,
      );
      
      if (flutterVersionResult.exitCode == 0) {
        // Parse version info if available
        metadata['flutterVersion'] = 'Available';
      }
    } catch (e) {
      // Flutter CLI not available
      metadata['flutterVersion'] = 'Unknown';
    }
    
    try {
      // Get Dart version
      final dartVersionResult = await Process.run('dart', ['--version']);
      if (dartVersionResult.exitCode == 0) {
        metadata['dartVersion'] = 'Available';
      }
    } catch (e) {
      metadata['dartVersion'] = 'Unknown';
    }
    
    return metadata;
  }

  /// Runs static analysis on the project
  Future<List<PluginIssue>> _runStaticAnalysis(String projectPath) async {
    try {
      return await _staticAnalyzer.analyze(
        projectPath: projectPath,
        includePlatforms: _config.includePlatforms,
        excludePlugins: _config.excludePlugins,
      );
    } catch (e) {
      return [
        PluginIssue(
          pluginName: 'static_analyzer',
          issueType: IssueType.initializationFailure,
          severity: IssueSeverity.high,
          description: 'Static analysis failed: ${e.toString()}',
          affectedPlatforms: _config.includePlatforms,
          detectedAt: DateTime.now(),
          additionalContext: {'error': e.toString()},
        ),
      ];
    }
  }

  /// Runs runtime detection
  Future<List<PluginIssue>> _runRuntimeDetection(String projectPath) async {
    try {
      return await _runtimeDetector.detect(
        projectPath: projectPath,
        includePlatforms: _config.includePlatforms,
        excludePlugins: _config.excludePlugins,
      );
    } catch (e) {
      return [
        PluginIssue(
          pluginName: 'runtime_detector',
          issueType: IssueType.initializationFailure,
          severity: IssueSeverity.medium,
          description: 'Runtime detection failed: ${e.toString()}',
          affectedPlatforms: _config.includePlatforms,
          detectedAt: DateTime.now(),
          additionalContext: {'error': e.toString()},
        ),
      ];
    }
  }

  /// Generates resolution guides for detected issues
  Future<void> _generateResolutionGuides(List<PluginIssue> issues) async {
    for (final issue in issues) {
      try {
        await _resolutionGuide.generateGuide(issue);
      } catch (e) {
        // Log error but don't fail the entire diagnostic
        if (_config.verboseLogging) {
          print('Failed to generate resolution guide for ${issue.pluginName}: $e');
        }
      }
    }
  }

  /// Removes duplicate issues from the list
  List<PluginIssue> _deduplicateIssues(List<PluginIssue> issues) {
    final seen = <String>{};
    final deduplicated = <PluginIssue>[];
    
    for (final issue in issues) {
      final key = '${issue.pluginName}_${issue.issueType}_${issue.description}';
      if (!seen.contains(key)) {
        seen.add(key);
        deduplicated.add(issue);
      }
    }
    
    return deduplicated;
  }

  /// Determines the overall diagnostic status based on issues found
  DiagnosticStatus _determineStatus(List<PluginIssue> issues) {
    if (issues.isEmpty) {
      return DiagnosticStatus.healthy;
    }
    
    final hasCritical = issues.any(
      (issue) => issue.severity == IssueSeverity.critical,
    );
    
    if (hasCritical) {
      return DiagnosticStatus.error;
    }
    
    final hasHigh = issues.any(
      (issue) => issue.severity == IssueSeverity.high,
    );
    
    if (hasHigh) {
      return DiagnosticStatus.error;
    }
    
    return DiagnosticStatus.warning;
  }
}
