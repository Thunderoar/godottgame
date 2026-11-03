# Android APK build

Use Godot 4.7.2 with matching Android export templates, JDK 17 and an Android SDK configured in Godot Editor Settings. The Android preset in export_presets.cfg builds an APK with arm64-v8a and armeabi-v7a libraries, landscape orientation, immersive display and the Compatibility renderer. Gradle export is enabled for the HUAWEI Scan Kit plugin: install Godot's Gradle Build Template before exporting. The first Gradle build requires network access on the build computer. The app's local QR feature needs no network, camera or external-storage permission; the export plugin removes those optional SDK permissions. See [HMS_SCAN_KIT.md](HMS_SCAN_KIT.md) for setup, source and verification limits.

The package is com.tidesworn.protectbesut. Output: build/android/ProtectBESUT.apk. Build outputs and signing material are not tracked. The preset contains no signing passwords or machine-specific SDK paths.

## Smaller direct-install APKs

Both presets enable `gradle_build/compress_native_libraries`. Android extracts
the compressed libraries at installation instead of loading them directly from
the APK. This reduces the download; the installed footprint does not shrink by
the same percentage. Game resources and native-library contents are unchanged.

- **Android**: universal ARM64 + ARMv7, for both supported processor families.
- **Android ARM64**: ARM64 only, for phones whose Android system supports
  `arm64-v8a`. Use the universal build for 32-bit Android systems, including
  devices that have a 64-bit processor but run a 32-bit OS.

Export the smaller variant with the same signing environment as below:

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Android ARM64" build/android/ProtectBESUT-ARM64.apk
```

Keep the same signing key and package for updates. Version 1.3.5/code 14 is the
first compressed release. The original 1.3.4 APK is preserved for comparison.

For a direct-install development APK, supply the existing development keystore using GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER and GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD, then run:

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release Android build/android/ProtectBESUT.apk
```

Use a production signing key and an Android App Bundle for a later Play Store submission. A development-signed APK is intended for direct phone installation. Android SDK apksigner verify and zipalign -c -P 16 4 verify the signed output.

Current gameplay, sea controls and story progression are documented in BESUT_STORY_CAMPAIGN.md. On a phone, check simultaneous joystick/Attack, Menu/Settings, drag-and-resize controls, NPC tapping, minimap readability, the bottom clock, sea steering/Pick Up and automatic nearby fish/heart collection, background/resume saving, and both rescue paths. Physical-phone playtesting is performed by the player.
