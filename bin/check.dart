#!/usr/bin/env dart

import 'package:missing_plugin_exception_detective/src/cli/cli_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = CliRunner();
  await runner.run(['check', ...arguments]);
}
