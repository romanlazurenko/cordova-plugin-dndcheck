# Cordova Plugin DND Check

[![npm version](https://badge.fury.io/js/cordova-plugin-dndcheck.svg)](https://badge.fury.io/js/cordova-plugin-dndcheck)
[![GitHub license](https://img.shields.io/github/license/romanlazurenko/cordova-plugin-dndcheck.svg)](https://github.com/romanlazurenko/cordova-plugin-dndcheck/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/romanlazurenko/cordova-plugin-dndcheck.svg)](https://github.com/romanlazurenko/cordova-plugin-dndcheck/stargazers)

A Cordova plugin to check Do Not Disturb state on Android devices. This plugin allows you to respect the user's Do Not Disturb settings when playing sounds or showing notifications in your Cordova applications.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [API](#api)
- [Features](#features)
- [Requirements](#requirements)
- [Platform Support](#platform-support)
- [License](#license)
- [Contributing](#contributing)
- [Changelog](#changelog)

## Installation

### From npm
```bash
cordova plugin add cordova-plugin-dndcheck
```

### From GitHub
```bash
cordova plugin add https://github.com/romanlazurenko/cordova-plugin-dndcheck.git
```

## Quick Start

1. **Install the plugin:**
   ```bash
   cordova plugin add cordova-plugin-dndcheck
   ```

2. **Check DND state:**
   ```javascript
   cordova.plugins.DndCheck.isDndEnabled(
       function(isDndEnabled) {
           if (isDndEnabled) {
               console.log("DND is enabled - respect user's quiet time");
           } else {
               console.log("DND is disabled - safe to play sounds");
           }
       },
       function(error) {
           console.error("Error checking DND state:", error);
       }
   );
   ```

## Usage

```javascript
// Check if DND is enabled
cordova.plugins.DndCheck.isDndEnabled(
    function(isDndEnabled) {
        console.log("DND is enabled:", isDndEnabled);
        if (isDndEnabled) {
            // DND is enabled, don't play sound
            console.log("DND is on, skipping sound");
        } else {
            // DND is disabled, play sound
            playSound();
        }
    },
    function(error) {
        console.error("Error checking DND state:", error);
        // Fallback: play sound anyway
        playSound();
    }
);
```

### Vue.js Example

```javascript
// In your Vue component
methods: {
    playMP3() {
        // Check DND status first if on Android
        if (this.isAndroid && window.cordova?.plugins?.DndCheck) {
            console.log("Checking DND state using native plugin...");
            window.cordova.plugins.DndCheck.isDndEnabled(
                (isDndEnabled) => {
                    console.log("DND is enabled:", isDndEnabled);
                    if (isDndEnabled) {
                        // DND is enabled, don't play sound
                        console.log("DND is on, skipping sound");
                    } else {
                        // DND is disabled, play sound
                        this._playSound();
                    }
                },
                (error) => {
                    console.error("Error checking DND state:", error);
                    // Fallback: play sound anyway
                    this._playSound();
                }
            );
        } else {
            // Not Android or plugin not available, play sound directly
            this._playSound();
        }
    },

    _playSound() {
        // Your sound playing logic here
        const audio = new Audio('/yoursound.mp3');
        audio.play();
    }
}
```

## API

### `isDndEnabled(successCallback, errorCallback)`

Checks if Do Not Disturb mode is enabled on the device.

- **successCallback**: Function called when the check completes successfully
  - **parameter**: `boolean` - `true` if DND is enabled, `false` if disabled
- **errorCallback**: Function called when an error occurs
  - **parameter**: `string` - Error message

## Features

- ✅ Check Do Not Disturb state on Android devices
- ✅ Simple boolean return value
- ✅ Error handling with fallback support
- ✅ Respects user privacy settings
- ✅ Lightweight and efficient

## Requirements

- Cordova >= 6.0.0
- Android >= 6.0.0 (API level 23+)
- Android permission: `ACCESS_NOTIFICATION_POLICY`

> **Note**: This plugin requires the `ACCESS_NOTIFICATION_POLICY` permission to check DND state on Android. The permission is automatically added to your app's manifest when you install the plugin.

## Platform Support

- ✅ Android 6.0+ (API 23+)
- ❌ iOS (not implemented)
- ❌ Browser (not implemented)

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Changelog

### 1.0.0
- Initial release
- Android DND state checking
- Boolean return value
- Error handling 