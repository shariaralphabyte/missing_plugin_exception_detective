# Missing Plugin Exception Detective 🔍

[![pub package](https://img.shields.io/pub/v/missing_plugin_exception_detective.svg)](https://pub.dev/packages/missing_plugin_exception_detective)
[![Build Status](https://github.com/shariaralphabyte/missing_plugin_exception_detective/workflows/CI/badge.svg)](https://github.com/shariaralphabyte/missing_plugin_exception_detective/actions)
[![Coverage Status](https://coveralls.io/repos/github/shariaralphabyte/missing_plugin_exception_detective/badge.svg?branch=main)](https://coveralls.io/github/shariaralphabyte/missing_plugin_exception_detective?branch=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A **developer productivity tool** that automatically detects, analyzes, and resolves Flutter plugin initialization issues (e.g., `MissingPluginException`). Save 2-4 hours of debugging time per week with intelligent diagnostics and step-by-step resolution guides.

## 🚀 Features

### Core Capabilities
- **🔍 Real-time Detection**: Automatically detects `MissingPluginException` errors at runtime
- **🧠 Intelligent Analysis**: Rule-based diagnostic engine with platform-specific insights
- **🛠️ Automated Solutions**: Step-by-step resolution guides with platform-aware fixes
- **⚡ Performance Optimized**: <10ms diagnostic completion with zero runtime overhead
- **🌐 Cross-platform**: Supports Android, iOS, Web, Windows, macOS, and Linux
- **📊 Multiple Output Formats**: Console, JSON, and Markdown reporting

### Advanced Features
- **📈 Static Analysis**: Compare `pubspec.yaml` vs `GeneratedPluginRegistrant`
- **🔄 Runtime Monitoring**: Continuous monitoring for plugin issues
- **🏥 Project Health Check**: Comprehensive Flutter project diagnostics
- **🎯 IDE Integration Ready**: Designed for VS Code and Android Studio extensions
- **📋 Enterprise Reporting**: JSON output for CI/CD integration

## 📦 Installation

### As a Dev Dependency (Recommended)

```yaml
dev_dependencies:
  missing_plugin_exception_detective: ^0.1.0
```

### Global Installation

```bash
flutter pub global activate missing_plugin_exception_detective
```

## 🎯 Quick Start

### Command Line Interface

```bash
# Basic diagnostic scan
flutter pub run missing_plugin_exception_detective:check

# Scan specific project path
flutter pub run missing_plugin_exception_detective:check --path=/path/to/project

# JSON output for CI/CD
flutter pub run missing_plugin_exception_detective:check --output=json

# Monitor runtime issues
flutter pub run missing_plugin_exception_detective:monitor --duration=60

# Comprehensive health check
flutter pub run missing_plugin_exception_detective:doctor
```

### Programmatic Usage

```dart
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective.dart';

void main() async {
  final detective = MissingPluginExceptionDetective();
  
  // Run diagnostic scan
  final result = await detective.diagnose(
    projectPath: '/path/to/flutter/project',
    includeResolutions: true,
  );
  
  // Check results
  if (result.hasIssues) {
    print('Found ${result.issues.length} issues:');
    for (final issue in result.issues) {
      print('• ${issue.pluginName}: ${issue.description}');
    }
  } else {
    print('✅ All plugins are properly configured!');
  }
  
  // Monitor runtime issues
  detective.monitorRuntime().listen((issue) {
    print('Runtime issue detected: ${issue.description}');
  });
}
```

## 📖 Usage Examples

### 1. Basic Project Scan

```bash
$ flutter pub run missing_plugin_exception_detective:check

🔍 Flutter Plugin Diagnostic Results
==================================================
📊 Summary:
  Status: ✅ HEALTHY
  Scanned plugins: 12
  Issues found: 0
  Scan duration: 145ms

✅ All plugins are properly configured!
```

### 2. Detecting Issues

```bash
$ flutter pub run missing_plugin_exception_detective:check

🔍 Flutter Plugin Diagnostic Results
==================================================
📊 Summary:
  Status: ❌ ERROR
  Scanned plugins: 15
  Issues found: 2
  Scan duration: 203ms

🚨 CRITICAL ISSUES (1):
  • camera
    Plugin camera is declared in pubspec.yaml but not registered for Android
    Platforms: android
    💡 Resolution:
       1. Clean Flutter Project
          Run: flutter clean
       2. Get Dependencies
          Run: flutter pub get
       3. Regenerate Android Plugin Registration
          Run: flutter build apk --debug

⚠️ MEDIUM ISSUES (1):
  • geolocator
    Plugin geolocator may require script import in web/index.html
    Platforms: web
```

### 3. JSON Output for CI/CD

```bash
$ flutter pub run missing_plugin_exception_detective:check --output=json

{
  "status": "error",
  "issues": [
    {
      "pluginName": "camera",
      "issueType": "missingRegistration",
      "severity": "critical",
      "description": "Plugin camera is declared in pubspec.yaml but not registered for Android",
      "affectedPlatforms": ["android"],
      "detectedAt": "2023-12-01T10:30:00.000Z",
      "resolutionGuide": [
        {
          "title": "Clean Flutter Project",
          "action": "runCommand",
          "command": "flutter clean"
        }
      ]
    }
  ],
  "scannedPlugins": ["camera", "geolocator"],
  "scanDuration": 203,
  "summary": "Found 1 issues: 1 critical priority."
}
```

### 4. Runtime Monitoring

```bash
$ flutter pub run missing_plugin_exception_detective:monitor --duration=30

🔍 Starting runtime monitoring...
Project path: /current/project
Duration: 30s

[2023-12-01T10:35:22.123Z] 🚨 camera
  MissingPluginException: No implementation found for method takePicture on channel plugins.flutter.io/camera
  Platforms: android

✅ Monitoring completed
```

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Detective Engine                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Static Analyzer │  │Runtime Detector │  │Resolution Guide │ │
│  │                 │  │                 │  │                 │ │
│  │ • pubspec.yaml  │  │ • Exception     │  │ • Step-by-step  │ │
│  │ • Registrants   │  │   monitoring    │  │   guides        │ │
│  │ • Build configs │  │ • Log analysis  │  │ • Platform-     │ │
│  │                 │  │                 │  │   specific      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      CLI Interface                             │
│  check │ monitor │ doctor │ --output=json,markdown,console     │
└─────────────────────────────────────────────────────────────────┘
```

### Supported Issue Types

| Issue Type | Description | Severity | Platforms |
|------------|-------------|----------|----------|
| `missingRegistration` | Plugin declared but not registered | Critical | All |
| `missingDeclaration` | Plugin registered but not declared | High | All |
| `versionMismatch` | Version conflicts between platforms | Medium | All |
| `platformConfigMissing` | Platform-specific config missing | Medium | Specific |
| `initializationFailure` | Plugin initialization failed | High | All |
| `methodChannelNotFound` | Method channel not available | High | All |
| `dependenciesMissing` | Dependencies not resolved | Medium | All |
| `buildConfigIssue` | Build configuration problems | Medium | Specific |

## 🔧 Configuration

### Detective Configuration

```dart
final config = DetectiveConfig(
  enableRuntimeDetection: true,
  enableStaticAnalysis: true,
  enableResolutionGuides: true,
  performanceMode: false,
  maxScanDuration: Duration(seconds: 30),
  includePlatforms: ['android', 'ios', 'web'],
  excludePlugins: ['dev_only_plugin'],
  verboseLogging: false,
);

final detective = MissingPluginExceptionDetective(config: config);
```

### CLI Options

```bash
# Platform filtering
flutter pub run missing_plugin_exception_detective:check --platforms=android,ios

# Plugin exclusion
flutter pub run missing_plugin_exception_detective:check --exclude=test_plugin,dev_plugin

# Performance mode (faster, less thorough)
flutter pub run missing_plugin_exception_detective:check --performance

# Verbose output
flutter pub run missing_plugin_exception_detective:check --verbose

# Disable resolution guides
flutter pub run missing_plugin_exception_detective:check --no-fix
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Test Coverage

The plugin maintains **≥90% test coverage** across:
- ✅ Unit tests for core components
- ✅ Integration tests for CLI commands
- ✅ Platform-specific analysis tests
- ✅ Error handling and edge cases

## 🚀 Performance

### Benchmarks

| Operation | Duration | Memory | Notes |
|-----------|----------|--------|---------|
| Static Analysis | <50ms | <10MB | Typical Flutter project |
| Runtime Detection | <10ms | <5MB | Per issue detection |
| Resolution Generation | <20ms | <5MB | Per issue guide |
| Full Diagnostic | <200ms | <25MB | 20+ plugins project |

### Performance Mode

Enable performance mode for faster scans in CI/CD:

```bash
flutter pub run missing_plugin_exception_detective:check --performance
```

## 🔌 Integration

### CI/CD Integration

#### GitHub Actions

```yaml
name: Plugin Health Check
on: [push, pull_request]

jobs:
  plugin-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter pub run missing_plugin_exception_detective:check --output=json > plugin-report.json
      - uses: actions/upload-artifact@v3
        with:
          name: plugin-report
          path: plugin-report.json
```

#### GitLab CI

```yaml
plugin_health_check:
  stage: test
  script:
    - flutter pub get
    - flutter pub run missing_plugin_exception_detective:check --output=json
  artifacts:
    reports:
      junit: plugin-report.json
```

### IDE Integration (Planned)

- **VS Code Extension**: Real-time diagnostics in editor
- **Android Studio Plugin**: Integrated with Flutter Inspector
- **IntelliJ IDEA**: Code analysis integration

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/shariaralphabyte/missing_plugin_exception_detective.git
cd missing_plugin_exception_detective

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example
cd example
flutter run
```

### Code Style

This project follows the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide and uses:
- **Linting**: `flutter_lints` with custom rules
- **Formatting**: `dart format`
- **Analysis**: `dart analyze`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent plugin architecture
- The Flutter community for feedback and contributions
- All contributors who help improve this tool

## 📞 Support

- **Documentation**: [pub.dev/documentation/missing_plugin_exception_detective](https://pub.dev/documentation/missing_plugin_exception_detective/latest/)
- **Issues**: [GitHub Issues](https://github.com/shariaralphabyte/missing_plugin_exception_detective/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shariaralphabyte/missing_plugin_exception_detective/discussions)

---

**Made with ❤️ for the Flutter community**

