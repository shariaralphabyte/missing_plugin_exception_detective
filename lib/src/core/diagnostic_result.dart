import 'package:meta/meta.dart';

import 'plugin_issue.dart';

/// Represents the overall status of a diagnostic scan
enum DiagnosticStatus {
  /// No issues found - all plugins are properly configured
  healthy,
  
  /// Minor issues found that don't affect functionality
  warning,
  
  /// Critical issues found that may cause runtime errors
  error,
  
  /// Diagnostic scan failed to complete
  failed,
}

/// Contains the results of a plugin diagnostic scan
@immutable
class DiagnosticResult {
  /// Creates a new diagnostic result
  const DiagnosticResult({
    required this.status,
    required this.issues,
    required this.scannedPlugins,
    required this.scanDuration,
    this.scanTimestamp,
    this.projectPath,
    this.flutterVersion,
    this.dartVersion,
    this.additionalMetadata = const <String, dynamic>{},
  });

  /// The overall status of the diagnostic scan
  final DiagnosticStatus status;

  /// List of issues found during the scan
  final List<PluginIssue> issues;

  /// List of plugins that were scanned
  final List<String> scannedPlugins;

  /// Duration of the diagnostic scan
  final Duration scanDuration;

  /// Timestamp when the scan was performed
  final DateTime? scanTimestamp;

  /// Path to the Flutter project that was scanned
  final String? projectPath;

  /// Flutter version used in the project
  final String? flutterVersion;

  /// Dart version used in the project
  final String? dartVersion;

  /// Additional metadata about the scan
  final Map<String, dynamic> additionalMetadata;

  /// Returns true if the diagnostic found any issues
  bool get hasIssues => issues.isNotEmpty;

  /// Returns true if the diagnostic found critical issues
  bool get hasCriticalIssues => issues.any(
        (issue) => issue.severity == IssueSeverity.critical,
      );

  /// Returns issues grouped by severity
  Map<IssueSeverity, List<PluginIssue>> get issuesBySeverity {
    final Map<IssueSeverity, List<PluginIssue>> grouped = {};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.severity, () => []).add(issue);
    }
    return grouped;
  }

  /// Returns issues grouped by plugin name
  Map<String, List<PluginIssue>> get issuesByPlugin {
    final Map<String, List<PluginIssue>> grouped = {};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.pluginName, () => []).add(issue);
    }
    return grouped;
  }

  /// Returns issues grouped by type
  Map<IssueType, List<PluginIssue>> get issuesByType {
    final Map<IssueType, List<PluginIssue>> grouped = {};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.issueType, () => []).add(issue);
    }
    return grouped;
  }

  /// Returns a summary of the diagnostic results
  String get summary {
    if (issues.isEmpty) {
      return 'All ${scannedPlugins.length} plugins are properly configured.';
    }

    final criticalCount = issues
        .where((issue) => issue.severity == IssueSeverity.critical)
        .length;
    final highCount = issues
        .where((issue) => issue.severity == IssueSeverity.high)
        .length;
    final mediumCount = issues
        .where((issue) => issue.severity == IssueSeverity.medium)
        .length;
    final lowCount = issues
        .where((issue) => issue.severity == IssueSeverity.low)
        .length;

    final parts = <String>[];
    if (criticalCount > 0) parts.add('$criticalCount critical');
    if (highCount > 0) parts.add('$highCount high');
    if (mediumCount > 0) parts.add('$mediumCount medium');
    if (lowCount > 0) parts.add('$lowCount low');

    return 'Found ${issues.length} issues: ${parts.join(', ')} priority.';
  }

  /// Creates a copy of this result with updated fields
  DiagnosticResult copyWith({
    DiagnosticStatus? status,
    List<PluginIssue>? issues,
    List<String>? scannedPlugins,
    Duration? scanDuration,
    DateTime? scanTimestamp,
    String? projectPath,
    String? flutterVersion,
    String? dartVersion,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return DiagnosticResult(
      status: status ?? this.status,
      issues: issues ?? this.issues,
      scannedPlugins: scannedPlugins ?? this.scannedPlugins,
      scanDuration: scanDuration ?? this.scanDuration,
      scanTimestamp: scanTimestamp ?? this.scanTimestamp,
      projectPath: projectPath ?? this.projectPath,
      flutterVersion: flutterVersion ?? this.flutterVersion,
      dartVersion: dartVersion ?? this.dartVersion,
      additionalMetadata: additionalMetadata ?? this.additionalMetadata,
    );
  }

  /// Converts this result to a JSON representation
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'issues': issues.map((issue) => issue.toJson()).toList(),
      'scannedPlugins': scannedPlugins,
      'scanDuration': scanDuration.inMilliseconds,
      'scanTimestamp': scanTimestamp?.toIso8601String(),
      'projectPath': projectPath,
      'flutterVersion': flutterVersion,
      'dartVersion': dartVersion,
      'additionalMetadata': additionalMetadata,
      'summary': summary,
    };
  }

  /// Creates a DiagnosticResult from a JSON representation
  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      status: DiagnosticStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      issues: (json['issues'] as List)
          .map((issueJson) => PluginIssue.fromJson(issueJson as Map<String, dynamic>))
          .toList(),
      scannedPlugins: List<String>.from(json['scannedPlugins'] as List),
      scanDuration: Duration(milliseconds: json['scanDuration'] as int),
      scanTimestamp: json['scanTimestamp'] != null
          ? DateTime.parse(json['scanTimestamp'] as String)
          : null,
      projectPath: json['projectPath'] as String?,
      flutterVersion: json['flutterVersion'] as String?,
      dartVersion: json['dartVersion'] as String?,
      additionalMetadata: Map<String, dynamic>.from(
        json['additionalMetadata'] as Map? ?? <String, dynamic>{},
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiagnosticResult &&
        other.status == status &&
        other.issues.length == issues.length &&
        other.scannedPlugins.length == scannedPlugins.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      issues.length,
      scannedPlugins.length,
      scanDuration,
    );
  }

  @override
  String toString() {
    return 'DiagnosticResult('
        'status: $status, '
        'issues: ${issues.length}, '
        'scannedPlugins: ${scannedPlugins.length}, '
        'scanDuration: ${scanDuration.inMilliseconds}ms'
        ')';
  }
}
