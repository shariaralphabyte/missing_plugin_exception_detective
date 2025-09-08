# Contributing to Missing Plugin Exception Detective

Thank you for your interest in contributing to Missing Plugin Exception Detective! This document provides guidelines and information for contributors.

## 🎯 Project Vision

Our goal is to create the most comprehensive and user-friendly Flutter plugin diagnostic tool that:
- Saves developers 2-4 hours of debugging time per week
- Provides intelligent, actionable solutions
- Maintains enterprise-grade quality standards
- Supports the entire Flutter ecosystem

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK (>=2.17.0)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/missing_plugin_exception_detective.git
   cd missing_plugin_exception_detective
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Setup**
   ```bash
   # Run tests
   flutter test
   
   # Run analysis
   dart analyze
   
   # Format code
   dart format .
   
   # Test CLI
   dart bin/missing_plugin_exception_detective.dart --help
   ```

4. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

## 📋 Development Guidelines

### Code Style

We follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- **Formatting**: Use `dart format` before committing
- **Linting**: All code must pass `dart analyze` without warnings
- **Documentation**: Public APIs must have dartdoc comments
- **Testing**: Maintain ≥90% test coverage

### Project Structure

```
lib/
├── src/
│   ├── core/           # Core domain models and engine
│   ├── analyzers/      # Static and runtime analysis
│   ├── resolvers/      # Resolution guide generation
│   └── cli/           # Command-line interface
├── missing_plugin_exception_detective.dart  # Public API
test/
├── core/              # Core component tests
├── analyzers/         # Analyzer tests
├── cli/              # CLI tests
└── integration/      # End-to-end tests
```

### Naming Conventions

- **Classes**: PascalCase (`PluginIssue`, `DiagnosticResult`)
- **Functions/Variables**: camelCase (`analyzeProject`, `issueCount`)
- **Constants**: lowerCamelCase (`maxScanDuration`)
- **Files**: snake_case (`plugin_issue.dart`, `static_analyzer.dart`)

## 🧪 Testing Requirements

### Test Categories

1. **Unit Tests** (Required)
   - Test individual functions and classes
   - Mock external dependencies
   - Cover edge cases and error conditions

2. **Integration Tests** (Required)
   - Test component interactions
   - Use real file system operations
   - Verify end-to-end workflows

3. **CLI Tests** (Required)
   - Test command-line interface
   - Verify output formats
   - Test error handling

### Writing Tests

```dart
// Good test structure
group('PluginIssue', () {
  test('should create issue with required fields', () {
    // Arrange
    const pluginName = 'test_plugin';
    
    // Act
    final issue = PluginIssue(
      pluginName: pluginName,
      issueType: IssueType.missingRegistration,
      severity: IssueSeverity.high,
      description: 'Test description',
      affectedPlatforms: ['android'],
    );
    
    // Assert
    expect(issue.pluginName, equals(pluginName));
    expect(issue.severity, equals(IssueSeverity.high));
  });
});
```

### Coverage Requirements

- **Minimum**: 90% overall coverage
- **Core Components**: 95% coverage required
- **CLI**: 85% coverage (due to platform-specific code)
- **Integration**: 80% coverage

Run coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🐛 Issue Guidelines

### Reporting Bugs

Use the bug report template and include:

1. **Environment**
   - Flutter version (`flutter --version`)
   - Dart version (`dart --version`)
   - Operating system
   - Plugin version

2. **Reproduction Steps**
   - Minimal code example
   - Expected vs actual behavior
   - Error messages/stack traces

3. **Additional Context**
   - Project structure
   - Relevant configuration files
   - Screenshots (if applicable)

### Feature Requests

Use the feature request template and include:

1. **Problem Statement**
   - What problem does this solve?
   - Who would benefit?
   - Current workarounds

2. **Proposed Solution**
   - Detailed description
   - API design (if applicable)
   - Examples of usage

3. **Alternatives**
   - Other solutions considered
   - Why this approach is preferred

## 🔄 Pull Request Process

### Before Submitting

1. **Code Quality**
   ```bash
   # Format code
   dart format .
   
   # Run analysis
   dart analyze
   
   # Run tests
   flutter test
   
   # Check coverage
   flutter test --coverage
   ```

2. **Documentation**
   - Update README if needed
   - Add/update dartdoc comments
   - Update CHANGELOG.md

3. **Testing**
   - Add tests for new functionality
   - Ensure existing tests pass
   - Test CLI changes manually

### PR Guidelines

