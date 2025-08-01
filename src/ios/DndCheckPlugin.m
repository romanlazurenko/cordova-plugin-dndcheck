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
    // Use AVAudioSession with soloAmbient category to detect silent mode
    // This is the most reliable method as it respects the Silent switch
    
    @try {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        // Store current category and options
        AVAudioSessionCategory originalCategory = audioSession.category;
        AVAudioSessionCategoryOptions originalOptions = audioSession.categoryOptions;
        
        // Set to soloAmbient category which is silenced by the Silent switch
        NSError *error = nil;
        [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:&error];
        
        if (error) {
            NSLog(@"[DndCheckPlugin] Error setting soloAmbient category: %@", error.localizedDescription);
            return NO;
        }
        
        // Activate the session
        [audioSession setActive:YES error:&error];
        
        if (error) {
            NSLog(@"[DndCheckPlugin] Error activating audio session: %@", error.localizedDescription);
            return NO;
        }
        
        // Check if the session is actually playing (this will be affected by Silent switch)
        // We can detect this by checking if the session is muted
        BOOL isMuted = audioSession.outputVolume == 0.0;
        
        // Also check the current route - if only receiver is available, it might be silent
        AVAudioSessionRouteDescription *route = audioSession.currentRoute;
        BOOL hasReceiver = NO;
        BOOL hasSpeaker = NO;
        
        for (AVAudioSessionPortDescription *output in route.outputs) {
            if ([output.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
                hasReceiver = YES;
            } else if ([output.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
                hasSpeaker = YES;
            }
        }
        
        // Restore original category and options
        [audioSession setCategory:originalCategory withOptions:originalOptions error:nil];
        
        // Determine silent mode
        BOOL volumeBasedSilent = isMuted;
        BOOL routeBasedSilent = hasReceiver && !hasSpeaker;
        BOOL isSilent = volumeBasedSilent || routeBasedSilent;
        
        NSLog(@"[DndCheckPlugin] Silent mode detection (soloAmbient) - Volume: %.2f, Route (Receiver: %@, Speaker: %@), Final result: %@", 
              audioSession.outputVolume, hasReceiver ? @"YES" : @"NO", hasSpeaker ? @"YES" : @"NO", 
              isSilent ? @"SILENT" : @"NOT_SILENT");
        
        return isSilent;
        
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] Exception in silent mode detection: %@", exception.reason);
        return NO;
    }
}

@end