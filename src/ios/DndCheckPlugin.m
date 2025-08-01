#import "DndCheckPlugin.h"
#import <UserNotifications/UserNotifications.h>

@implementation DndCheckPlugin

- (void)isDndEnabled:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    
    NSLog(@"[DndCheckPlugin] isDndEnabled called from iOS native code");
    
    @try {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                BOOL isDndEnabled = NO;
                
                // Check if notifications are authorized and if DND might be active
                if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                    // On iOS, we can't directly check DND state due to privacy restrictions
                    // But we can check if notifications are being delivered
                    // If notifications are not being delivered, it might be due to DND
                    
                    // For now, we'll return false (DND not enabled) as a safe default
                    // since we can't reliably detect DND state on iOS
                    isDndEnabled = NO;
                    
                    NSLog(@"[DndCheckPlugin] iOS DND check - returning false (safe default)");
                } else {
                    // Notifications not authorized, treat as DND enabled
                    isDndEnabled = YES;
                    NSLog(@"[DndCheckPlugin] iOS notifications not authorized, treating as DND enabled");
                }
                
                // Return integer (1 for true, 0 for false) to match Android implementation
                int result = isDndEnabled ? 1 : 0;
                NSLog(@"[DndCheckPlugin] iOS returning result: %d", result);
                
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:isDndEnabled ? 1 : 0];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }];
        } else {
            // iOS version < 10.0, return false as safe default
            NSLog(@"[DndCheckPlugin] iOS version < 10.0, returning false");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] iOS Error: %@", exception.reason);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Error checking DND state: %@", exception.reason]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

@end 