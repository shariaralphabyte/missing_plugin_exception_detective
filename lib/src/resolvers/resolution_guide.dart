import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../core/plugin_issue.dart';

/// Represents a step in a resolution guide
@immutable
class ResolutionStep {
  /// Creates a new resolution step
  const ResolutionStep({
    required this.title,
    required this.description,
    required this.action,
    this.command,
    this.filePath,
    this.fileContent,
    this.isOptional = false,
    this.platform,
  });

  /// Title of the resolution step
  final String title;

  /// Detailed description of what this step does
  final String description;

  /// The action to be performed
  final ResolutionAction action;

  /// Command to run (if action is runCommand)
  final String? command;

  /// File path to modify (if action involves file operations)
  final String? filePath;

  /// Content to add/modify in file
  final String? fileContent;

  /// Whether this step is optional
  final bool isOptional;

  /// Platform this step applies to
  final String? platform;

  /// Converts this step to a JSON representation
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'action': action.name,
      'command': command,
      'filePath': filePath,
      'fileContent': fileContent,
      'isOptional': isOptional,
      'platform': platform,
    };
  }
}

/// Types of resolution actions
enum ResolutionAction {
  /// Run a command in terminal
  runCommand,
  
  /// Create a new file
  createFile,
  
  /// Modify an existing file
  modifyFile,
  
  /// Delete a file
  deleteFile,
  
  /// Show information to user
  showInfo,
  
  /// Open a URL or documentation
  openUrl,
}

/// Generates step-by-step resolution guides for plugin issues
class ResolutionGuide {
  /// Creates a new resolution guide generator
  const ResolutionGuide();

  /// Generates a resolution guide for the given plugin issue
  Future<List<ResolutionStep>> generateGuide(PluginIssue issue) async {
    switch (issue.issueType) {
      case IssueType.missingRegistration:
        return _generateMissingRegistrationGuide(issue);
      case IssueType.missingDeclaration:
        return _generateMissingDeclarationGuide(issue);
      case IssueType.versionMismatch:
        return _generateVersionMismatchGuide(issue);
      case IssueType.platformConfigMissing:
        return _generatePlatformConfigGuide(issue);
      case IssueType.initializationFailure:
        return _generateInitializationFailureGuide(issue);
      case IssueType.methodChannelNotFound:
        return _generateMethodChannelGuide(issue);
      case IssueType.dependenciesMissing:
        return _generateDependenciesGuide(issue);
      case IssueType.buildConfigIssue:
        return _generateBuildConfigGuide(issue);
    }
  }

  /// Generates guide for missing plugin registration
  List<ResolutionStep> _generateMissingRegistrationGuide(PluginIssue issue) {
    final steps = <ResolutionStep>[];
    
    // Step 1: Run flutter clean
    steps.add(
      const ResolutionStep(
        title: 'Clean Flutter Project',
        description: 'Clean the Flutter project to remove any cached build artifacts',
        action: ResolutionAction.runCommand,
        command: 'flutter clean',
      ),
    );
    
    // Step 2: Get dependencies
    steps.add(
      const ResolutionStep(
        title: 'Get Dependencies',
        description: 'Fetch and resolve all project dependencies',
        action: ResolutionAction.runCommand,
        command: 'flutter pub get',
      ),
    );
    
    // Platform-specific steps
    for (final platform in issue.affectedPlatforms) {
      steps.addAll(_generatePlatformSpecificSteps(issue, platform));
    }
    
    // Step 3: Rebuild the project
    steps.add(
      const ResolutionStep(
        title: 'Rebuild Project',
        description: 'Rebuild the project to regenerate plugin registrations',
        action: ResolutionAction.runCommand,
        command: 'flutter build apk --debug',
        isOptional: true,
      ),
    );
    
    return steps;
  }

  /// Generates guide for missing plugin declaration
  List<ResolutionStep> _generateMissingDeclarationGuide(PluginIssue issue) {
    return [
      ResolutionStep(
        title: 'Add Plugin to pubspec.yaml',
        description: 'Add the ${issue.pluginName} plugin to your pubspec.yaml dependencies',
        action: ResolutionAction.modifyFile,
        filePath: 'pubspec.yaml',
        fileContent: '''
dependencies:
  flutter:
    sdk: flutter
  ${issue.pluginName}: ^latest_version  # Add this line
''',
      ),
      const ResolutionStep(
        title: 'Get Dependencies',
        description: 'Run flutter pub get to install the new dependency',
        action: ResolutionAction.runCommand,
        command: 'flutter pub get',
      ),
    ];
  }

