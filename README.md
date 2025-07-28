# Cordova Plugin DND Check

A Cordova plugin to check Do Not Disturb state on Android devices.

## Installation

```bash
cordova plugin add https://github.com/romanlazurenko/cordova-plugin-dndcheck.git
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

## API

### `isDndEnabled(successCallback, errorCallback)`

Checks if Do Not Disturb mode is enabled on the device.

- **successCallback**: Function called when the check completes successfully
  - **parameter**: `boolean` - `true` if DND is enabled, `false` if disabled
- **errorCallback**: Function called when an error occurs
  - **parameter**: `string` - Error message

## Requirements

- Cordova >= 6.0.0
- Android >= 6.0.0 (API level 23+)
- Android permission: `ACCESS_NOTIFICATION_POLICY`

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