# Real-world day/night using HUAWEI Location Kit

Research date: 2026-11-01. Scope: online feasibility research and inspection of
the current Protect BESUT source. This document does not implement the feature,
register an account, enable a cloud service, request location or change saves.

## Finding and recommended approach

The feature is feasible. Use Location Kit to obtain latitude/longitude, then
calculate sunrise/sunset locally from those coordinates and current UTC time.
Feed the resulting environment phase into one GameState-owned policy used by
both presentation and gameplay. The player should opt into a Real-world mode;
retain Classic as an explicitly selected alternative and as a usable fallback.

Location Kit supplies positioning. The solar calculation and integration with
this game's clock are separate work. A custom backend, Map Kit, address lookup,
geofences, activity recognition and continuous background tracking are unnecessary
for the proposed design. These are design conclusions, not claims that Location
Kit automatically implements a game clock.

The main prerequisite is different from the existing standalone Scan Kit feature:
Huawei's documented Location Kit setup uses an AppGallery Connect application,
enabled Location service and registered signing fingerprint. Its preparation
guide explicitly requires developer identity verification. Do not promise this
route satisfies a strict no-developer-verification requirement. [1][2][3]

## Verified online findings

### Setup and account ownership

The official Android sample requires an AppGallery Connect project/application,
`agconnect-services.json`, signing certificate configuration and fingerprint.
Use the existing `com.tidesworn.protectbesut` package and signing identity; do not
generate a replacement release key. Register debug and release fingerprints
where their respective builds need service access. The owner must use their
own developer account, or grant an existing team member appropriate access.
This does not imply a Huawei sign-in screen for each player. [1][2]

Huawei's Android codelab repeats the project, fingerprint and API-enablement
requirements. Its example uses SDK 6.4.0.300; the GitHub sample uses 6.12.0.300.
Both are examples, not reliable evidence of today's newest release. [2][3]

### API and lifecycle

The relevant APIs are `LocationServices.getFusedLocationProviderClient(...)`,
`getLastLocation()`, `SettingsClient.checkLocationSettings(...)`,
`requestLocationUpdates(...)` and `removeLocationUpdates(...)`. Huawei's example
checks settings before requesting updates and retains the callback for removal.
`getLastLocation()` can return null; an empty or old cache is not a current fix.
Huawei documents `setNumUpdates(1)` for a single result. [4][5][6]

Recommended policy: accept a recent usable cached fix, otherwise issue a bounded
foreground request for one result. Validate finite WGS84 coordinates, range,
reported age and accuracy. Stop after success, failure, cancellation, timeout or
loss of foreground ownership. Re-evaluate phase on resume, date/time changes and
meaningful movement; use a lightweight local timer between location refreshes.
Exact cache-age, timeout and movement thresholds need device testing.

### Permissions and battery

Android recommends requesting approximate location where sufficient, and asking
when the player selects the feature. Start with `ACCESS_COARSE_LOCATION` and
while-in-use access. If the selected Huawei SDK genuinely requires precise access,
request coarse and fine together and continue handling approximate-only grants.
Precise-to-approximate downgrades may restart the process. [7]

This feature needs no app background-location permission or location foreground
service: the activity can obtain a fix while visible and stop requests when
hidden. Check the final merged manifest rather than copying the broad demo
manifest, which also supports unrelated sample features. [8][9]

For ordinary Malaysian latitudes, a regional position should be sufficient for
game day/night; this is an engineering assessment, with less tolerance near a
transition or at extreme latitudes. The goal is not navigation accuracy.

### Day/night definition and solar calculation

Recommended game rule: day begins at calculated sunrise; night begins at
calculated sunset. Fade the scenery through dawn and civil dusk. Sunrise/sunset
and the end of twilight are distinct events: USNO defines civil twilight's dark
boundary at a geometric solar-center altitude of -6 degrees, and conventional
sunrise/sunset at approximately -0.8333 degrees. Actual observed light also
depends on atmosphere, terrain and clouds. This feature matches astronomical
day/night, not whether a room or storm is dark. [10]

Use a tested, pinned solar implementation. SunCalc provides sunrise, sunset,
dawn/dusk and explicit polar-day/night cases; it is a possible reference to port
or wrap, not a native Godot dependency already present here. Retain its license
if adapting code. Its current v2 documentation has changed units/conventions
from older versions, so do not mix v1 snippets with v2 behavior. [11][12]

Use UTC instants for comparisons, with correct date/solar-day selection around
midnight and the date line. Device timezone is useful for display; a timezone
name is not required merely to calculate the Sun's position from UTC and
coordinates. DST must not add or remove an hour of solar daylight. A phone-clock
schedule such as 07:00-19:00 is a simpler approximation, not a location-dependent
sunrise/sunset implementation.

SunCalc's `night` event means astronomical darkness, substantially later than
sunset in some places. Do not accidentally use that property as the intended
game sunset transition. Handle absent rise/set events at high latitudes explicitly.
Avoid comparing apparent/refracted altitude against a geometric threshold
without understanding the chosen algorithm. [10][11]

