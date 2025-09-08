import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:missing_plugin_exception_detective/missing_plugin_exception_detective_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMissingPluginExceptionDetective platform = MethodChannelMissingPluginExceptionDetective();
  const MethodChannel channel = MethodChannel('missing_plugin_exception_detective');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
