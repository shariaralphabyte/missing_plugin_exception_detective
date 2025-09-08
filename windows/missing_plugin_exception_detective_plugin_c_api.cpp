#include "include/missing_plugin_exception_detective/missing_plugin_exception_detective_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "missing_plugin_exception_detective_plugin.h"

void MissingPluginExceptionDetectivePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  missing_plugin_exception_detective::MissingPluginExceptionDetectivePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
