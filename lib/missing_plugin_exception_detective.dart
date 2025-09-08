/// A developer productivity tool that automatically detects, analyzes, and resolves
/// Flutter plugin initialization issues (e.g., MissingPluginException).
library missing_plugin_exception_detective;

export 'src/core/detective.dart';
export 'src/core/diagnostic_result.dart';
export 'src/core/plugin_issue.dart';
export 'src/analyzers/static_analyzer.dart';
export 'src/analyzers/runtime_detector.dart';
export 'src/resolvers/resolution_guide.dart';
export 'src/cli/cli_runner.dart';
