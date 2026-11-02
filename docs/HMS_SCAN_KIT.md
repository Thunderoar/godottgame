# HUAWEI Scan Kit — local BESUT message QR

Settings on the title screen, land and ocean include **SHARE BESUT → Create message QR**.
On Android, the button calls HUAWEI Scan Kit's real `ScanUtil.buildBitmap()` API through
the `ProtectBesutHms` Godot v2 Android plugin. Scan the displayed QR with another
phone, or share a screenshot. Its complete payload is:

```text
PB (Protect BESUT)
Nature needs a protector.
```

This is message sharing, not save export/import or a reward code. It reads no
player progress, account, developer phrase or device identifier. Closing Settings
releases the displayed texture. It uses the existing Settings ownership and does
not introduce another modal or pause gameplay.

## Why this integration

Huawei's [CardReader codelab](https://developer.huawei.com/consumer/en/codelab/card_reader)
explicitly describes Scan Kit as a standalone SDK without AppGallery Connect
configuration. This local barcode-generation integration supplies no app ID,
API key, Huawei account, `agconnect-services.json`, signing fingerprint registration
or identity-verification flow. The existing Android package and signing setup
are retained. Publishing on AppGallery is a separate process with its own account
requirements; this feature does not bypass them.

The pinned SDK is `com.huawei.hms:scan:2.15.0.301` from Huawei's Maven repository.
Huawei's [version history](https://developer.huawei.com/consumer/cn/doc/HMScore-Guides/android-version-change-history-0000001050043947)
records Android 16/target 36 support in this release and 16 KB page support in
the earlier 2.13.0.301 release. [The generation API](https://developer.huawei.com/consumer/es/doc/HMSCore-References/scan-scanutil4-0000001050167699)
accepts a string and returns a bitmap. The bridge disables operation tracking;
the export plugin removes optional network, Wi-Fi-state, camera and image/storage
permissions from merged SDK manifests. There is no camera scanner or remote call.

## Build

Godot v2 Android plugins [require Gradle export](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).
`export_presets.cfg` enables it and `project.godot` enables the export plugin.
The small compiled bridge is included at
`addons/pb_hms_scan/bin/ProtectBesutHms.aar`; Huawei and its transitive libraries
are resolved by Gradle during export, not downloaded by the game.

1. Use the matching Godot 4.7.2 Android export templates, an Android SDK and
   a Gradle-compatible JDK (17 recommended). The installed template currently
   requests Android platform 36 and build tools 36.1.0; install its prerequisites.
2. Install the Gradle Build Template from Godot's Project menu. Alternatively,
   rebuild the bridge and install a missing template with:

   ```powershell
   ./tools/build_hms_bridge.ps1 -InstallGradleTemplate
   ```

   This refuses to replace an existing `android/build` directory. For bridge-only
   rebuilds, omit the switch. Optional `-JavaHome`, `-AndroidJar` and
   `-TemplateSource` select local build prerequisites. The helper verifies the
   downloaded Huawei archive's SHA-256 and compiles against the installed matching
   Godot Android library with Java 17 bytecode. Java source and its manifest/keep
   rule live under `tools/android_hms/`.
3. Export using the existing Android preset and signing environment described in
   `ANDROID_BUILD.md`. The first Gradle export needs network access on the build
   computer. No Huawei verification or account configuration is supplied.

Desktop and Android builds missing the bridge show an unavailable explanation
and disable the button; no substitute QR implementation pretends to be HMS.

## Verification

The full isolated gameplay gate runs `HmsScanChecks`: native boundary failures,
PNG-to-texture conversion, exact public payload and unchanged journey data.
`tools/hms_scan_test.tscn` additionally checks the existing title Settings action,
availability, texture cleanup and no save creation. With `-- --capture`, run it
with isolated `APPDATA`, `LOCALAPPDATA` and `TIDESWORN_TEST_ROOT` to capture
1280×720 and 832×480 Settings views. Normal player data must not be used.

For a real Android integration review, use a disposable source copy and a separate
test package, set its main scene to `res://tools/hms_scan_test.tscn`, and include
the test tools in that test export. The harness requires the native singleton,
presses the real Settings button and saves `user://hms-message-qr.png` for an
independent scan. It does not create or delete a journey. On a clean install,
verify success without Huawei sign-in, HMS Core installation or network access;
scan the QR with another phone and check the exact message above. Check the final
merged APK manifest for unexpected SDK permissions as part of Android export QA.

2026-11-01 evidence: real Huawei/Godot bridge Java compilation passed; isolated
Godot import passed with the existing Android build-tools-directory diagnostic;
the full gameplay gate passed 6,758 checks; native Windows focused review passed
14 checks, with both captures visually inspected. No APK export, emulator or
physical-phone execution has been established by these checks.
