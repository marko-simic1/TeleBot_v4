//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<device_info/FLTDeviceInfoPlugin.h>)
#import <device_info/FLTDeviceInfoPlugin.h>
#else
@import device_info;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<platform_device_id_v3/PlatformDeviceIdPlugin.h>)
#import <platform_device_id_v3/PlatformDeviceIdPlugin.h>
#else
@import platform_device_id_v3;
#endif

#if __has_include(<reactive_ble_mobile/ReactiveBlePlugin.h>)
#import <reactive_ble_mobile/ReactiveBlePlugin.h>
#else
@import reactive_ble_mobile;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FLTDeviceInfoPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTDeviceInfoPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [PlatformDeviceIdPlugin registerWithRegistrar:[registry registrarForPlugin:@"PlatformDeviceIdPlugin"]];
  [ReactiveBlePlugin registerWithRegistrar:[registry registrarForPlugin:@"ReactiveBlePlugin"]];
}

@end
