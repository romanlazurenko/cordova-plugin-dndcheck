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
    // First check silent mode using a more reliable method
    BOOL isSilentMode = [self checkSilentMode];
    if (isSilentMode) {
        NSLog(@"[DndCheckPlugin] Silent mode detected - DND enabled");
        return YES;
    }
    
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
    
    // Check if alerts are disabled (Focus mode)
    if (settings.alertSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Alerts disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if sounds are disabled (Focus mode)
    if (settings.soundSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Sounds disabled - likely Focus mode enabled");
        return YES;
    }
    
    // Check if badges are disabled (Focus mode)
    if (settings.badgeSetting == UNNotificationSettingDisabled) {
        NSLog(@"[DndCheckPlugin] Badges disabled - likely Focus mode enabled");
        return YES;
    }
    
    NSLog(@"[DndCheckPlugin] No DND indicators found - DND likely disabled");
    return NO;
}

- (BOOL)checkSilentMode {
    // Conservative approach: Since iOS silent switch detection is unreliable,
    // let's use a simplified method that's less intrusive
    
    @try {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        float currentVolume = audioSession.outputVolume;
        
        // Simple volume-based detection
        // If volume is 0 or very low, assume silent mode
        BOOL isSilent = (currentVolume <= 0.1);
        
        NSLog(@"[DndCheckPlugin] Simplified silent mode detection - Volume: %.3f, Silent: %@", 
              currentVolume, isSilent ? @"YES" : @"NO");
        
        // For now, let's be more aggressive and assume silent mode if volume is low
        // This prevents background audio interference
        return isSilent;
        
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] Exception in silent mode detection: %@", exception.reason);
        // Conservative: assume silent mode if we can't check
        return YES;
    }
}

@end