### Cost, backend and device support

Huawei's published pricing page lists Android fused location as free; it lists
GeoLocation web APIs and geofencing separately as paid services. The proposed
design uses the Android fused service, not those additional services. Recheck
current service terms in the owner's console before enabling anything paid. [13]

AppGallery Connect is needed for service/application configuration under the
documented route. It is not automatically a player-location history dashboard.
No custom backend is needed for the solar calculation. A local calculation also
does not prove that the positioning SDK itself makes no network requests; assess
the chosen SDK's data handling and disclose actual behavior.

Huawei's older FAQ describes HMS Core installation and its own location settings
as dependencies of that integration path. The sample supports Huawei and
non-Huawei Android devices. Treat HMS Core/device availability as a tested
capability and handle unavailable service explicitly; do not promise identical
behavior on every Android phone or assume GMS makes HMS APIs work. [2][6]

## Current Protect BESUT source findings

Inspected on main at source commit `906f5a1`, with the existing uncommitted Scan
Kit work retained. Current source is authoritative over dated historical docs.

| Owner | Current behavior | Consequence for this feature |
| --- | --- | --- |
| `scripts/autoload/game_state.gd` | `DAY_PHASE_SECONDS = 180`; `is_night()`, `night_number()` and `time_string()` derive from saved `world_time` | Introduce a consistent phase policy and migrate wave identity; changing only the constant is insufficient |
| `scripts/game/game.gd` | Advances the clock during an active world, respecting existing story/developer/wild-duel suspension | Keep play simulation suspension while rechecking external time safely on resume |
| `scripts/creative/monsoon_lighting.gd` | Independently normalizes lighting to a 360-second cycle | Lighting must consume the accepted phase/daylight sample rather than keep cycling every six minutes |
| `scripts/world/lobby.gd` | Uses both `is_night()` and direct `world_time` for lighting, waves and arrival spacing | Update every owning path together; preserve active-world/journey guards |
| `scripts/data/mission_db.gd`, `scripts/ui/tutorial_guide.gd` | Separate day/night lessons; some explicitly wait for dawn/night | Prevent real-world mode from forcing a player to wait hours to progress |
| `scripts/world/resident.gd` | Night blocks builder work | Night-only players need an explicit gameplay policy |
| `addons/pb_hms_scan/export_plugin.gd` | Removes INTERNET, network state and Wi-Fi state permissions | Revise the shared manifest policy before integrating location; a second plugin cannot assume those permissions survive |

`world_time` also measures seconds between arrivals and indexes saved pending
batches. Replacing it with Unix time, multiplying it by a daily ratio, or making
it jump to a real-clock value can break arrival pacing and save sanitization.
Keeping `night_number()` on its current six-minute calculation while using real
night for `is_night()` can also repeatedly authorize fresh waves in one real night.

## Proposed implementation design

1. Extend the Godot v2 Android integration with a separate Location provider.
   Add the verified Location dependency and AGC configuration without changing
   the package/signing identity. Keep Scan Kit's independent QR behavior intact.
2. Offer a Settings choice: Classic or Real-world. Explain the use of approximate
   location before invoking Android's permission prompt. Keep native SDK and
   account configuration details out of the player-facing flow.
3. Return a validated location result asynchronously to Godot. Retain request
   ownership/cancellation tokens so callbacks after hide, world handoff or free
   cannot act on retired UI/world objects.
4. Compute an environment sample locally: source, validity, phase, daylight
   blend, sunrise/sunset instants and next transition. Refresh on resume and
   at a practical local interval, not through per-frame positioning calls.
5. Let GameState accept the sample and own gameplay phase transitions. Preserve
   accumulated simulation seconds for combat, recovery, work and arrival timers.
   Give waves a persistent phase identity with defaults, sanitization and legacy
   migration; reconcile it with existing `home_wave` and pending-arrival records.
6. Feed lighting, lanterns, HUD clock and gameplay from that same accepted phase.
   Change HUD copy to local time/next sunrise or sunset; the current 3-minute
   countdown is invalid in Real-world mode.
7. On return after hours/days, reconcile to the present phase once. Do not
   simulate missed attacks, destroy the forest while the game was closed or
   deliver every missed night's waves. Preserve deduplication on reload and
   do not treat crossing midnight as the beginning of another night.
8. Cache only what is necessary. Prefer memory-only exact coordinates; any
   persisted approximate region/fallback needs a clear lifetime and delete path.
   Do not log coordinates or bundle them into saves or QR messages by default.

These are proposals, not implemented contracts. The phase, wave and tutorial
rules need to be resolved together before enabling this by default.

## Gameplay decisions to resolve

- A genuinely synchronized world may remain day or night for an entire play
  session. Changing its length is an intended effect, but existing tutorial waits
  and daytime-only work would become much longer.
- Recommended initial design: optional Real-world mode with a tutorial that can
  progress in either phase and an explicit accessible path for repairs. Classic
  remains available. A visuals-only mode is possible but must be labeled clearly
  because it does not synchronize gameplay rules.
