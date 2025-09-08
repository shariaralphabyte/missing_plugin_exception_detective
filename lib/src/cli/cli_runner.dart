import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';

import '../core/detective.dart';
import '../core/diagnostic_result.dart';
import '../core/plugin_issue.dart';
import '../resolvers/resolution_guide.dart';

/// Command-line interface for the Missing Plugin Exception Detective
class CliRunner {
  /// Creates a new CLI runner
  CliRunner({
    MissingPluginExceptionDetective? detective,
    ResolutionGuide? resolutionGuide,
  })  : _detective = detective ?? MissingPluginExceptionDetective(),
        _resolutionGuide = resolutionGuide ?? const ResolutionGuide();

  final MissingPluginExceptionDetective _detective;
  final ResolutionGuide _resolutionGuide;

  /// Runs the CLI with the given arguments
  Future<int> run(List<String> arguments) async {
    final parser = _createArgParser();
    
    try {
      final results = parser.parse(arguments);
      
      if (results['help'] as bool) {
        _printUsage(parser);
        return 0;
      }
      
      if (results['version'] as bool) {
        _printVersion();
        return 0;
      }
      
      final command = results.command?.name ?? 'check';
      
      switch (command) {
        case 'check':
          return await _runCheckCommand(results.command!);
        case 'monitor':
          return await _runMonitorCommand(results.command!);
        case 'doctor':
          return await _runDoctorCommand(results.command!);
        default:
          stderr.writeln('Unknown command: $command');
          _printUsage(parser);
          return 1;
      }
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      _printUsage(parser);
      return 1;
    } catch (e) {
      stderr.writeln('Unexpected error: $e');
      return 1;
    }
  }

  /// Creates the argument parser
  ArgParser _createArgParser() {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show usage information',
        negatable: false,
      )
      ..addFlag(
        'version',
        abbr: 'v',
        help: 'Show version information',
        negatable: false,
      );

