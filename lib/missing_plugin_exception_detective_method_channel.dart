import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'missing_plugin_exception_detective_platform_interface.dart';

/// An implementation of [MissingPluginExceptionDetectivePlatform] that uses method channels.
class MethodChannelMissingPluginExceptionDetective extends MissingPluginExceptionDetectivePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('missing_plugin_exception_detective');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
