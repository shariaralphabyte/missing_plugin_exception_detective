import 'package:meta/meta.dart';

import '../resolvers/resolution_guide.dart';

/// Represents the severity level of a plugin issue
enum IssueSeverity {
  /// Critical issues that prevent app functionality
  critical,
  
  /// High priority issues that may cause runtime errors
  high,
  
  /// Medium priority issues that may cause warnings
  medium,
  
  /// Low priority issues for optimization
  low,
}

/// Represents the type of plugin issue detected
enum IssueType {
  /// Plugin is declared in pubspec.yaml but not registered
  missingRegistration,
  
  /// Plugin is registered but not declared in pubspec.yaml
  missingDeclaration,
  
  /// Plugin version mismatch between platforms
  versionMismatch,
  
  /// Platform-specific configuration missing
  platformConfigMissing,
  
  /// Plugin initialization failure
  initializationFailure,
  
  /// Plugin method channel not found
  methodChannelNotFound,
  
  /// Plugin dependencies missing
  dependenciesMissing,
  
  /// Plugin build configuration issues
  buildConfigIssue,
}

/// Represents a specific plugin issue detected by the detective
@immutable
class PluginIssue {
  /// Creates a new plugin issue
  const PluginIssue({
    required this.pluginName,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.affectedPlatforms,
    this.stackTrace,
    this.detectedAt,
    this.additionalContext = const <String, dynamic>{},
    this.resolutionSteps,
  });

  /// The name of the plugin causing the issue
  final String pluginName;

  /// The type of issue detected
  final IssueType issueType;

  /// The severity level of the issue
  final IssueSeverity severity;

  /// Human-readable description of the issue
  final String description;

  /// List of platforms affected by this issue
  final List<String> affectedPlatforms;

  /// Stack trace if the issue was detected at runtime
  final StackTrace? stackTrace;

  /// Timestamp when the issue was detected
  final DateTime? detectedAt;

  /// Additional context information about the issue
  final Map<String, dynamic> additionalContext;

  /// Resolution steps to fix this issue
  final List<ResolutionStep>? resolutionSteps;

  /// Creates a copy of this issue with updated fields
  PluginIssue copyWith({
    String? pluginName,
    IssueType? issueType,
    IssueSeverity? severity,
    String? description,
    List<String>? affectedPlatforms,
    StackTrace? stackTrace,
    DateTime? detectedAt,
    Map<String, dynamic>? additionalContext,
    List<ResolutionStep>? resolutionSteps,
  }) {
    return PluginIssue(
      pluginName: pluginName ?? this.pluginName,
      issueType: issueType ?? this.issueType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      affectedPlatforms: affectedPlatforms ?? this.affectedPlatforms,
      stackTrace: stackTrace ?? this.stackTrace,
      detectedAt: detectedAt ?? this.detectedAt,
      additionalContext: additionalContext ?? this.additionalContext,
      resolutionSteps: resolutionSteps ?? this.resolutionSteps,
    );
  }

  /// Converts this issue to a JSON representation
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pluginName': pluginName,
      'issueType': issueType.name,
      'severity': severity.name,
      'description': description,
      'affectedPlatforms': affectedPlatforms,
      'stackTrace': stackTrace?.toString(),
      'detectedAt': detectedAt?.toIso8601String(),
      'additionalContext': additionalContext,
      'resolutionSteps': resolutionSteps?.map((step) => step.toJson()).toList(),
    };
  }

  /// Creates a PluginIssue from a JSON representation
  factory PluginIssue.fromJson(Map<String, dynamic> json) {
    return PluginIssue(
      pluginName: json['pluginName'] as String,
      issueType: IssueType.values.firstWhere(
        (e) => e.name == json['issueType'],
      ),
      severity: IssueSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      description: json['description'] as String,
      affectedPlatforms: List<String>.from(json['affectedPlatforms'] as List),
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
      additionalContext: Map<String, dynamic>.from(
        json['additionalContext'] as Map? ?? <String, dynamic>{},
      ),
      resolutionSteps: json['resolutionSteps'] != null
          ? (json['resolutionSteps'] as List)
              .map((step) => ResolutionStep.fromJson(step as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PluginIssue &&
        other.pluginName == pluginName &&
        other.issueType == issueType &&
        other.severity == severity &&
        other.description == description &&
        other.affectedPlatforms.toString() == affectedPlatforms.toString() &&
        other.resolutionSteps?.length == resolutionSteps?.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      pluginName,
      issueType,
      severity,
      description,
      affectedPlatforms,
      resolutionSteps?.length,
    );
  }

  @override
  String toString() {
    return 'PluginIssue('
        'pluginName: $pluginName, '
        'issueType: $issueType, '
        'severity: $severity, '
        'description: $description, '
        'affectedPlatforms: $affectedPlatforms'
        ')';
  }
}