- New journeys opened at night need a safe introductory grace period without
  pretending it is daylight. Location failure should show a source/fallback
  state and should not repeatedly switch phases or request permission.
- Cinematics can defer visible phase changes until their normal handoff; manual
  pause must not advance simulation timers. On resume, synchronize the external
  environment without spawning duplicate enemies.

## Verification required before delivery

- Solar fixtures: Malaysian coordinates, opposite hemispheres/seasons, before
  sunrise/after sunset, civil twilight, midnight, DST, date line and polar cases.
- Location: valid cache, null/stale result, denied/permanently denied permission,
  approximate-only access, settings disabled, timeout, no service/HMS Core,
  background cancellation, permission downgrade/process restart and late callback.
- Clock integration: one phase owner, consistent light/lantern/HUD/gameplay,
  existing timers keep their intended second durations and developer freeze works.
- Persistence: old saves migrate; repeated reloads in one real night do not
  duplicate waves; returning after days does not replay missed destruction.
- Progression: new journey at night, both tutorial phase lists, builder work,
  emergency combat, stories, recovery, ocean/return and developer test sessions.
- Android export: AGC identity/signature match, resolved dependency graph,
  permissions in the merged manifest, both ARM ABIs, 16 KB compatibility and
  real-device execution. Do not transplant old demo Gradle/SDK versions.
- Run the isolated full gameplay gate and focused captures at 832x480/1280x720
  after implementation. No new gameplay gate was needed for this research-only
  document; no Location Kit runtime test is claimed.

## Alternatives if developer verification must remain unnecessary

| Approach | Real geographical sunrise/sunset? | Huawei developer setup? |
| --- | --- | --- |
| HUAWEI Location Kit + local solar calculation | Yes, from obtained coordinates | Required by Huawei's documented setup |
| Android platform location + local solar calculation | Yes, with location permission and a usable provider | No Huawei account; this is not an HMS Location Kit integration |
| Manually chosen region + local solar calculation | Yes, for the selected place | No Huawei account or device-location request |
| Phone clock + fixed day/night hours | Approximation only | No Huawei account or device-location request |

## References and evidence limits

Primary sources were used for API, account, permission, astronomy and pricing
claims. Several Huawei documentation routes returned timeouts or a JavaScript
shell in the research tool. Search-indexed official content and the directly
readable official GitHub sample corroborate setup requirements. A working sample
repository is included below so the result does not depend on a broken Learn
more button. A declared SDK version was not selected: Huawei's Maven metadata
response listed only an old 6.0.0.302 entry, inconsistent with its own sample's
6.12.0.300 dependency, so it must not be treated as a latest-version source.

Huawei's HMS Toolkit page has an overseas sunset notice for 2026-12-30. That is
a notice about the IDE toolkit, not evidence that Location Kit itself is ending.
Use direct SDK/Gradle integration rather than depending on that wizard. [14]

1. [Huawei Location Kit preparation/account guide](https://developer.huawei.com/consumer/en/doc/HMS-Plugin-Guides-V1/config-agc-0000001050142221-V1)
2. [Official Location Kit Android sample and README](https://github.com/HMS-Core/hms-location-demo)
3. [Huawei Android Location Kit codelab](https://developer.huawei.com/consumer/en/codelab/HMSLocationKit/index.html)
4. [Official request/settings/cancellation example](https://github.com/HMS-Core/hms-location-demo/blob/master/locationkit-java-sample/app/src/main/java/com/huawei/locationsample6/location/fusedlocation/RequestLocationUpdatesWithCallbackActivity.java)
5. [Official last-location example](https://github.com/HMS-Core/hms-location-demo/blob/master/locationkit-java-sample/app/src/main/java/com/huawei/locationsample6/location/fusedlocation/GetLastLocationActivity.java)
6. [Huawei Location Kit FAQ](https://developer.huawei.com/consumer/ru/doc/HMSCore-Guides/faq-0000001050986161)
7. [Android runtime permissions and approximate location](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime)
8. [Android foreground/background location definitions](https://developer.android.com/develop/sensors-and-location/location/permissions)
9. [Official sample manifest](https://github.com/HMS-Core/hms-location-demo/blob/master/locationkit-java-sample/app/src/main/AndroidManifest.xml)
10. [US Naval Observatory: rise, set and twilight definitions](https://aa.usno.navy.mil/faq/RST_defs)
11. [SunCalc API, conventions and polar cases](https://github.com/mourner/suncalc/blob/master/README.md)
12. [SunCalc license](https://github.com/mourner/suncalc/blob/master/LICENSE)
13. [Huawei Location Kit pricing](https://developer.huawei.com/consumer/en/doc/HMSCore-Guides/pricing-0000001061986005)
14. [Huawei HMS Toolkit Location integration and sunset notice](https://developer.huawei.com/consumer/es/doc/Tools-Guides/location-integration-0000001136021561)
