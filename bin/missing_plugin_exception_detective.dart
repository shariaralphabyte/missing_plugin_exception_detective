#!/usr/bin/env dart

import 'dart:io';

import 'package:missing_plugin_exception_detective/src/cli/cli_runner.dart';

/// Entry point for the Missing Plugin Exception Detective CLI tool
Future<void> main(List<String> arguments) async {
  final runner = CliRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
