# Android APK build

Use Godot 4.7.2 with matching Android export templates, JDK 17 and an Android SDK configured in Godot Editor Settings. The Android preset in export_presets.cfg builds an APK with arm64-v8a and armeabi-v7a libraries, landscape orientation, immersive display and the Compatibility renderer. No network or external-storage permission is requested.

The package is com.tidesworn.protectbesut. Output: build/android/ProtectBESUT.apk. Build outputs and signing material are not tracked. The preset contains no signing passwords or machine-specific SDK paths.

For a direct-install development APK, supply the existing development keystore using GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER and GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD, then run:

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release Android build/android/ProtectBESUT.apk
```

Use a production signing key and an Android App Bundle for a later Play Store submission. A development-signed APK is intended for direct phone installation. Android SDK apksigner verify and zipalign -c -P 16 4 verify the signed output.

Current gameplay, sea controls and story progression are documented in BESUT_STORY_CAMPAIGN.md. On a phone, check simultaneous joystick/Attack, Menu/Settings, drag-and-resize controls, NPC tapping, minimap readability, the bottom clock, sea steering/Pick Up and automatic nearby fish/heart collection, background/resume saving, and both rescue paths. Physical-phone playtesting is performed by the player.
