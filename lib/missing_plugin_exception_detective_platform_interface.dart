import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'missing_plugin_exception_detective_method_channel.dart';

abstract class MissingPluginExceptionDetectivePlatform extends PlatformInterface {
  /// Constructs a MissingPluginExceptionDetectivePlatform.
  MissingPluginExceptionDetectivePlatform() : super(token: _token);

  static final Object _token = Object();

  static MissingPluginExceptionDetectivePlatform _instance = MethodChannelMissingPluginExceptionDetective();

  /// The default instance of [MissingPluginExceptionDetectivePlatform] to use.
  ///
  /// Defaults to [MethodChannelMissingPluginExceptionDetective].
  static MissingPluginExceptionDetectivePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MissingPluginExceptionDetectivePlatform] when
  /// they register themselves.
  static set instance(MissingPluginExceptionDetectivePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
