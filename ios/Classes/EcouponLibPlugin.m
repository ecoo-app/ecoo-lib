#import "EcouponLibPlugin.h"
#if __has_include(<ecoupon_lib/ecoupon_lib-Swift.h>)
#import <ecoupon_lib/ecoupon_lib-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ecoupon_lib-Swift.h"
#endif

@implementation EcouponLibPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEcouponLibPlugin registerWithRegistrar:registrar];
}
@end
