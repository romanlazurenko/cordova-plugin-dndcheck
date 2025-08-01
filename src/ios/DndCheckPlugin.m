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
    // This method uses the most reliable approach for detecting silent mode
    // by attempting to play a very short audio file and measuring the duration
    
    @try {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *error = nil;
        
        // Store current category
        AVAudioSessionCategory originalCategory = audioSession.category;
        
        // Set category to playback to test silent mode
        [audioSession setCategory:AVAudioSessionCategoryPlayback 
                      withOptions:AVAudioSessionCategoryOptionMixWithOthers 
                            error:&error];
        
        if (error) {
            NSLog(@"[DndCheckPlugin] Error setting audio category: %@", error.localizedDescription);
            return NO;
        }
        
        [audioSession setActive:YES error:&error];
        
        if (error) {
            NSLog(@"[DndCheckPlugin] Error activating audio session: %@", error.localizedDescription);
            return NO;
        }
        
        // Create a SystemSoundID for testing
        SystemSoundID soundID;
        
        // Create a very short silent audio file URL
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"silent" ofType:@"wav"];
        NSURL *soundURL = nil;
        
        if (soundPath) {
            soundURL = [NSURL fileURLWithPath:soundPath];
        } else {
            // If no silent file exists, create one programmatically or use system sound
            // Use system sound ID for click (which respects silent mode)
            soundID = 1104; // System sound that respects silent switch
        }
        
        if (soundURL) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundID);
        }
        
        // Test by checking if we can play sound
        __block BOOL soundPlayed = NO;
        __block BOOL completionCalled = NO;
        
        // Set completion callback using a C function
        AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompletionCallback, (void *)(&completionCalled));
        
        // Play the sound
        AudioServicesPlaySystemSound(soundID);
        
        // Wait briefly for completion
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.1];
        while (!completionCalled && [timeout timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        
        // Clean up
        AudioServicesRemoveSystemSoundCompletion(soundID);
        if (soundURL) {
            AudioServicesDisposeSystemSoundID(soundID);
        }
        
        // Restore original audio session category
        [audioSession setCategory:originalCategory error:nil];
        
        // If completion wasn't called, likely in silent mode
        BOOL isSilent = !completionCalled;
        
        NSLog(@"[DndCheckPlugin] Silent mode test - Sound played: %@, Completion called: %@, Silent mode: %@", 
              soundPlayed ? @"YES" : @"NO", completionCalled ? @"YES" : @"NO", isSilent ? @"YES" : @"NO");
        
        return isSilent;
        
    } @catch (NSException *exception) {
        NSLog(@"[DndCheckPlugin] Exception in silent mode detection: %@", exception.reason);
        return NO;
    }
}

@end