1. **Title**: Use conventional commits format
   - `feat: add runtime monitoring for web platform`
   - `fix: resolve issue with iOS registrant detection`
   - `docs: update installation instructions`

2. **Description**: Include
   - Summary of changes
   - Related issue numbers
   - Breaking changes (if any)
   - Testing performed

3. **Size**: Keep PRs focused and reasonably sized
   - Prefer multiple small PRs over one large PR
   - Separate refactoring from feature additions

### Review Process

1. **Automated Checks**
   - All CI checks must pass
   - Code coverage must meet requirements
   - No merge conflicts

2. **Code Review**
   - At least one maintainer approval required
   - Address all review comments
   - Maintain respectful discussion

3. **Merge**
   - Squash and merge for feature branches
   - Maintain clean commit history

## 🏗️ Architecture Guidelines

### Adding New Features

1. **Core Components** (`lib/src/core/`)
   - Domain models and business logic
   - Platform-agnostic code
   - High test coverage required

2. **Analyzers** (`lib/src/analyzers/`)
   - Static analysis logic
   - Runtime detection systems
   - Platform-specific implementations

3. **Resolvers** (`lib/src/resolvers/`)
   - Resolution guide generation
   - Platform-specific solutions
   - Step-by-step instructions

4. **CLI** (`lib/src/cli/`)
   - Command-line interface
   - Output formatting
   - User interaction

### Design Principles

1. **Separation of Concerns**
   - Each class has a single responsibility
   - Clear interfaces between components
   - Minimal coupling

2. **Testability**
   - Dependency injection for external services
   - Pure functions where possible
   - Mockable interfaces

3. **Performance**
   - Async/await for I/O operations
   - Lazy loading where appropriate
   - Memory-efficient algorithms

4. **Extensibility**
   - Plugin architecture for new analyzers
   - Configurable behavior
   - Clear extension points

## 📚 Documentation Standards

### Code Documentation

```dart
/// Detects and analyzes Flutter plugin configuration issues.
///
/// The [StaticAnalyzer] examines project files to identify potential
/// plugin registration problems, version mismatches, and configuration
/// issues across different platforms.
///
/// Example usage:
/// ```dart
/// final analyzer = StaticAnalyzer();
/// final issues = await analyzer.analyze(
///   projectPath: '/path/to/project',
///   includePlatforms: ['android', 'ios'],
/// );
/// ```
class StaticAnalyzer {
  /// Creates a new static analyzer instance.
  const StaticAnalyzer();
  
  /// Analyzes the Flutter project for plugin configuration issues.
  ///
  /// Returns a list of [PluginIssue]s found during analysis.
  /// The [projectPath] must point to a valid Flutter project directory.
  /// 
  /// Throws [ArgumentError] if the project path is invalid.
  Future<List<PluginIssue>> analyze({
    required String projectPath,
    List<String> includePlatforms = const ['android', 'ios'],
    List<String> excludePlugins = const <String>[],
  }) async {
    // Implementation...
  }
}
```

### API Documentation

- All public classes and methods must have dartdoc comments
- Include usage examples for complex APIs
- Document parameters, return values, and exceptions
- Use `///` for dartdoc, `//` for implementation comments

## 🚀 Release Process

### Version Management

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Release Checklist

1. **Pre-release**
   - [ ] All tests pass
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated
   - [ ] Version bumped in pubspec.yaml

2. **Release**
   - [ ] Create release tag
   - [ ] Publish to pub.dev
   - [ ] Update GitHub release notes

3. **Post-release**
   - [ ] Announce on social media
   - [ ] Update documentation site
   - [ ] Monitor for issues

## 🤝 Community Guidelines

### Code of Conduct

We are committed to providing a welcoming and inclusive environment:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and diverse perspectives  
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Remember that everyone is learning

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code review and collaboration

### Recognition

Contributors are recognized through:
- GitHub contributor graphs
- Release notes acknowledgments
- Special recognition for significant contributions

## 📞 Getting Help

### Documentation

- **API Reference**: [pub.dev/documentation](https://pub.dev/documentation/missing_plugin_exception_detective/latest/)
- **Examples**: Check the `example/` directory
- **Tests**: Look at test files for usage patterns

### Support Channels

1. **GitHub Discussions**: General questions and help
2. **GitHub Issues**: Bug reports and feature requests
3. **Code Review**: Ask questions in pull requests

### Maintainer Contact

For sensitive issues or questions:
- Create a private GitHub issue
- Tag maintainers in discussions
- Follow up on stale issues

---

Thank you for contributing to Missing Plugin Exception Detective! Your efforts help make Flutter development more productive for developers worldwide. 🚀