  /// Generates guide for version mismatch
  List<ResolutionStep> _generateVersionMismatchGuide(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Check Plugin Versions',
        description: 'Check the current versions of your plugins',
        action: ResolutionAction.runCommand,
        command: 'flutter pub deps',
      ),
      ResolutionStep(
        title: 'Update Plugin Version',
        description: 'Update ${issue.pluginName} to the latest compatible version',
        action: ResolutionAction.modifyFile,
        filePath: 'pubspec.yaml',
        fileContent: '# Update the version constraint for ${issue.pluginName}',
      ),
      const ResolutionStep(
        title: 'Upgrade Dependencies',
        description: 'Upgrade all dependencies to their latest versions',
        action: ResolutionAction.runCommand,
        command: 'flutter pub upgrade',
      ),
    ];
  }

  /// Generates guide for platform configuration missing
  List<ResolutionStep> _generatePlatformConfigGuide(PluginIssue issue) {
    final steps = <ResolutionStep>[];
    
    for (final platform in issue.affectedPlatforms) {
      switch (platform) {
        case 'android':
          steps.addAll(_generateAndroidConfigSteps(issue));
          break;
        case 'ios':
          steps.addAll(_generateIosConfigSteps(issue));
          break;
        case 'web':
          steps.addAll(_generateWebConfigSteps(issue));
          break;
        case 'windows':
          steps.addAll(_generateWindowsConfigSteps(issue));
          break;
        case 'macos':
          steps.addAll(_generateMacosConfigSteps(issue));
          break;
        case 'linux':
          steps.addAll(_generateLinuxConfigSteps(issue));
          break;
      }
    }
    
    return steps;
  }

  /// Generates guide for initialization failure
  List<ResolutionStep> _generateInitializationFailureGuide(PluginIssue issue) {
    return [
      ResolutionStep(
        title: 'Check Plugin Documentation',
        description: 'Review the plugin documentation for initialization requirements',
        action: ResolutionAction.openUrl,
        command: 'https://pub.dev/packages/' + issue.pluginName,
      ),
      const ResolutionStep(
        title: 'Verify Plugin Setup',
        description: 'Ensure the plugin is properly set up according to its documentation',
        action: ResolutionAction.showInfo,
      ),
      const ResolutionStep(
        title: 'Check for Required Permissions',
        description: 'Verify that all required permissions are declared',
        action: ResolutionAction.showInfo,
      ),
      const ResolutionStep(
        title: 'Restart Application',
        description: 'Completely restart the application after making changes',
        action: ResolutionAction.runCommand,
        command: 'flutter run',
      ),
    ];
  }

  /// Generates guide for method channel not found
  List<ResolutionStep> _generateMethodChannelGuide(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Hot Restart Application',
        description: 'Perform a hot restart to reload plugin registrations',
        action: ResolutionAction.runCommand,
        command: 'flutter run --hot',
      ),
      const ResolutionStep(
        title: 'Check Plugin Registration',
        description: 'Verify that the plugin is properly registered for your target platform',
        action: ResolutionAction.showInfo,
      ),
      ResolutionStep(
        title: 'Verify Plugin Support',
        description: 'Check if ${issue.pluginName} supports your target platform',
        action: ResolutionAction.openUrl,
        command: 'https://pub.dev/packages/' + issue.pluginName,
      ),
    ];
  }

  /// Generates guide for missing dependencies
  List<ResolutionStep> _generateDependenciesGuide(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Install Dependencies',
        description: 'Install all project dependencies',
        action: ResolutionAction.runCommand,
        command: 'flutter pub get',
      ),
      const ResolutionStep(
        title: 'Check Dependency Conflicts',
        description: 'Check for any dependency conflicts',
        action: ResolutionAction.runCommand,
        command: 'flutter pub deps',
      ),
      const ResolutionStep(
        title: 'Resolve Conflicts',
        description: 'If conflicts exist, update pubspec.yaml to resolve them',
        action: ResolutionAction.showInfo,
      ),
    ];
  }

  /// Generates guide for build configuration issues
  List<ResolutionStep> _generateBuildConfigGuide(PluginIssue issue) {
    final steps = <ResolutionStep>[];
    
    for (final platform in issue.affectedPlatforms) {
      switch (platform) {
        case 'android':
          steps.add(
            const ResolutionStep(
              title: 'Check Android Build Configuration',
              description: 'Verify Android build.gradle configuration',
              action: ResolutionAction.showInfo,
              platform: 'android',
            ),
          );
          break;
        case 'ios':
          steps.add(
            const ResolutionStep(
              title: 'Check iOS Build Configuration',
              description: 'Verify iOS Podfile and project settings',
              action: ResolutionAction.showInfo,
              platform: 'ios',
            ),
          );
          break;
      }
    }
    
    return steps;
  }

  /// Generates platform-specific resolution steps
  List<ResolutionStep> _generatePlatformSpecificSteps(PluginIssue issue, String platform) {
    switch (platform) {
      case 'android':
        return [
          const ResolutionStep(
            title: 'Regenerate Android Plugin Registration',
            description: 'Force regeneration of Android plugin registrant',
            action: ResolutionAction.runCommand,
            command: 'flutter build apk --debug',
            platform: 'android',
          ),
        ];
      case 'ios':
        return [
          const ResolutionStep(
            title: 'Update iOS Pods',
            description: 'Update iOS CocoaPods dependencies',
            action: ResolutionAction.runCommand,
            command: 'cd ios && pod install --repo-update',
            platform: 'ios',
          ),
        ];
      case 'web':
        return [
          const ResolutionStep(
            title: 'Build for Web',
            description: 'Build the project for web to ensure web plugins are registered',
            action: ResolutionAction.runCommand,
            command: 'flutter build web',
            platform: 'web',
          ),
        ];
      default:
        return [];
    }
  }

  /// Generates Android-specific configuration steps
  List<ResolutionStep> _generateAndroidConfigSteps(PluginIssue issue) {
    return [
      ResolutionStep(
        title: 'Check Android Permissions',
        description: 'Add required permissions for ${issue.pluginName} to AndroidManifest.xml',
        action: ResolutionAction.modifyFile,
        filePath: 'android/app/src/main/AndroidManifest.xml',
        fileContent: '<!-- Add required permissions for ${issue.pluginName} -->',
        platform: 'android',
      ),
      const ResolutionStep(
        title: 'Update Gradle Configuration',
        description: 'Ensure proper Gradle configuration for plugin compatibility',
        action: ResolutionAction.showInfo,
        platform: 'android',
      ),
    ];
  }

  /// Generates iOS-specific configuration steps
  List<ResolutionStep> _generateIosConfigSteps(PluginIssue issue) {
    return [
      ResolutionStep(
        title: 'Check iOS Permissions',
        description: 'Add required permissions for ${issue.pluginName} to Info.plist',
        action: ResolutionAction.modifyFile,
        filePath: 'ios/Runner/Info.plist',
        fileContent: '<!-- Add required permissions for ${issue.pluginName} -->',
        platform: 'ios',
      ),
      const ResolutionStep(
        title: 'Update Podfile',
        description: 'Ensure proper Podfile configuration for plugin compatibility',
        action: ResolutionAction.showInfo,
        platform: 'ios',
      ),
    ];
  }

  /// Generates Web-specific configuration steps
  List<ResolutionStep> _generateWebConfigSteps(PluginIssue issue) {
    return [
      ResolutionStep(
        title: 'Add Web Plugin Script',
        description: 'Add required script imports for ${issue.pluginName} to web/index.html',
        action: ResolutionAction.modifyFile,
        filePath: 'web/index.html',
        fileContent: '<!-- Add script imports for ${issue.pluginName} -->',
        platform: 'web',
      ),
    ];
  }

  /// Generates Windows-specific configuration steps
  List<ResolutionStep> _generateWindowsConfigSteps(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Check Windows Plugin Support',
        description: 'Verify that the plugin supports Windows platform',
        action: ResolutionAction.showInfo,
        platform: 'windows',
      ),
    ];
  }

  /// Generates macOS-specific configuration steps
  List<ResolutionStep> _generateMacosConfigSteps(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Check macOS Plugin Support',
        description: 'Verify that the plugin supports macOS platform',
        action: ResolutionAction.showInfo,
        platform: 'macos',
      ),
    ];
  }

  /// Generates Linux-specific configuration steps
  List<ResolutionStep> _generateLinuxConfigSteps(PluginIssue issue) {
    return [
      const ResolutionStep(
        title: 'Check Linux Plugin Support',
        description: 'Verify that the plugin supports Linux platform',
        action: ResolutionAction.showInfo,
        platform: 'linux',
      ),
    ];
  }
}
