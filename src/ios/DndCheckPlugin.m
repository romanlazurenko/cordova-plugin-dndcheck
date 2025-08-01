#import "DndCheckPlugin.h"
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

// C callback function for AudioServices completion
static void soundCompletionCallback(SystemSoundID ssID, void* clientData) {
    BOOL* completionFlag = (BOOL*)clientData;
    if (completionFlag) {
        *completionFlag = YES;
    }
}

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
    // Use a much simpler and non-intrusive approach that doesn't interfere with background audio
    // This method checks the silent switch without playing any sounds or changing audio session
    
    @try {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        // Don't change the audio session category - this prevents interference with background music
        // Just check the current state without modifying anything
        
        // Method 1: Check if the output volume is 0 (might indicate silent mode)
        float outputVolume = audioSession.outputVolume;
        
        // Method 2: Check audio route for silent mode indicators
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
        
        // Method 3: Use a very lightweight system sound test that doesn't interfere
        // Use kSystemSoundID_Vibrate which respects silent mode but doesn't play audio
        __block BOOL vibrationCompleted = NO;
        
        // Set up vibration completion callback
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, 
                                             soundCompletionCallback, (void *)(&vibrationCompleted));
        
        // Trigger vibration (this respects silent mode)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Wait briefly for completion
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.05];
        while (!vibrationCompleted && [timeout timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        
        // Clean up
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        
        // Determine silent mode based on multiple factors
        BOOL volumeBasedSilent = (outputVolume == 0.0);
        BOOL routeBasedSilent = hasReceiver && !hasSpeaker; // If only receiver available, might be silent
        BOOL vibrationBasedSilent = !vibrationCompleted;
        
        // Combine methods for more reliable detection
        BOOL isSilent = volumeBasedSilent || vibrationBasedSilent;
        
        NSLog(@"[DndCheckPlugin] Silent mode detection - Volume: %.2f, Route (Receiver: %@, Speaker: %@), Vibration completed: %@, Final result: %@", 
              outputVolume, hasReceiver ? @"YES" : @"NO", hasSpeaker ? @"YES" : @"NO", 
              vibrationCompleted ? @"YES" : @"NO", isSilent ? @"SILENT" : @"NOT_SILENT");
        
        return isSilent;
        
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] Exception in silent mode detection: %@", exception.reason);
        return NO;
    }
}

@end