
import 'missing_plugin_exception_detective_platform_interface.dart';

class MissingPluginExceptionDetective {
  Future<String?> getPlatformVersion() {
    return MissingPluginExceptionDetectivePlatform.instance.getPlatformVersion();
  }
}
