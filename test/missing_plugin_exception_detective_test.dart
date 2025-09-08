import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective_platform_interface.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMissingPluginExceptionDetectivePlatform
    with MockPlatformInterfaceMixin
    implements MissingPluginExceptionDetectivePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MissingPluginExceptionDetectivePlatform initialPlatform = MissingPluginExceptionDetectivePlatform.instance;

  test('$MethodChannelMissingPluginExceptionDetective is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMissingPluginExceptionDetective>());
  });

  test('getPlatformVersion', () async {
    MissingPluginExceptionDetective missingPluginExceptionDetectivePlugin = MissingPluginExceptionDetective();
    MockMissingPluginExceptionDetectivePlatform fakePlatform = MockMissingPluginExceptionDetectivePlatform();
    MissingPluginExceptionDetectivePlatform.instance = fakePlatform;

    expect(await missingPluginExceptionDetectivePlugin.getPlatformVersion(), '42');
  });
}
