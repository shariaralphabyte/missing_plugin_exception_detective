#ifndef FLUTTER_PLUGIN_MISSING_PLUGIN_EXCEPTION_DETECTIVE_PLUGIN_H_
#define FLUTTER_PLUGIN_MISSING_PLUGIN_EXCEPTION_DETECTIVE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace missing_plugin_exception_detective {

class MissingPluginExceptionDetectivePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MissingPluginExceptionDetectivePlugin();

  virtual ~MissingPluginExceptionDetectivePlugin();

  // Disallow copy and assign.
  MissingPluginExceptionDetectivePlugin(const MissingPluginExceptionDetectivePlugin&) = delete;
  MissingPluginExceptionDetectivePlugin& operator=(const MissingPluginExceptionDetectivePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace missing_plugin_exception_detective

#endif  // FLUTTER_PLUGIN_MISSING_PLUGIN_EXCEPTION_DETECTIVE_PLUGIN_H_
