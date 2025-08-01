#import "DndCheckPlugin.h"
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>

@implementation DndCheckPlugin

- (void)isDndEnabled:(CDVInvokedUrlCommand*)command {
    NSLog(@"[DndCheckPlugin] isDndEnabled called from iOS native code");
    
    @try {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                BOOL isDndEnabled = [self checkDndStatus:settings];
                
                // Return integer (1 for true, 0 for false) to match Android implementation
                int resultValue = isDndEnabled ? 1 : 0;
                NSLog(@"[DndCheckPlugin] iOS DND enabled: %@, returning result: %d", isDndEnabled ? @"YES" : @"NO", resultValue);
                
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:resultValue];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
        } else {
            // iOS version < 10.0, return false as safe default
            NSLog(@"[DndCheckPlugin] iOS version < 10.0, returning false");
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] iOS Error: %@", exception.reason);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Error checking DND state: %@", exception.reason]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (BOOL)checkDndStatus:(UNNotificationSettings *)settings {
    // Check if notifications are completely disabled (likely Focus mode)
    if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
        NSLog(@"[DndCheckPlugin] Notifications denied - likely Focus mode enabled");
        return YES;
    }
    
    // Check if notification center is disabled (Focus mode)
    if (settings.notificationCenterSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Notification center disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if lock screen notifications are disabled (Focus mode)
    if (settings.lockScreenSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Lock screen notifications disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if silent mode is enabled (physical switch)
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setActive:YES error:&error];
    
    if (error) {
        NSLog(@"[DndCheckPlugin] Error activating audio session: %@", error.localizedDescription);
    } else {
        float outputVolume = audioSession.outputVolume;
        BOOL isSilent = (outputVolume == 0.0);
        
        NSLog(@"[DndCheckPlugin] Audio volume: %.2f, Silent mode: %@", outputVolume, isSilent ? @"YES" : @"NO");
        
        if (isSilent) {
            return YES;
        }
    }
    
    // Check if alerts are disabled (Focus mode)
    if (settings.alertSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Alerts disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if badges are disabled (Focus mode)
    if (settings.badgeSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Badges disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if sounds are disabled (Focus mode)
    if (settings.soundSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Sounds disabled - likely Focus mode enabled");
        return YES;
    }
    
    NSLog(@"[DndCheckPlugin] No DND indicators found - DND likely disabled");
    return NO;
}

@end