    // Check command
    parser.addCommand('check')
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to Flutter project (defaults to current directory)',
        defaultsTo: '.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output format',
        allowed: ['console', 'json', 'markdown'],
        defaultsTo: 'console',
      )
      ..addFlag(
        'verbose',
        help: 'Enable verbose output',
        negatable: false,
      )
      ..addFlag(
        'fix',
        help: 'Show resolution guides for detected issues',
        defaultsTo: true,
      )
      ..addMultiOption(
        'platforms',
        help: 'Platforms to check (comma-separated)',
        defaultsTo: ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
      )
      ..addMultiOption(
        'exclude',
        help: 'Plugins to exclude from analysis',
        defaultsTo: [],
      )
      ..addFlag(
        'performance',
        help: 'Enable performance mode (faster but less thorough)',
        negatable: false,
      );

    // Monitor command
    parser.addCommand('monitor')
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to Flutter project (defaults to current directory)',
        defaultsTo: '.',
      )
      ..addOption(
        'duration',
        abbr: 'd',
        help: 'Monitoring duration in seconds (0 for indefinite)',
        defaultsTo: '0',
      )
      ..addFlag(
        'verbose',
        help: 'Enable verbose output',
        negatable: false,
      );

    // Doctor command
    parser.addCommand('doctor')
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to Flutter project (defaults to current directory)',
        defaultsTo: '.',
      )
      ..addFlag(
        'verbose',
        help: 'Enable verbose output',
        negatable: false,
      );

    return parser;
  }

  /// Runs the check command
  Future<int> _runCheckCommand(ArgResults results) async {
    final projectPath = results['path'] as String;
    final outputFormat = results['output'] as String;
    final verbose = results['verbose'] as bool;
    final showFix = results['fix'] as bool;
    final platforms = results['platforms'] as List<String>;
    final excludePlugins = results['exclude'] as List<String>;
    final performanceMode = results['performance'] as bool;

    if (verbose) {
      stdout.writeln('🔍 Starting plugin diagnostic scan...');
      stdout.writeln('Project path: $projectPath');
      stdout.writeln('Platforms: ${platforms.join(', ')}');
      if (excludePlugins.isNotEmpty) {
        stdout.writeln('Excluded plugins: ${excludePlugins.join(', ')}');
      }
    }

    try {
      // Configure detective
      final config = DetectiveConfig(
        includePlatforms: platforms,
        excludePlugins: excludePlugins,
        performanceMode: performanceMode,
        verboseLogging: verbose,
      );
      
      final detective = MissingPluginExceptionDetective(config: config);
      
      // Run diagnostic
      final result = await detective.diagnose(
        projectPath: projectPath,
        includeResolutions: showFix,
      );

      // Output results
      switch (outputFormat) {
        case 'json':
          await _outputJson(result, showFix);
          break;
        case 'markdown':
          await _outputMarkdown(result, showFix);
          break;
        default:
          await _outputConsole(result, showFix, verbose);
      }

      // Return appropriate exit code
      return result.status == DiagnosticStatus.healthy ? 0 : 1;
      
    } catch (e) {
      stderr.writeln('❌ Diagnostic scan failed: $e');
      return 1;
    }
  }

  /// Runs the monitor command
  Future<int> _runMonitorCommand(ArgResults results) async {
    final projectPath = results['path'] as String;
    final durationStr = results['duration'] as String;
    final verbose = results['verbose'] as bool;

    final duration = int.tryParse(durationStr) ?? 0;

    stdout.writeln('🔍 Starting runtime monitoring...');
    stdout.writeln('Project path: $projectPath');
    if (duration > 0) {
      stdout.writeln('Duration: ${duration}s');
    } else {
      stdout.writeln('Duration: Indefinite (press Ctrl+C to stop)');
    }

    try {
      final detective = MissingPluginExceptionDetective();
      final monitorStream = detective.monitorRuntime();

      final subscription = monitorStream.listen(
        (issue) {
          _printIssue(issue, verbose);
        },
        onError: (error) {
          stderr.writeln('❌ Monitoring error: $error');
        },
      );

      if (duration > 0) {
        await Future.delayed(Duration(seconds: duration));
        await subscription.cancel();
        stdout.writeln('✅ Monitoring completed');
      } else {
        // Monitor indefinitely
        await subscription.asFuture();
      }

      return 0;
    } catch (e) {
      stderr.writeln('❌ Monitoring failed: $e');
      return 1;
    }
  }

  /// Runs the doctor command
  Future<int> _runDoctorCommand(ArgResults results) async {
    final projectPath = results['path'] as String;
    final verbose = results['verbose'] as bool;

    stdout.writeln('🏥 Running Flutter Plugin Doctor...');
    stdout.writeln('Project path: $projectPath');

    try {
      // Check Flutter installation
      final flutterCheck = await _checkFlutterInstallation();
      _printDoctorCheck('Flutter Installation', flutterCheck.success, flutterCheck.message);

      // Check project structure
      final projectCheck = await _checkProjectStructure(projectPath);
      _printDoctorCheck('Project Structure', projectCheck.success, projectCheck.message);

      // Check dependencies
      final depsCheck = await _checkDependencies(projectPath);
      _printDoctorCheck('Dependencies', depsCheck.success, depsCheck.message);

      // Run quick diagnostic
      final detective = MissingPluginExceptionDetective();
      final result = await detective.diagnose(projectPath: projectPath);
      
      final hasIssues = result.issues.isNotEmpty;
      _printDoctorCheck(
        'Plugin Configuration',
        !hasIssues,
        hasIssues ? '${result.issues.length} issues found' : 'All plugins properly configured',
      );

      if (verbose && hasIssues) {
        stdout.writeln('\n📋 Issues Summary:');
        for (final issue in result.issues) {
          stdout.writeln('  • ${issue.pluginName}: ${issue.description}');
        }
      }

      final allHealthy = flutterCheck.success && 
                       projectCheck.success && 
                       depsCheck.success && 
                       !hasIssues;

      stdout.writeln('\n${allHealthy ? '✅' : '❌'} Overall Status: ${allHealthy ? 'Healthy' : 'Issues Found'}');

      return allHealthy ? 0 : 1;
    } catch (e) {
      stderr.writeln('❌ Doctor check failed: $e');
      return 1;
    }
  }

  /// Outputs results in console format
  Future<void> _outputConsole(
    DiagnosticResult result,
    bool showFix,
    bool verbose,
  ) async {
    // Header
    stdout.writeln('🔍 Flutter Plugin Diagnostic Results');
    stdout.writeln('=' * 50);
    
    // Summary
    stdout.writeln('📊 Summary:');
    stdout.writeln('  Status: ${_getStatusEmoji(result.status)} ${result.status.name.toUpperCase()}');
    stdout.writeln('  Scanned plugins: ${result.scannedPlugins.length}');
    stdout.writeln('  Issues found: ${result.issues.length}');
    stdout.writeln('  Scan duration: ${result.scanDuration.inMilliseconds}ms');
    
    if (verbose) {
      stdout.writeln('  Project path: ${result.projectPath}');
      stdout.writeln('  Flutter version: ${result.flutterVersion ?? 'Unknown'}');
      stdout.writeln('  Dart version: ${result.dartVersion ?? 'Unknown'}');
    }
    
    stdout.writeln();

    if (result.issues.isEmpty) {
      stdout.writeln('✅ All plugins are properly configured!');
      return;
    }

    // Issues by severity
    final issuesBySeverity = result.issuesBySeverity;
    
    for (final severity in IssueSeverity.values) {
      final issues = issuesBySeverity[severity] ?? [];
      if (issues.isEmpty) continue;
      
      stdout.writeln('${_getSeverityEmoji(severity)} ${severity.name.toUpperCase()} ISSUES (${issues.length}):');
      
      for (final issue in issues) {
        stdout.writeln('  • ${issue.pluginName}');
        stdout.writeln('    ${issue.description}');
        if (issue.affectedPlatforms.isNotEmpty) {
          stdout.writeln('    Platforms: ${issue.affectedPlatforms.join(', ')}');
        }
        
        if (showFix) {
          final guide = await _resolutionGuide.generateGuide(issue);
          if (guide.isNotEmpty) {
            stdout.writeln('    💡 Resolution:');
            for (int i = 0; i < guide.length; i++) {
              final step = guide[i];
              stdout.writeln('       ${i + 1}. ${step.title}');
              if (step.command != null) {
                stdout.writeln('          Run: ${step.command}');
              }
            }
          }
        }
        stdout.writeln();
      }
    }

    // Footer
    if (showFix) {
      stdout.writeln('💡 Run with --no-fix to hide resolution guides');
    } else {
      stdout.writeln('💡 Run with --fix to show resolution guides');
    }
  }

  /// Outputs results in JSON format
  Future<void> _outputJson(DiagnosticResult result, bool showFix) async {
    final json = result.toJson();
    
    if (showFix) {
      final issuesWithGuides = <Map<String, dynamic>>[];
      
      for (final issue in result.issues) {
        final issueJson = issue.toJson();
        final guide = await _resolutionGuide.generateGuide(issue);
        issueJson['resolutionGuide'] = guide.map((step) => step.toJson()).toList();
        issuesWithGuides.add(issueJson);
      }
      
      json['issues'] = issuesWithGuides;
    }
    
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(json));
  }

  /// Outputs results in Markdown format
  Future<void> _outputMarkdown(DiagnosticResult result, bool showFix) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# Flutter Plugin Diagnostic Report');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Status | ${result.status.name.toUpperCase()} |');
    buffer.writeln('| Scanned Plugins | ${result.scannedPlugins.length} |');
    buffer.writeln('| Issues Found | ${result.issues.length} |');
    buffer.writeln('| Scan Duration | ${result.scanDuration.inMilliseconds}ms |');
    buffer.writeln();

    if (result.issues.isEmpty) {
      buffer.writeln('✅ **All plugins are properly configured!**');
      stdout.write(buffer.toString());
      return;
    }

    // Issues by severity
    final issuesBySeverity = result.issuesBySeverity;
    
    for (final severity in IssueSeverity.values) {
      final issues = issuesBySeverity[severity] ?? [];
      if (issues.isEmpty) continue;
      
      buffer.writeln('## ${severity.name.toUpperCase()} Issues (${issues.length})');
      buffer.writeln();
      
      for (final issue in issues) {
        buffer.writeln('### ${issue.pluginName}');
        buffer.writeln();
        buffer.writeln('**Description:** ${issue.description}');
        buffer.writeln();
        if (issue.affectedPlatforms.isNotEmpty) {
          buffer.writeln('**Affected Platforms:** ${issue.affectedPlatforms.join(', ')}');
          buffer.writeln();
        }
        
        if (showFix) {
          final guide = await _resolutionGuide.generateGuide(issue);
          if (guide.isNotEmpty) {
            buffer.writeln('**Resolution Steps:**');
            buffer.writeln();
            for (int i = 0; i < guide.length; i++) {
              final step = guide[i];
              buffer.writeln('${i + 1}. **${step.title}**');
              buffer.writeln('   ${step.description}');
              if (step.command != null) {
                buffer.writeln('   ```bash');
                buffer.writeln('   ${step.command}');
                buffer.writeln('   ```');
              }
              buffer.writeln();
            }
          }
        }
      }
    }
    
    stdout.write(buffer.toString());
  }

  /// Prints a single issue to console
  void _printIssue(PluginIssue issue, bool verbose) {
    final timestamp = DateTime.now().toIso8601String();
    stdout.writeln('[$timestamp] ${_getSeverityEmoji(issue.severity)} ${issue.pluginName}');
    stdout.writeln('  ${issue.description}');
    if (verbose && issue.affectedPlatforms.isNotEmpty) {
      stdout.writeln('  Platforms: ${issue.affectedPlatforms.join(', ')}');
    }
    stdout.writeln();
  }

  /// Prints a doctor check result
  void _printDoctorCheck(String name, bool success, String message) {
    final emoji = success ? '✅' : '❌';
    stdout.writeln('$emoji $name: $message');
  }

  /// Checks Flutter installation
  Future<DoctorCheckResult> _checkFlutterInstallation() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        return DoctorCheckResult(true, 'Flutter is installed and accessible');
      } else {
        return DoctorCheckResult(false, 'Flutter command failed');
      }
    } catch (e) {
      return DoctorCheckResult(false, 'Flutter not found in PATH');
    }
  }

  /// Checks project structure
  Future<DoctorCheckResult> _checkProjectStructure(String projectPath) async {
    final pubspecFile = File('$projectPath/pubspec.yaml');
    
    if (!await pubspecFile.exists()) {
      return DoctorCheckResult(false, 'pubspec.yaml not found');
    }
    
    try {
      final content = await pubspecFile.readAsString();
      if (!content.contains('flutter:')) {
        return DoctorCheckResult(false, 'Not a Flutter project');
      }
      
      return DoctorCheckResult(true, 'Valid Flutter project structure');
    } catch (e) {
      return DoctorCheckResult(false, 'Cannot read pubspec.yaml');
    }
  }

  /// Checks dependencies
  Future<DoctorCheckResult> _checkDependencies(String projectPath) async {
    final lockFile = File('$projectPath/pubspec.lock');
    
    if (!await lockFile.exists()) {
      return DoctorCheckResult(false, 'pubspec.lock missing - run "flutter pub get"');
    }
    
    return DoctorCheckResult(true, 'Dependencies resolved');
  }

  /// Gets emoji for diagnostic status
  String _getStatusEmoji(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.healthy:
        return '✅';
      case DiagnosticStatus.warning:
        return '⚠️';
      case DiagnosticStatus.error:
        return '❌';
      case DiagnosticStatus.failed:
        return '💥';
    }
  }

  /// Gets emoji for issue severity
  String _getSeverityEmoji(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return '🚨';
      case IssueSeverity.high:
        return '❌';
      case IssueSeverity.medium:
        return '⚠️';
      case IssueSeverity.low:
        return '💡';
    }
  }

  /// Prints usage information
  void _printUsage(ArgParser parser) {
    stdout.writeln('Missing Plugin Exception Detective');
    stdout.writeln('A developer productivity tool for Flutter plugin issues');
    stdout.writeln();
    stdout.writeln('Usage: flutter pub run missing_plugin_exception_detective:check [options]');
    stdout.writeln();
    stdout.writeln('Available commands:');
    stdout.writeln('  check    Analyze project for plugin issues (default)');
    stdout.writeln('  monitor  Monitor runtime for plugin issues');
    stdout.writeln('  doctor   Check overall project health');
    stdout.writeln();
    stdout.writeln(parser.usage);
    stdout.writeln();
    stdout.writeln('Examples:');
    stdout.writeln('  flutter pub run missing_plugin_exception_detective:check');
    stdout.writeln('  flutter pub run missing_plugin_exception_detective:check --path=/path/to/project');
    stdout.writeln('  flutter pub run missing_plugin_exception_detective:check --output=json');
    stdout.writeln('  flutter pub run missing_plugin_exception_detective:monitor --duration=60');
    stdout.writeln('  flutter pub run missing_plugin_exception_detective:doctor');
  }

  /// Prints version information
  void _printVersion() {
    stdout.writeln('Missing Plugin Exception Detective v0.1.0');
    stdout.writeln('A developer productivity tool for Flutter plugin issues');
  }
}

/// Result of a doctor check
@immutable
class DoctorCheckResult {
  /// Creates a new doctor check result
  const DoctorCheckResult(this.success, this.message);

  /// Whether the check was successful
  final bool success;

  /// Message describing the result
  final String message;
}
