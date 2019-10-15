#import "OssPlugin.h"
#import <oss/oss-Swift.h>

@implementation OssPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOssPlugin registerWithRegistrar:registrar];
}
@end
