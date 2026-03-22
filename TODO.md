# Audio, Sensor & System Fix TODO + Play Integrity Integration
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)  
**Last updated:** 2026-03-15 (session 24 → P42 black-screen + drain regression P0 OPEN; userdebug build compiling for debug capture)
**Branch:** `a16-bringup-fixes`

> `✅ FIXED` = verified correct in the current tree (file read or ADB confirmed).
> `🔴 OPEN` = known bug, actionable fix listed.
> `🟡 OPTIONAL` = low-priority, won't block audio/sensor function.

---

## SESSION 24+ ACTION PLAN

> **P42 FIXED** (2026-03-15) — PPR property disabled; black-screen + drain resolved by user.
> **All P0/P1 blockers are now clear.** Next work is Play Integrity.

### Step 1 — Play Integrity Phase 1 (CURRENT BLOCKER)

See **PLAY INTEGRITY INTEGRATION PLAN** section below for full detail.
Quick implementation path:
```bash
# 1. Verify current build fingerprint spoof is active
adb shell getprop ro.build.fingerprint
# Expected: OnePlus/OnePlus8Pro/OnePlus8Pro:13/RKQ1.211119.001/...release-keys

# 2. Add Phase 1 properties to device/oneplus/instantnoodlep/system.prop
#    (ro.product.first_api_level=29, ro.com.google.gmsversion=gms_20_202009, etc.)
# 3. Rebuild + flash vendor
# 4. Test Play Integrity API response (expect MEETS_DEVICE_INTEGRITY minimum)
```

---

### Step 3 — Release Gate (after Phase 1 validated)

1. Clean flash of signed `user` build
2. SetupWizard completes without error
3. Call audio: earpiece + speaker + mic both directions
4. Fingerprint: enroll + unlock passes
5. Camera: photo + video quick pass
6. WiFi + LTE + Bluetooth quick pass
7. Play Integrity + target banking app smoke test
8. Sign + package OTA + ship

---

### Backup Routine (run BEFORE any flash)

```bash
# 1. Note the active slot — flash to the INACTIVE slot
adb shell getprop ro.boot.slot_suffix    # e.g. "_a" means flash to _b

# 2. Pull WiFi config if you want to restore networks
adb pull /data/misc/wifi/WifiConfigStore.xml /tmp/wifi_backup_$(date +%Y%m%d).xml

# 3. Snapshot props + boot reason for pre-flash baseline
adb shell getprop                         > /tmp/preflash_props_$(date +%Y%m%d_%H%M%S).txt
adb shell 'getprop ro.boot.bootreason; cat /sys/power/pon_reason; cat /sys/power/poff_reason' \
                                          > /tmp/preflash_boot_reason_$(date +%Y%m%d_%H%M%S).txt

# 4. Capture logcat baseline
adb logcat -b all -d -v threadtime        > /tmp/preflash_logcat_$(date +%Y%m%d_%H%M%S).txt

# 5. Note current build fingerprint
adb shell getprop ro.build.fingerprint
adb shell getprop ro.build.version.release
```

---

## STATUS SUMMARY

| # | Subsystem | Issue | Priority | Status |
|---|-----------|-------|----------|--------|
| 1 | Init | `init.instantnoodlep-bringup.rc` added to `PRODUCT_COPY_FILES` | **P0** | ✅ FIXED |
| 2 | Init | `sensor_recover.sh` added to `PRODUCT_COPY_FILES` + called from bringup RC | **P0** | ✅ FIXED |
| 3 | Init | `zz_vendor.touch-hal.override.rc` added to `PRODUCT_COPY_FILES` | P1 | ✅ FIXED |
| 4 | Init | `zz_audio_prop_migration.rc` added to `PRODUCT_COPY_FILES` | P1 | ✅ FIXED |
| 5 | Audio | `audio_platform_info_intcodec.xml` → correct path `audio_platform_info.xml` | **P0** | ✅ FIXED |
| 6 | Audio | Makefile comment bug — `audio_policy_configuration.xml`, `audio_io_policy.conf`, `audio_tuning_mixer.txt` missing from vendor | **P0** | ✅ FIXED |
| 6a | Audio | `external_speaker.enable` + `external_speaker_tfa.enable` both `false` in `vendor.prop` | **P0** | ✅ FIXED |
| 7 | Audio | `persist.vendor.audio.speaker.prot.enable false` in both RCs — TFA calibration blocked | **P0** | ✅ FIXED |
| 8 | Sensors | All 56 sensors confirmed live — lsm6dsm, mmc5603x, tcs3701, stk2232, OPlus custom, SAR, pedometer | **P0** | ✅ DONE |
| 9 | SELinux | `vendor_hal_oplus_sensor_default.te` type + allow rule for `oplus_sensor_devinfo` | P1 | ✅ FIXED |
| 10 | System | `lpm_levels.sleep_disabled=1` in kernel cmdline — CPU power states disabled | P1 | ✅ FIXED |
| 11 | Audio | `vendor.audio.feature.spkr_prot.enable` set to `false` in `vendor.prop` — regression | **P0** | ✅ FIXED |
| 12 | Audio | TFA9874 kernel DT `tfa_use_i2s` absent at probe — DAI links registered correctly via `extend_codec_be_dailink`; audio plays; non-issue | **P0** | ✅ NON-ISSUE |
| 13 | Audio | WSA DAPM route failures at boot — 4 unknown pins: `SpkrLeft IN`, `SpkrLeft SPKR`, `SpkrRight IN`, `SpkrRight SPKR` | P2 | 🟡 COSMETIC |
| 14 | Audio | `audio_io_policy.conf` dead 24-bit profiles — all preprocessor guards removed | P2 | ✅ FIXED |
| 15 | SELinux | `/dev/oplus_sensor_devinfo` unlabeled (`file_contexts` untracked) | P2 | ✅ FIXED |
| 16 | Audio | QCOM `libspkrprot` opens PCM device 25 (missing) — blocked `enable_snd_device` | **P0** | ✅ FIXED (Option A: `spkr_prot.enable=false`, confirmed session 5) |
| 17 | SELinux | `shell.te`, `tri-state-key-calibrate.te`, `vendor_qti_init_shell.te` untracked | P2 | ✅ FIXED |
| 18 | Audio | `Audio Stream Capture 32 App Type Cfg` mixer ctrl missing — VI hostless app_type ctl not registered; ACDB still applies calibration | P3 | 🟡 COSMETIC |
| 19 | Audio | `volume_listener: Failed to set gain dep cal level` → `out_write: retry` on each playback start | P3 | 🟡 COSMETIC |
| 20 | Kernel | `oplus,dac-vendor` DT property absent in `oplus,audio-drv` node | P3 | 🟡 COSMETIC |
| 21 | Kernel | `No DT match for tdm max slots` — falls back to default 8; correct for this device | P3 | 🟡 COSMETIC |
| 22 | Fingerprint | UDFPS HBM UI-ready handshake broken — root cause was stale invalid `/dev/oplus_display` fd in `@2.3` bridge; fixed by runtime fd reopen + HBM path replay | **P0** | ✅ FIXED (validated 2026-03-11) |
| 23 | Call Audio | In-call earpiece/speaker playback silent — `voicemmode1-call` entered, but HAL previously failed opening missing PCM 44 due internal-codec platform-info filename mismatch | **P0** | ✅ FIXED (validated 2026-03-10; handset now routes to top earpiece) |
| 24 | Call Audio | In-call microphone dead — same failed voice session startup as P23 prevented uplink voice path bring-up | **P0** | ✅ FIXED (validated 2026-03-10) |
| 25 | Audio | Internal-codec HAL expects `/vendor/etc/audio_platform_info_intcodec.xml`; build shipped only `/vendor/etc/audio_platform_info.xml`, so `VOICEMMODE1_CALL` falls back to default PCM IDs 44/45 (missing on this kernel) | **P0** | ✅ FIXED (session 9 + session 11 validation) |
| 26 | Power | Sleep of Death (SoD) — massive battery drain / phone does not wake from deep sleep | **P0** | ✅ FIXED (2026-03-13: overnight deep sleep confirmed stable by user) |
| 32 | SELinux | `rild` denied write to `system_data_root_file` + read on `cache_file` + read `default_prop` — RIL init probes only; no call impact | P2 | ✅ FIXED (log-cleanup policy applied; no AVC in boot capture 2026-03-12) |
| 33 | SELinux | `vendor_init` denied `{ set }` on `vendor_persist_camera_prop` (`vendor.camera.aux.packageexcludelist`) — camera aux exclusion list not set at boot | P2 | ✅ FIXED (no AVC in boot capture 2026-03-12) |
| 34 | SELinux | `init` denied `{ transition }` to `vendor_shell` domain for `sensor_recover.sh` — sensor recovery script may not execute at boot | P2 | ✅ FIXED (no transition AVC in boot capture 2026-03-12; sensor persist tree present) |
| 35 | SELinux | `vendor_pd_mapper` denied `{ read }` on `system_prop` — PD mapper property probe | P2 | ✅ FIXED (policy/log cleanup validated in boot capture 2026-03-12) |
| 36 | WiFi | `cnss: Failed to load BDF: qca6390/regdb.bin` — regulatory DB binary missing | P2 | ✅ FIXED (`/vendor/firmware/qca6390/regdb.bin` found + BDF download size 19348 in boot capture 2026-03-12) |
| 37 | WiFi | `cnss: Coex antenna switch_to_mdm resp wait failed -22` — antenna switch coex timeout; may affect WiFi+LTE coexistence in edge cases | P2 | ✅ CONFIRMED CLEAN (2026-03-12 session 17; wlan0 + rmnet_data1 both routing with active SIM/LTE; no timeout error) |
| 38 | Camera | `CAM-OIS: get download,fw failed rc=-22` — legacy boot log from missing OIS DT property `download,fw` (not missing `/odm/firmware` blob) | P3 | ✅ FIXED (2026-03-13: dmesg now shows `read download,fw success, value:1` for both OIS nodes) |
| 39 | Display | Settings UI text overlapping / garbled — display HAL reported 560 DPI via `displayconfig` XML (`display_id_4630947194340276609.xml`), overriding `ro.sf.lcd_density`; at 560 DPI only 411dp screen width → layout compression | P1 | ✅ FIXED (2026-03-12 session 17; 1440p density 560→420 + 1080p 450→420 in `configs/display_id_4630947194340276609.xml`; `TARGET_SCREEN_DENSITY` 450→420 in `BoardConfig.mk`; verified Physical density: 420 on device) |
| 40 | Stability | User-reported app-switch reboot (YouTube → Photos) not reproducible in live capture; no fresh tombstones/dropbox native-crash records; boot reason remains KPD-triggered cold reboot | P2 | 🟡 MONITOR (session 19 re-check clean) |
| 41 | Release | Shipping recovery path was disabled (`TARGET_NO_RECOVERY` + `AB_OTA recovery` filter); no fresh `recovery.img` could be produced for fastboot users | P1 | ✅ FIXED (session 20: recovery build re-enabled + live flash validation) |
| 42 | Power/Display | Black-screen + severe idle drain regression — device enters black state with heavy battery drain; requires Vol+ + Power ~15 s combo to recover | **P0** | ✅ FIXED (2026-03-15: disabled PPR property that was causing the black-screen; validated by user) |
| 27 | SELinux | `hal_power_default` denied `{ read }` on `idle_state` sysfs node labeled `vendor_sysfs_graphics` — Power HAL can't read GPU/display idle state | **P0** | ✅ FIXED (validated 2026-03-11) |
| 28 | SELinux | `hal_lineage_health_default` denied `{ search/write }` on `vendor_sysfs_usb_supply` (`oplus_chg`) — Lineage Health HAL charging node access blocked | P1 | ✅ FIXED (validated 2026-03-11) |
| 29 | SELinux | `vendor_hal_oplus_sensor_default` denied search/write on `vendor_proc_oplus_als_file` + `vendor_proc_eng_cali_file` — ALS + pressure calibration access blocked | P2 | ✅ FIXED (validated 2026-03-11) |
| 30 | Bluetooth | `com.android.bluetooth` SIGABRT in `bt_stack_manage` during GD shutdown — `pthread_mutex_lock` on destroyed mutex in `Handler::~Handler()` / `Stack::Stop()` race — BT APEX/module race | P2 | 🟡 MONITOR (module-level fix in tree; 8x enable/disable stress on 2026-03-13 had no SIGABRT/FORTIFY crash) |
| 31 | SELinux | `vendor_poweroffalarm_app` + `vendor_wcnss_service` denied property set path (`property_socket`/`property_service`) — alarm + WiFi daemon property writes blocked | P2 | ✅ FIXED (validated 2026-03-11) |

---

## SENSOR STATUS — COMPLETE ✅

Live ADB check (`dumpsys sensorservice`) confirms **Total 56 h/w sensors, 56 running**:

| Sensor | Chip | Status |
|--------|------|--------|
| Accelerometer (wakeup + non-wakeup) | STMicro LSM6DSM | ✅ |
| Gyroscope (wakeup + non-wakeup + uncal) | STMicro LSM6DSM | ✅ |
| Magnetometer (wakeup + non-wakeup + uncal) | Memsic MMC5603X | ✅ |
| Ambient Light Sensor | AMS TCS3701 | ✅ |
| Proximity (wakeup) | Sensortek STK2232 | ✅ |
| SAR / WiFi RF | SX9324UP | ✅ |
| Step counter/detector, Tilt, Significant motion | OPlus (SSC) | ✅ |
| OPlus custom (AMD, elevator, OCA, infrared) | OPlus multihal | ✅ |
| Rear camera ALS/RGB/flicker | AMS TCS3408 | ✅ |
| UDFPS sensor | (`org.lineageos.sensor.udfps`) | ✅ |

**Shake control:** `sns_multishake.json` deployed with correct soc_id=356. `com.android.touch.gestures` is running. Works after enabling in Settings.

**No further sensor work needed.**

---

## AUDIO STATUS — **SPEAKER WORKING** ✅ (session 5 confirmed)

**Session 5 ADB verification:**
- `tfa_dev_start success (0)` on both TFA9874 chips (I2C 0x34 + 0x35) ✅
- Calibration values applied: 0x35 = 6023 mΩ, 0x34 = 6294 mΩ (both within 5000–8000 mΩ limit) ✅
- `hw_params: Requested rate: 48000, sample size: 24, physical size: 32` — 24-bit 48kHz active ✅
- `send_app_type_cfg PLAYBACK app_type 69936` — `deep_buffer_24` profile selected ✅
- `enable_snd_device: snd_device(2: speaker)` + `snd_device(217: vi-feedback)` — correct path ✅
- No `spkr_prot_start_processing` errors — P16 fix confirmed ✅
- No SELinux AVC denials for audio ✅

Remaining issues are all cosmetic (P13, P18–P21) — they log at boot or on first write but do not prevent audio from playing.

---

### PROBLEM 11 — `vendor.audio.feature.spkr_prot.enable=false` (regression) ✅ FIXED

**File:** `sm8250-common/vendor.prop`  
**Fix applied:** `vendor.audio.feature.spkr_prot.enable=false` → `true`  
**Confirmed on device (session 3):** `[vendor.audio.feature.spkr_prot.enable]: [true]` ✅

> **NOTE:** Enabling `spkr_prot` surfaced a new problem — see **Problem 16**. With `spkr_prot=true` the QCOM `libspkrprot` tries to open PCM device 25 for VI-feedback TX, which doesn't exist on this kernel. Turning this flag on moved the failure from "library not loaded" to "PCM open error", which gave us the precise root cause.

---

### PROBLEM 12 — TFA9874 DT `tfa_use_i2s` absent ✅ NON-ISSUE

**Original theory:** Missing DT property would cause TFA chips to bind to PRIMARY I2S while HAL routes TERT_MI2S → no audio.

**Session 5 outcome:** Audio plays correctly. Investigation shows the `tfa_use_i2s` log message ("no defined tfa_use_i2s, use primary i2s") only appeared at the very first cold boot (January timestamps). On subsequent boots the `extend_codec_be_dailink` mechanism registers `tfa98xx-aif-2-34` and `tfa98xx-aif-2-35` DAI links correctly against TERT_MI2S regardless of the DT property. `tfa_dev_start success (0)` on both chips confirms the codec DAI is live on the correct bus.

**No kernel DT change needed.**

---

### PROBLEM 13 — WSA DAPM route failures at boot 🟡 COSMETIC

**Evidence (every boot):**
```
E tfa98xx 2-0035: ASoC: unknown pin SpkrRight IN
E tfa98xx 2-0035: ASoC: unknown pin SpkrRight SPKR
E tfa98xx 2-0034: ASoC: unknown pin SpkrLeft IN
E tfa98xx 2-0034: ASoC: unknown pin SpkrLeft SPKR
E bolero-codec: ASoC: unknown pin WSA AIF VI
```

The kona machine driver registers DAPM routes for WSA smart amplifier (QCOM-native amp on reference designs). OnePlus 8 Pro has TFA9874 — its DAPM outputs are named differently and don't expose `SpkrLeft IN`, `SpkrLeft SPKR`, `SpkrRight IN`, `SpkrRight SPKR`, or `WSA AIF VI`. These routes simply fail to connect at probe time.

**Session 5 confirmation:** Audio plays perfectly despite these errors. The TERT_MI2S backend PCM path does not require these WSA DAPM routes to be resolved. The kona machine driver falls back gracefully.

**Not worth fixing** unless logspam becomes a specific issue (would require a kernel patch to guard WSA route registration behind a DT flag).

---

### PROBLEM 14 — `audio_io_policy.conf` preprocessor guards ✅ FIXED (fully cleaned session 4)

**File:** `sm8250-common/audio/audio_io_policy.conf`  
**Fix applied (session 3):** `#ifdef OPLUS_FEATURE_PLAYBACK_24BIT` / `#endif` guards removed from output section  
**Fix applied (session 4):** All remaining guards in input section also removed:  
- 3× `#ifndef OPLUS_BUG_COMPATIBILITY` / `#else` / `#endif` blocks (sampling-rate list alternates in `record_16bit`, `record_24bit`, `record_32bit`)  
- 1× `#ifdef OPLUS_ARCH_EXTENDS` block (entire `record_compress_16/24/32` profiles hidden)  
- 1× stray `#endif/* OPLUS_ARCH_EXTENDS */`  

Remaining `#` lines are editorial comments only (file header, engineer change-marks). Zero preprocessor guards remain. `record_compress_*` profiles and correct sampling-rate sets are now unconditionally visible to the HAL parser.

---

### PROBLEM 16 — QCOM `libspkrprot` opens PCM device 25 (missing) ✅ CONFIRMED FIXED (session 5)

**Root cause (session 3):** With `spkr_prot.enable=true`, QCOM `libspkrprot` tried to open `pcmC0D25c` (hardcoded default, doesn't exist on this kernel). This blocked `enable_snd_device` → complete silence.

**Fix (session 4):** `vendor.audio.feature.spkr_prot.enable=false` in `sm8250-common/vendor.prop` — QCOM `libspkrprot` disabled; TFA HAL handles speaker protection via `pcm_dev_tx_id=32`.

**Session 5 ADB confirmation:**
- No `spkr_prot_start_processing` errors in logcat ✅
- `enable_snd_device: snd_device(2: speaker)` succeeds ✅
- `tfa_dev_start success (0)` both chips ✅
- Audio heard from speaker ✅

**Prop disambiguation:**

| Property | Value | Purpose |
|----------|-------|---------|
| `vendor.audio.feature.spkr_prot.enable` | `false` | QCOM `libspkrprot` gate — **must be false** on TFA devices |
| `persist.vendor.audio.speaker.prot.enable` | `true` | TFA HAL calibration data flag — **must be true** |

---

### PROBLEM 18 — `Audio Stream Capture 32 App Type Cfg` mixer control missing 🟡 COSMETIC

**Evidence:** `E audio_hw_utils: send_app_type_cfg_for_device: Could not get ctl for mixer cmd - Audio Stream Capture 32 App Type Cfg`

The HAL tries to set `app_type` on PCM device 32 (VI-hostless hostless capture, `in_snd_device vi-feedback`). The corresponding ALSA mixer control `Audio Stream Capture 32 App Type Cfg` is not registered by this kernel. The HAL logs an error but continues; ACDB calibration (acdb_id=102, app_type=69938) is still loaded via a separate path.

**Impact:** None. Speaker audio plays correctly. ACDB is applied.

---

### PROBLEM 19 — `volume_listener: Failed to set gain dep cal level` 🟡 COSMETIC

**Evidence:** `E volume_listener: check_and_set_gain_dep_cal: Failed to set gain dep cal level`  
Followed by: `D audio_hw_primary: out_write: retry previous failed cal level set` on first write

The `volume_listener` extension tries to set gain-dependent calibration level via a mixer control that doesn’t exist for the VI-feedback hostless path. The HAL retries once on the next `out_write`, which succeeds. No audible effect.

**Impact:** One extra `out_write` retry per playback session start. Cosmetic log noise.

---

### PROBLEM 20 — `oplus,dac-vendor` DT property absent 🟡 COSMETIC

**Evidence:** `W extend_codec_prop_parse: Looking up 'oplus,dac-vendor' property in node oplus,audio-drv failed`

The OPlus audio driver DT node `oplus,audio-drv` is missing the optional `oplus,dac-vendor` property. The driver uses it to detect a dedicated external DAC. OnePlus 8 Pro has no such DAC chip; the Snapdragon internal WCD940x is used. Driver falls back to default.

**Impact:** None. Internal codec path works correctly.

---

### PROBLEM 21 — `No DT match for tdm max slots` 🟡 COSMETIC

**Evidence:** `E kona-asoc-snd: msm_asoc_machine_probe: No DT match for tdm max slots` → `Using default tdm max slot: 8`

The kona machine driver probes for a DT property specifying TDM max slots for this board. The OnePlus 8 Pro DT doesn’t set it; the driver defaults to 8 which is correct for the TERT_MI2S 8-slot TDM configuration in use.

**Impact:** None.

---

### PROBLEM 22 — UDFPS HBM UI-ready handshake ✅ FIXED (validated 2026-03-11)

**Evidence (live logcat during enrollment attempt, session 6):**
```
E [GF_HAL][CustomizedFingerprintCore]: [onBeforeEnrollCapture] exit. err=GF_ERROR_UI_READY_TIMEOUT, errno=1143
E FingerprintCallback: sendUdfpsPointerDown, callback null
E FingerprintCallback: sendUdfpsPointerUp, callback null
W UdfpsDisplayMode: disable | onDisabled is null
E BufferQueueProducer: SurfaceView[UdfpsControllerOverlay]... disconnect: not connected
I auditd: avc: denied { set } for property=vendor.calibration.fingerprint
         scontext=u:r:hal_fingerprint_default:s0 tcontext=u:object_r:vendor_default_prop:s0
```

**What works:**
- `fps_hal` + `android.hardware.biometrics.fingerprint@2.3-service.oplus` running ✅
- Touch detection: HAL receives `onFingerDown` / `onTouchDown` on every touch ✅
- No `GF_ERROR_OPEN_DEVICE_FAILED` — `/dev/goodix_fp` accessible ✅
- SELinux `vendor_proc_display` + `tee_bind_core` from Issues 146–150 still present ✅

**What breaks:**
1. **`FingerprintCallback` is null** — the HIDL bridge service (`@2.3`, pid 988) has no callback object from SystemUI registered. UDFPS pointer-down/up events cannot be forwarded to trigger HBM.
2. **`UdfpsDisplayMode.onDisabled` is null** — SystemUI `UdfpsController` never successfully registers an HBM enable/disable callback. The display illumination for the FOD area never fires.
3. **HAL times out** — Goodix HAL waits ~500 ms for a "UI ready" confirmation (display HBM active + frame ready). Never gets it → `GF_ERROR_UI_READY_TIMEOUT` (errno 1143).
4. **`vendor.calibration.fingerprint` AVC** — HAL tries to write calibration data to an untyped `vendor_default_prop`. Needs dedicated property type.

**Root cause:** A16 PixelOS changed the UDFPS callback registration path vs A13. The Goodix blob expects `FingerprintCallback` injected via the `vendor.oplus.hardware.biometrics.fingerprint@2.1` HIDL interface. `UdfpsController` in A16 wires this differently — the SystemUI→HAL HBM ready callback is not being registered, so HAL never learns when the display illuminated.

Note: `libudfps_extension.oplus` static lib IS present in source (`hardware/oplus/fingerprint/`) and is referenced by `soong_config_set,surfaceflinger,udfps_lib` in `common.mk`. SurfaceFlinger Z-order side is likely fine. The break is in the SystemUI HBM signalling path.

**Candidate fixes (in priority order):**

1. **Fix `vendor.calibration.fingerprint` property AVC** (quick, isolated):
   - `device/oneplus/instantnoodlep/sepolicy/vendor/property.te`: add `type vendor_calibration_fingerprint_prop, vendor_default_prop;`
   - `device/oneplus/instantnoodlep/sepolicy/vendor/property_contexts`: add `vendor.calibration.fingerprint u:object_r:vendor_calibration_fingerprint_prop:s0`
   - `device/oneplus/instantnoodlep/sepolicy/vendor/hal_fingerprint_default.te`: add `set_prop(hal_fingerprint_default, vendor_calibration_fingerprint_prop)`

2. **Check SystemUI `UdfpsController` and `UdfpsDisplayModeProvider`** — verify A16 PixelOS SystemUI properly calls `setCallback` on `IBiometricsFingerprint` (HIDL v2.1/2.3). Compare with another working PixelOS A16 device that uses UDFPS (e.g. OnePlus 9 Pro `lemonadep`).

3. **Check HIDL bridge blob compatibility** — `android.hardware.biometrics.fingerprint@2.3-service.oplus` is from A13 blobs. It bridges between the framework and the Goodix `@2.1` HAL. In A16 the callback interface may have changed. Look for a more recent blob or a shim.

4. **Review `hardware/oplus/fingerprint/` UdfpsExtension** — confirm SurfaceFlinger was built with it by checking `ro.vendor.build.fingerprint` vs any SF log output, or dumpling SF binary symbols for `getUdfpsZOrder`.

**Session 12/13 final root cause + fix (2026-03-11):**
- Added targeted runtime diagnostics in `hardware/oplus/hidl/fingerprint/BiometricsFingerprint.*`.
- Captures showed all panel ioctls were skipped because the bridge held an invalid `/dev/oplus_display` fd (`fd < 0`) during enrollment.
- Root cause: fd was opened only once at service start; if node was unavailable at that instant, it stayed invalid forever.
- Implemented lazy reopen logic (`ensureDisplayFd()`) so each panel ioctl path can recover and open `/dev/oplus_display` at runtime.
- Kept HIDL onUiReady replay in framework (`HidlToAidlSessionAdapter`) and panel HBM/dimlayer/fp-press signaling in bridge.

**Validation after fix (`logs/fingerprint_fd_reopen_test_20260311_145346_60s.txt`):**
- `Opened /dev/oplus_display fd=7` observed ✅
- `Failed to open /dev/oplus_display`: `0`
- `invalid /dev/oplus_display`: `0`
- `GF_ERROR_UI_READY_TIMEOUT`: reduced to `3` (from large repeated loops)
- Enrollment reached finish state: `onEnrollResult(... rem=0)` + `FingerprintEnrollFinish` activity shown ✅
- User confirmation: fingerprint enrollment works ✅

**Residual non-blocking warnings:**
- `FingerprintCallback ... callback null` remains during enroll/auth transitions (framework-side callback path behavior), but no longer blocks enrollment completion.
- Occasional `GF_ERROR_UI_READY_TIMEOUT` can still appear during later auth probes; monitor only if user-visible failures return.

---

### PROBLEM 23 — In-call audio playback silent ✅ FIXED (validated 2026-03-10)
### PROBLEM 24 — In-call microphone dead (remote hears nothing) ✅ FIXED (validated 2026-03-10)

> P23 and P24 are treated together — both symptoms share the same root cause: the voice call audio path through the QCOM Q6/VoiceMMode HAL is not being established when a phone call connects.

**Symptoms confirmed by user (session 7):**
- Earpiece (and speaker) produce no sound during active phone calls ← P23
- Remote party hears nothing — microphone audio does not reach the modem ← P24
- Normal media playback: works ✅ (P16 fix confirmed, TFA9874 active)
- Normal recording/mic: works ✅ (TX_CDC_DMA_TX_3 interface accessible)
- The failure is call-specific, not a codec or SELinux issue at the device level

**Session 8 repro evidence (60s focused log):**
- `voice_start_usecase: enter usecase:voicemmode1-call` appears repeatedly ✅
- Route application happens: `enable_audio_route: ... voicemmode1-call` + `Apply path: voicemmode1-call` ✅
- Then hard failure: `E voice: voice_start_usecase: cannot open device 44 for card 0: No such file or directory` ❌
- Follow-up failure: `E voice_extn: update_calls: voice_start_usecase() failed for usecase: 41` ❌
- Summary counts from capture: device 44 open failures = 10, `adev_create_audio_patch` failures = 5, missing device 16 opens = 52.

**In-call audio architecture on this device (from config analysis, session 7):**

| Path | Backend | Notes |
|------|---------|-------|
| Earpiece RX (`voicemmode1-call`) | `TERT_MI2S_RX` (→ TFA bus) | Unusual — earpiece is on TFA TERT_MI2S_RX, not `RX_CDC_DMA_RX_0` |
| Headphones RX (`voicemmode1-call headphones`) | `RX_CDC_DMA_RX_0` | Internal WCD codec |
| Microphone TX (`voicemmode1-call`) | `TX_CDC_DMA_TX_3` | Internal WCD DMA TX — same as normal recording |
| Mixer controls (earpiece) | `TERT_MI2S_RX_Voice Mixer VoiceMMode1` = 1 | set in `mixer_paths.xml` |
| Mixer controls (mic) | `VoiceMMode1_Tx Mixer TX_CDC_DMA_TX_3_MMode1` = 1 | set in `mixer_paths.xml` |

**What is confirmed present:**
- `voicemmode1-call` mixer paths exist in `mixer_paths.xml` ✅
- `SND_DEVICE_OUT_VOICE_HANDSET` → `TERT_MI2S_RX` interface mapping in `audio_platform_info_intcodec.xml` ✅
- `SND_DEVICE_IN_VOICE_DMIC` → `TX_CDC_DMA_TX_3` interface mapping ✅
- IMS daemons present: `imsqmidaemon`, `imsdatadaemon`, `ims_rtp_daemon`, `qcrild` — all have `/vendor/etc/init/*.rc` ✅
- IMS properties: `persist.dbg.volte_avail_ovr=1`, `vt_avail_ovr=1`, `wfc_avail_ovr=1` ✅
- `android.hardware.telephony.ims.xml` declared in `common.mk` ✅
- `vendor.audio.feature.multi_voice_session.enable=true` ✅
- ACDB data for voice paths present: `Handset_cal.acdb`, `General_cal.acdb`, etc. ✅

**Root cause chain (session 8):**

1. `platform.c` internal-codec path calls `platform_info_init(...audio_platform_info_intcodec.xml)` and does **not** fall back to `audio_platform_info.xml` in that branch.
2. Current build ships only `/vendor/etc/audio_platform_info.xml` (from `audio_platform_info_intcodec.xml` source), but not `/vendor/etc/audio_platform_info_intcodec.xml`.
3. With missing internal-codec XML, HAL keeps compile-time defaults from `platform.h`:
   - `VOICEMMODE1_CALL_PCM_DEVICE = 44`
   - `VOICEMMODE2_CALL_PCM_DEVICE = 45`
4. Kernel ALSA card on this device does not expose PCM 44/45, so call startup fails at `voice_start_usecase`, causing both no downlink audio (P23) and no uplink mic path (P24).

**Diagnostic steps (to run on next device session):**

```bash
# 1. During an active call, check if voice mode is set
adb shell getprop | grep audio.mode
adb shell dumpsys audio | grep -E "mode|IN_CALL|setMode"

# 2. Check VoiceMMode mixer state during a call
adb shell tinymix | grep -E "VoiceMMode|TERT_MI2S_RX_Voice|VoiceMMode1_Tx"

# 3. Check HAL logs for voice call setup
adb logcat | grep -E "voice_start_call|start_voice_call|setMode|VoiceMMode|qcrild|AudioFlinger.*mode|in_call"

# 4. Check if qcrild is running and connected
adb shell getprop | grep init.svc.vendor.qcrild
adb shell ps -A | grep qcrild

# 5. Check IMS daemon status
adb shell getprop | grep init.svc.vendor.imsqmidaemon
adb shell getprop | grep init.svc.vendor.imsdatadaemon

# 6. Check for AVC denials on qcrild or audio during call
adb logcat | grep "avc.*audio\|avc.*qcrild\|avc.*imsqmi"
```

**Candidate fixes (in priority order):**

1. **Deploy platform info under both names in vendor** (staged):  
   `device/oneplus/instantnoodlep/device.mk` now copies `audio_platform_info_intcodec.xml` to:
   - `/vendor/etc/audio_platform_info_intcodec.xml`
   - `/vendor/etc/audio_platform_info.xml`
2. Rebuild and flash `vendor.img` (`vendor_b` in fastbootd), then retest call.
3. Verify on-device after flash:
   - `ls /vendor/etc/audio_platform_info*`
   - active call log no longer shows `cannot open device 44`
   - `voice_start_usecase` reaches `pcm_start` and call audio works both directions.
4. If P23/P24 persist after this fix, continue with secondary hypotheses (qcril bridge or TFA call-mode switch).

**Post-fix validation (session 9, flashed `vendor_b`):**
- `/vendor/etc/audio_platform_info_intcodec.xml` now exists on device (same content as `audio_platform_info.xml`).
- Post-fix 60s capture includes call start and shows `voice_start_usecase: exit: status(0)`.
- No occurrences of `voice_start_usecase: cannot open device 44`, `voice_start_usecase() failed for usecase: 41`, `adev_create_audio_patch: Stream routing failed`, or `pcm_open_prepare_helper: cannot open device 16`.
- Remaining step: user subjective validation that in-call downlink + uplink audio are now correct.

**Session 10 follow-up (flashed `vendor_b` + `odm_b` + `boot_b`):**
- User reported microphone works, but in-call downlink is still heard from bottom speaker instead of top earpiece.
- Repro capture still showed mixed TFA profiles during handset route transitions: `2-0035 -> speaker`, `2-0034 -> receiver`.
- Handset mixer path was updated to program both chips to `receiver` (`selector 2 -> receiver`, then `selector 1 -> receiver`) and reflashed, but mixed profile behavior persisted in subsequent call capture.
- Kernel patch added in `tfa98xx_v6.c` to re-evaluate `TFA_CHIP_SELECTOR` on every unmute before deciding which chip to start (boot image rebuilt/flashed to slot `b`).
- Fresh post-kernel-call capture with full call routing logs is still pending (last 60s run captured fingerprint only / insufficient call-audio data).

**Session 11 follow-up (2026-03-09):**
- New hypothesis: DTS uses `qcom,wsa-aux-dev-prefix = "SpkrLeft", "SpkrRight"` so mixer control names may be prefixed; existing unprefixed `TFA_CHIP_SELECTOR` / `stereo Profile` writes can be ignored by HAL route application.
- Updated `device/oneplus/instantnoodlep/audio/mixer_paths.xml` to write both prefixed and legacy control names for `speaker`, `speaker-mono`, `handset`, and test paths (`mmi-*`), with handset forcing selector `1`.
- Rebuilt `vendorimage`; artifact ready at `out/target/product/instantnoodlep/vendor.img` (2026-03-09 17:24 CET).
- Pending: flash `vendor_b` with the standard routine and capture a new 30–45s call repro to verify kernel log moves from `selector:0` to `selector:1` in handset mode.

**Session 11 validation after flash (2026-03-10):**
- Flashed `vendor_b` and captured `45s` call repro:  
  `logs/call_post_vendorflash_2026-03-10_115629_{all,kernel}_45s.txt`
- Kernel now shows selector writes happening:
  - `tfa98xx_set_stereo_ctl: selector = 1` (handset)
  - `tfa98xx_set_stereo_ctl: selector = 3` (speaker)
- Handset mode now correctly deselects bottom amp:
  - `2-0035: selector:1 chip_selected:0`
  - `2-0034: selector:1 chip_selected:1` + `tfa_dev_start success`
- No return of old PCM-open failure (`cannot open device 44`) and voice startup remains `status(0)`.
- User confirmation: top earpiece works after the latest `vendor_b` flash; call audio routing issue resolved.

---

## SENSOR STATUS — COMPLETE ✅

Live ADB check (`dumpsys sensorservice`) confirms **Total 56 h/w sensors, 56 running**.  
All types working: lsm6dsm (accel+gyro), mmc5603x (mag), tcs3701 (ALS), stk2232 (proximity), SX9324UP (SAR), OPlus custom (infrared, elevator, OCA, AMD, pedometer), UDFPS.  
**No further sensor work needed.**

---

---

### PROBLEM 26 — Sleep of Death (SoD) / massive battery drain 🔴 ROOT CAUSE FOUND (2026-03-11)
### PROBLEM 27 — Power HAL `idle_state` SELinux denial ✅ FIXED
### PROBLEM 28 — Health HAL `oplus_chg` sysfs AVC denial ✅ FIXED
### PROBLEM 29 — Sensor ALS/pressure calibration proc AVC denials ✅ FIXED
### PROBLEM 30 — Bluetooth SIGABRT teardown race ✅ FIXED (2026-03-12)
### PROBLEM 31 — `poweroffalarm` + `wcnss_service` property set denials ✅ FIXED

**Symptom:** Phone drains battery very rapidly in standby and/or fails to wake from deep sleep (display stays black, requires hard reboot).

**Diagnostic session 2026-03-11 — root cause confirmed:**

**What was tested:**
- `dumpsys power` — `mWakeLockSummary=0x0`, no user-space wakelock held; `mHalAutoSuspendModeEnabled=false` (normal while plugged in + screen on)
- `dumpsys deviceidle force-idle` → **PASSED** — state machine transitions to `mState=IDLE mLightState=OVERRIDE`; ADB survives; phone recovers cleanly on `unforce`. No kernel panic from forced Doze.
- Crash logcat → **`com.android.bluetooth` SIGABRT** in `bt_stack_manage` thread (`SnoopLogger` double-clear, see P30)
- Kernel logcat → `bq27541_get_gauge_i2c_err gauge_i2c_err=0 suspend=0` flooding at ~5s intervals (225 occurrences) → confirms kernel is NOT entering suspend, this is a symptom not the cause
- `pstore` at `/sys/fs/pstore/` — permission denied without root; cannot read crash logs yet
- SELinux AVC scan → **critical** denial found (P27 below):

```
avc: denied { read } for comm="android.hardwar" name="idle_state" dev="sysfs"
  scontext=u:r:hal_power_default:s0 tcontext=u:object_r:vendor_sysfs_graphics:s0
  tclass=file permissive=0
```

**Root cause:** The `android.hardware.power.IPower/default` AIDL service is registered but returns `FAILED_TRANSACTION` on dump — it is non-functional. The `hal_power_default` domain is denied `{ read }` on the `idle_state` sysfs node (a GPU/display power management node labeled `vendor_sysfs_graphics`) from the very first second after boot (14:53:32). The current `hal_power_default.te` only grants `vendor_proc_display` and `vendor_sysfs_sde_crtc` — `vendor_sysfs_graphics` is absent. Without reading `idle_state`, the Power HAL cannot evaluate GPU/display idle state, which is required before it will signal the kernel to enter auto-suspend. Result: kernel stays in runtime-active → continuous battery drain.

**Current `hal_power_default.te` content (confirmed):**
```
rw_dir_file(hal_power_default, vendor_proc_display)
rw_dir_file(hal_power_default, vendor_sysfs_sde_crtc)
# MISSING: vendor_sysfs_graphics  ← SELinux denial at boot
```

**Fix for P27 (immediate):**
Add one line to `device/oneplus/instantnoodlep/sepolicy/vendor/hal_power_default.te`:
```
r_dir_file(hal_power_default, vendor_sysfs_graphics)
```
Rebuild `vendorimage`, flash `vendor_b`, test: `bq27541 suspend=0` spam should stop when screen goes off, and battery drain rate should drop to normal.

**Additional AVC denials found (separate from P26, catalogued as P28–P31):** See table rows above.

---

---

### PROBLEM 27 — Power HAL `idle_state` SELinux denial (root cause of P26)

**Fix applied:** Added to `device/oneplus/instantnoodlep/sepolicy/vendor/hal_power_default.te`:
```
r_dir_file(hal_power_default, vendor_sysfs_graphics)
```
**Validation (2026-03-11):** No further AVC for `hal_power_default` + `vendor_sysfs_graphics`/`idle_state` in post-flash boot capture (`post_p31final_boot_20260311_161129.txt`).

---

### PROBLEM 28 — Health HAL `oplus_chg` AVC denial

**Evidence:** `avc: denied { search } for comm="vendor.lineage." name="oplus_chg" dev="sysfs" scontext=u:r:hal_lineage_health_default:s0 tcontext=u:object_r:vendor_sysfs_usb_supply:s0 tclass=dir`

Lineage Health HAL tries to traverse the `oplus_chg` sysfs directory (OPlus charger driver nodes) but `vendor_sysfs_usb_supply` is not accessible to `hal_lineage_health_default`. This prevents accurate battery/charging status reporting in the system UI.

**Fix applied:** Created `sepolicy/vendor/hal_lineage_health_default.te` and granted:
```
rw_dir_file(hal_lineage_health_default, vendor_sysfs_usb_supply)
```
(`search` denial cleared first; follow-up `write` denial on `mmi_charging_enable` required `rw_dir_file`.)

**Validation (2026-03-11):** No remaining AVC for `hal_lineage_health_default` on `vendor_sysfs_usb_supply`.

---

### PROBLEM 29 — Sensor ALS + pressure calibration proc denials

**Evidence:**
- `avc: denied { search } for comm="vendor.oplus.ha" name="als_cali" scontext=u:r:vendor_hal_oplus_sensor_default:s0 tcontext=u:object_r:vendor_proc_oplus_als_file:s0 tclass=dir`
- `avc: denied { search } for comm="vendor.oplus.ha" name="pressure_cali" scontext=u:r:vendor_hal_oplus_sensor_default:s0 tcontext=u:object_r:vendor_proc_eng_cali_file:s0 tclass=dir`

The OPlus sensor HAL reads ALS calibration from `/proc/als_cali` and barometer calibration from `/proc/pressure_cali`. The 56 sensors are confirmed active (HW sensor poll works), but per-device calibration offsets may not be applied, causing slight measurement inaccuracy.

**Fix applied:** Updated `sepolicy/vendor/vendor_hal_oplus_sensor_default.te`:
```
rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_oplus_als_file)
rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_eng_cali_file)
```
(`search` denials cleared first; follow-up `write` denials on `red_max_lux/.../cali_coe` and `offset` required `rw_dir_file`.)

**Validation (2026-03-11):** No remaining AVC for `vendor_hal_oplus_sensor_default` on ALS/engineering proc nodes.

---

### PROBLEM 30 — Bluetooth SIGABRT ✅ FIXED (validated 2026-03-12)

**Old crash signatures (resolved):**
- `Handlers must only be cleared once` (from `handler.cc:61`)
- `FORTIFY: pthread_mutex_lock called on a destroyed mutex`
- Process abort: `com.android.bluetooth` / thread `bt_stack_manage`

**Root cause found in current tree:**
- `storage::StorageModule` destructor cleared/deleted `handler_` even though the handler lifetime is owned by `Stack`.
- `Stack::Stop()` also tore down `stack_handler_`, causing teardown-time double-clear / double-delete behavior.
- During shutdown, many modules posted deferred work after handler clear, creating noisy non-fatal log spam.

**Fixes applied (BT APEX source):**
- `packages/modules/Bluetooth/system/gd/storage/storage_module.cc`
  - removed destructor-side handler clear/delete ownership path
- `packages/modules/Bluetooth/system/main/shim/stack.cc`
  - always `WaitUntilStopped()` after `stack_handler_->Clear()`
  - stop `stack_thread_` before deleting `stack_handler_`
- `packages/modules/Bluetooth/system/gd/hal/snoop_logger.cc`
  - keep handler lifecycle ownership in stack; removed destructor handler teardown
- `packages/modules/Bluetooth/system/gd/os/handler.cc`
  - teardown-time `Post()`/`Clear()` on already-cleared handler now no-op without warning spam

**Validation after rebuild + flash (`system_b`):**
- Stress test: 8× `cmd bluetooth_manager disable/enable` loops
- No SIGABRT, no FORTIFY abort, no `destroyed mutex`, no `Handlers must only be cleared once`
- Capture artifact:
  - `device/oneplus/instantnoodlep/logs/bt_toggle_post_logclean_20260312_162437.txt`

**Status:** fixed in current build.

**Latest re-check (2026-03-13, session 18):**
- 8x `cmd bluetooth_manager enable/disable` stress loop completed
- No `SIGABRT`, no `FORTIFY`, no `destroyed mutex` signature
- Artifact: `device/oneplus/instantnoodlep/logs/bt_stress_20260313_134958.log`

---

### PROBLEM 31 — `poweroffalarm` + `wcnss_service` property set denials

**Evidence (before fix):**
- `vendor_poweroffalarm_app`: denied write on property path, runtime failure setting `persist.sys.poweralarm.time`.
- `vendor_wcnss_service`: denied property set path, later narrowed to denied `{ set }` for `property=vendor.vold.serialno`.

**Fix applied (device overlay):**
- `sepolicy/vendor/vendor_poweroffalarm_app.te`:
```te
set_prop(vendor_poweroffalarm_app, system_prop)
```
- `sepolicy/vendor/property.te`:
```te
vendor_internal_prop(vendor_cnss_daemon_prop)
vendor_internal_prop(vendor_vold_serialno_prop)
```
- `sepolicy/vendor/property_contexts`:
```text
persist.vendor.cnss-daemon.debug_level              u:object_r:vendor_cnss_daemon_prop:s0
persist.vendor.cnss-daemon.kmsg_logging             u:object_r:vendor_cnss_daemon_prop:s0
persist.vendor.cnss-daemon.hw_trc_disable_override  u:object_r:vendor_cnss_daemon_prop:s0
vendor.vold.serialno                                u:object_r:vendor_vold_serialno_prop:s0
```
- `sepolicy/vendor/vendor_wcnss_service.te`:
```te
set_prop(vendor_wcnss_service, vendor_cnss_daemon_prop)
set_prop(vendor_wcnss_service, vendor_vold_serialno_prop)
```

**Validation (2026-03-11):**
- No AVC for `vendor_poweroffalarm_app` property path.
- No AVC for `vendor_wcnss_service` property path or `property=vendor.vold.serialno`.
- Runtime properties confirm labels + set:
  - `getprop -Z persist.sys.poweralarm.time` → `u:object_r:system_prop:s0`, value `0`
  - `getprop -Z vendor.vold.serialno` → `u:object_r:vendor_vold_serialno_prop:s0`

---

## REMAINING ITEMS

**ADB health check 2026-03-11 (session 13) — all major subsystems PASS:**

| Subsystem | Result |
|-----------|--------|
| Sensors | `Total 56 h/w sensors, 56 running` ✅ |
| Audio | HAL running, `mMode=NORMAL`, speaker routing active ✅ |
| Camera | 8 devices detected (0–7), all closed-idle ✅ |
| Telephony/SIM | SIM1 `IN_SERVICE` LTE (A1 / 232-01), rsrp=-105, level=3 ✅ |
| WiFi daemon | `wificond` running ✅ |
| Display composer | `vendor.qti.hardware.display.composer-service` running ✅ |
| P27 `idle_state` AVC | **0 occurrences** ✅ |
| P28 `oplus_chg` AVC | **0 occurrences** ✅ |
| P29 ALS/pressure cal AVC | **0 occurrences** ✅ |
| P31 property_socket AVC | **0 occurrences** ✅ |
| `mHalAutoSuspendModeEnabled` | **true** (was `false` before P27 fix) ✅ |
| Screen-off suspend blockers | `mHoldingWakeLockSuspendBlocker=false`, `mHoldingDisplaySuspendBlocker=false` ✅ |
| Force-idle | Transitions to `IDLE/OVERRIDE`, ADB survives, recovers cleanly ✅ |
| `bq27541 suspend=0` flood | Still present while USB connected — **expected** (USB holds kernel wakelock) |
| Deep sleep offline soak | ✅ **DONE** — user-confirmed overnight deep sleep stable on latest build (2026-03-13) |
| SIM internet / LTE / call | ✅ **CONFIRMED** — MCC=232/MNC=01 (A1 AT), LTE Band 3 EARFCN 1700, IN\_SERVICE, rmnet\_data1 UP 10.72.156.216/28, ping 8.8.8.8 0% loss 84ms avg |
| Current boot AVC (session 17, 2026-03-12) | Only `bluetooth_lea_prop` upstream denial — all device-specific AVC clean ✅ |
| `mHalAutoSuspendModeEnabled` (screen ON + USB) | `false` — **expected** (Power HAL disables auto-suspend while display is active) ✅ |
| BT crash loop (session 17, 2026-03-12, 15:47–16:00) | Historical incident: 8+ crashes (`Handler::~Handler` destroyed-mutex SIGABRT) → reboot cascade; current build under 8x toggle stress on 2026-03-13 shows no recurrence |
| LTE registration + mobile data (session 17) | ✅ IN\_SERVICE, LTE Band 3, DATA+VOICE+SMS, rmnet\_data1 ping 0% loss |
| P37 WiFi+LTE coexistence (session 17) | ✅ wlan0 (192.168.8.152) + rmnet\_data1 (10.72.156.216) both UP + routing; ping 0% loss each; no `switch_to_mdm resp wait failed -22` |

**Active P0:** none — all P0 fixes flashed and validated (session 16).

**Active P1:** none.

**Active P2:** monitor-only. P30 (historical BT teardown race) and P40 (non-repro app-switch reboot report) are both monitor state. P37 CLOSED ✅.

**Pending validations (no code change needed):**
- Optional: longer real-world BT connected-device soak to fully close P30 monitor status.

Cosmetic/optional: P13, P18–P21, sensor HAL type-4 log flood.

---

### BT crash loop diagnostic — 2026-03-12 (session 17)

**Time window:** 15:47–16:00 (8+ crashes in 13 minutes) → crash loop watchdog → reboot at 16:08  
**Subsequent reboots:** 16:08 → 16:17 → 16:24 → 17:02 (last was `reboot,shell` from our ADB session) → 18:25 (current)

**pstore:** `pmsg-ramoops-0` only (2MB Android logcat mirror). **No `console-ramoops-0`, no `dmesg-ramoops-0`** → not a kernel panic.

**Root cause:** `com.android.bluetooth` SIGABRT in thread `bt_stack_manage`  
```
signal 6 (SIGABRT)
Abort: 'FORTIFY: pthread_mutex_lock called on a destroyed mutex (0xb4000074b0238858)'
```
**Full call stack (tombstone_25):**
```
#04  libbluetooth_jni.so  std::mutex::lock()
#05  libbluetooth_jni.so  bluetooth::os::Handler::~Handler()
#06  libbluetooth_jni.so  bluetooth::os::Handler::~Handler()  [thunk]
#07  libbluetooth_jni.so  bluetooth::shim::Stack::Stop()
#08  libbluetooth_jni.so  GeneralShutDown()
#09  libbluetooth_jni.so  module_shut_down(module_t const*)
#10  libbluetooth_jni.so  event_clean_up_stack(...)
```
**Process-Runtime: 7419 ms** — BT was freshly started, then received a shutdown signal 7.4 s later. Each restart → crash again → crash loop.

**Key facts:**
- `Process uptime: 0s` (rounded); BT was brand-new on each cycle
- 6 `system_app_native_crash` dropbox entries from 15:47–16:00 (more in earlier entries)
- SYSTEM_BOOT entries: 16:08, 16:17, 16:24, 17:02, 18:25 — crash loop triggered multiple reboots
- `SYSTEM_LAST_KMSG` at 17:02 shows `Last boot reason: reboot,shell` (the 16:24→17:02 reboot was `adb reboot`)

**Classification:** Upstream AOSP race condition in `libbluetooth_jni.so` (`com.android.bt` APEX). The `Handler` destructor tries to lock a mutex that has already been destroyed in a concurrent shutdown path. This is not fixable from the device tree.

**Current state:** BT stable on current boot — `dumpsys bluetooth_manager` shows `state: ON`, `Bluetooth crashed 0 times`. PID 2645 running.

**Trigger investigation:** Unknown what caused BT to receive rapid stop signals (7.4s intervals). Possible causes:
1. A connected BT device (headphones, watch) repeatedly disconnecting/reconnecting
2. System toggle caused by screen-off power management sequence
3. The `bluetooth_lea_prop` AVC denial in SystemUI causing retry loop (not confirmed)

**Action required:** None from device tree (upstream APEX bug). If crash loop recurs, disable BT before overnight soak tests. Track against upstream AOSP BT APEX fix landing.

---

### Session 16 validation snapshot — 2026-03-12

**Primary artifact:** `device/oneplus/instantnoodlep/logs/boot_review_20260312_170144.txt`

- `avc: denied` occurrences in full boot capture: **0**
- P32 signature (`rild` AVC set): **not present**
- P33 signature (`vendor.camera.aux.packageexcludelist` set denial): **not present**
- P34 signature (`init` transition to `vendor_shell` / `noatsecure` / `siginh` / `rlimitinh`): **not present**
- P35 signature (`vendor_pd_mapper` denied read `system_prop`): **not present**
- P36 signature (`Failed to load BDF: qca6390/regdb.bin`): **not present**
- CNSS confirms regdb load:
  - `found /vendor/firmware/qca6390/regdb.bin`
  - `Downloading BDF: qca6390/regdb.bin, size: 19348`
- P37 old timeout signature (`switch_to_mdm resp wait failed -22`): **not present** in this boot (only `Sending coex antenna switch_to_mdm` observed).
- Power quick-check:
  - screen off (`mWakefulness=Dozing`): `mHalAutoSuspendModeEnabled=true`, both suspend blockers `false`
  - screen awake (`mWakefulness=Awake`): `mHalAutoSuspendModeEnabled=false`, display blocker `true` (expected while display active)

**Note:** SIM was removed during this validation session after accidental PIN lockout. Final P37 closure completed in session 17 with active SIM/LTE + WiFi — both routing simultaneously, zero coex errors. P37 **CONFIRMED CLEAN**.

---

### Full logcat error triage — 2026-03-11 (session 13)

All errors categorised. No new P0/P1 blockers found. Full error breakdown:

| Error | Source | Classification | Action |
|-------|--------|---------------|--------|
| `Audio Stream Capture 32 App Type Cfg` mixer ctrl missing | `audio_hw_utils` | P3 🟡 cosmetic — already tracked as P18 | none |
| `afe_spk_prot_prepare: port=0x1004 failed -22` | kernel audio | P3 🟡 cosmetic — spkr_prot disabled; QCOM AFE still probes the path once at init, fails gracefully | none |
| `ADSP_EBADPARAM` / `afe_callback: cmd=0x100fa error=0x2` | ADSP AFE | P3 🟡 cosmetic — same spkr_prot probe as above | none |
| `cam_cci_assign_fops: Invalid dev node` | CAM-CCI | P3 🟡 cosmetic — CAM CCI character device numbering cosmetic; cameras still detect as 8 devices | none |
| `CAM-OIS: cam_ois_driver_soc_init: get download,fw failed rc:-22` | OIS driver | ✅ fixed — DT property `download,fw` now present in both instantnoodlep OIS nodes; current boot shows `read download,fw success, value:1` | monitor camera behavior in real shooting |
| `cam_sensor_update_id_info: vendor_slave_addr: 0x0` | CAM-SENSOR | P3 🟡 cosmetic — vendor ID probing on secondary camera slots, non-fatal | none |
| `cnss: Failed to load BDF: qca6390/regdb.bin` | WiFi CNSS | ✅ fixed on latest boot capture — regdb loaded from `/vendor/firmware/qca6390/regdb.bin` | monitor only |
| `cnss: Coex antenna switch_to_mdm resp wait failed -22` | WiFi CNSS | 🟡 monitor — not reproduced in latest boot capture | re-test with active SIM/LTE + WiFi traffic |
| `cnss: failed to query wlfw mac, error: 7` | WiFi CNSS | P3 🟡 cosmetic — MAC queried from firmware; falls back to NVRAM/persisted MAC. Non-blocking | none |
| `android.hardware.wifi-service: Failed to get chip capabilities / SupportedIfaceCombinations / SupportedRadioCombinations: NOT_SUPPORTED` | WiFi HAL | P3 🟡 cosmetic — QCA6390 legacy HAL path; WiFi works despite this | none |
| `android.hardware.wifi-service: Unknown iface name: wlan0` (init only) | WiFi HAL | P3 🟡 cosmetic — transient at startup before wlan0 is up | none |
| `ANDR-PERF: Failed to read /sys/class/mmc_host/mmc0/clk_scaling/enable` | Qualcomm perf | P3 🟡 cosmetic — UFS storage device, not eMMC; `mmc0` node absent is expected | none |
| `vendor_init: denied set property=vendor.camera.aux.packageexcludelist` | SELinux | ✅ fixed — not present in latest boot capture | none |
| `vendor_init: denied set property=ro.apk_verity.mode` | SELinux | P3 🟡 cosmetic — `vendor_init` attempting to set a `default_prop`; `ro.apk_verity.mode` is set by system init anyway | none |
| `init: denied transition to vendor_shell` (sensor_recover.sh) | SELinux | ✅ fixed — no transition denials in latest boot capture | none |
| `vendor_pd_mapper: denied read system_prop` | SELinux | ✅ fixed/log-clean — not present in latest boot capture | none |
| `system_server: denied read pih_disable_prop` | SELinux | P3 🟡 cosmetic — PIH (Peripheral Interface Hub) disable property not readable by system_server; PIH feature likely unused on this device | none |
| `rild: denied write system_data_root_file, read cache_file, read default_prop` | SELinux (P32) | ✅ fixed/log-clean — AVC signature absent in latest boot capture | none |
| `servicemanager: denied call usbd:s0` | SELinux | P3 🟡 cosmetic — servicemanager→usbd binder call; USB daemon communication path | check if affects USB functionality |
| `bt_ioctl / bt_vreg_enable` bursts during manual BT toggle stress | BT power | P3 🟡 cosmetic — expected while intentionally cycling BT state during validation | none |
| `bolero-codec: ASoC unknown pin WSA AIF VI` | Audio kernel | P3 🟡 cosmetic — already tracked as P13 | none |
| `cam_cc_sleep_clk_src: CXO configuration failed` | Camera clock | P3 🟡 cosmetic — camera subsystem sleep clock CXO config; non-fatal at runtime | none |
| `sensors-hal: handle_sns_client_event: oplus ts=..., type=4` flooding | OPlus sensor HAL | P3 🟡 cosmetic — device orientation sensor data logging at E level; sensor works correctly | may need `ro.build.flavor` check suppressed in HAL |
| `BootReceiver: Could not open /sys/kernel/tracing/instances/bootreceiver/trace_pipe` | system_server | P3 🟡 cosmetic — ftrace bootreceiver instance missing; affects boot crash tracing only | none |

**P33/P34/P35 validation update (session 16, 2026-03-12):**
- No matching AVC signatures in `boot_review_20260312_170144.txt`.
- `sensor_recover.sh` persist paths are present under `/mnt/vendor/persist/sensors/...` after boot.
- Current policy set is sufficient for clean boot behavior on this build.

P0 audio resolved and confirmed on device (session 5).

---

---

### Overnight battery drain diagnostic — 2026-03-12 (session 14, historical)

This section is preserved as historical context from before the latest flash/validation pass.  
Current-state validation is tracked in **Session 16 validation snapshot** above.

**Symptom:** Phone shut down overnight from 100% → 0%.

**pstore check:** `/sys/fs/pstore/` was **empty** — no kernel panic, no crash logs. This is a pure battery drain issue, not a Sleep of Death kernel crash.

**Root cause confirmed: P27 not flashed.** `mHalAutoSuspendModeEnabled=false` on the running build (built `Wed Mar 11 13:28:56 CET 2026`). All source-tree SELinux fixes (P27 re-fix, P33, P34, P35) have been written to the device tree but **no new build has been compiled or flashed yet**.

**Discharge step analysis (from `dumpsys batterystats`):**

| Step | Rate | State flags |
|------|------|------------|
| #6 (top step) | 2m 46s / 1% | `device-idle-off` ← never entered Doze |
| #7–#64 | ~30s / 1% | `screen-doze, device-idle-off` ← screen off, still NOT in deep idle |

Every single discharge step shows `device-idle-off`. The phone's screen was off (screen-doze) but Android Doze **never entered deep idle** because `mHalAutoSuspendModeEnabled=false` prevents the Power HAL from signalling the kernel that it is safe to suspend. At ~30s/1% the phone drains 100% in under 50 minutes of screen-off time.

**idle_state node status:**
- Path: `/sys/devices/platform/soc/ae00000.qcom,mdss_mdp/idle_state`
- SELinux label: `u:object_r:vendor_sysfs_graphics:s0` ✅ (correct label)
- Content: `idle` ✅ (node is readable by root)
- Issue: `hal_power_default` still cannot read it — the `r_dir_file(hal_power_default, vendor_sysfs_graphics)` fix is in the source tree but **not flashed**

**New AVC denials from P34 partial fix (sensor_recover.sh transition):**
At that point in session 14, the `allow init vendor_shell:process transition;` line had been added in source but not yet flashed. Additional permissions were suspected:
- `{ noatsecure }` — `scontext=u:r:init:s0 tcontext=u:r:vendor_shell:s0 tclass=process`
- `{ rlimitinh }` — same
- `{ siginh }` — same
- `{ search }` — `vendor_shell` reading `/mnt/vendor` (`mnt_vendor_file`)

These are the standard `domain_auto_trans` companion permissions. The P34 fix needs to be expanded from a bare `allow transition` to a full domain transition macro. **Required fix (not yet coded):**
```
# In vendor_qti_init_shell.te — replace the bare allow line with:
domain_auto_trans(init, vendor_shell_exec, vendor_shell)
allow vendor_shell mnt_vendor_file:dir search;
```

**Wakelock summary (top holders from `dumpsys batterystats`):**
| Wakelock | Holder | Duration | Assessment |
|----------|--------|---------|-----------|
| `PowerManagerService.WakeLocks` | kernel | 6m 28s | PMS aggregated — normal |
| `prox_lock` | kernel | 31s | proximity sensor during calls — normal |
| `AnyMotionDetector` | uid 1000 (system) | 2m 2s | motion detection wakelock — normal |
| `Checkin Service` | u0a172 (GMS) | 2m 34s | GMS check-in — normal |
| `NetworkTimeUpdateService` | uid 1000 | 1m 26s | NTP sync — normal |

**No single wakelock is the culprit.** All wakelocks are short and normal. The drain is caused by Doze never engaging (all CPU governors stay at full idle power instead of entering deep C-states / RPM sleep), which is 10–20× worse than proper deep sleep.

**Required action: build and flash the existing source fixes.**
Once P27 fix is flashed, `mHalAutoSuspendModeEnabled` will return to `true` and Doze deep idle will engage. Expected standby drain after fix: ~0.3–0.5%/hour (from ~2%/minute now).

**Historical note (session 14):** P34 expansion was considered before the next flash.

---

## NEXT BUILD STEPS

### Optional — commit current working state
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep
git add TODO.md && git commit --amend --no-edit

cd /home/lal3lu/android/pixelos/device/oneplus/sm8250-common
git add -u && git commit --amend --no-edit
```

### If cosmetic kernel logspam (P13, P21) becomes a problem
- Add a DT property to guard WSA DAPM route registration in the kona machine driver
- Add `qcom,tdm-max-slots = <8>` to the sound DT node (eliminates the default warning)
- These require a `kernel/oneplus/sm8250` change + boot.img rebuild

---

## VERIFIED — NO ACTION NEEDED

| Item | Verified |
|------|---------|
| `audio_policy_configuration.xml` loading from XML (not setDefault) | ADB: `Config source: /vendor/etc/audio_policy_configuration.xml` ✅ |
| `audio_platform_info_intcodec.xml` deployed as `/vendor/etc/audio_platform_info.xml` | `device.mk` ✅ |
| Generic kona `audio_platform_info.xml` removed from common.mk | `sm8250-common/common.mk` ✅ |
| `audio_io_policy.conf` deployed, 0× `#ifdef` guards | ADB: `grep -c ifdef` → `0` ✅ |
| `audio_tuning_mixer.txt` deployed to vendor | ADB ✅ |
| TFA flags `external_speaker*.enable=true` | `sm8250-common/vendor.prop` (session 4) + ADB runtime ✅ |
| `vendor.audio.feature.spkr_prot.enable=false` | `sm8250-common/vendor.prop` (session 4 — Option A fix for P16) ✅ |
| `audio_amplifier.kona.so` present and loading; TX mapped to device 32 | ADB: `D audio_amplifier: pcm_dev_tx_id = 32` ✅ |
| `AUDIO_FEATURE_ENABLED_EXT_AMPLIFIER := true` | `BoardConfigCommon.mk` ✅ |
| TFA9874 kernel driver probed on I2C 0x34 + 0x35 | ADB logcat: `TFA9874 detected` ✅ |
| `persist.vendor.audio.speaker.prot.enable=true` | ADB: `[persist.vendor.audio.speaker.prot.enable]: [true]` ✅ |
| ACDB files at `/odm/etc/acdbdata/` | `instantnoodlep-vendor.mk` ✅ |
| `tfa98xx.cnt` firmware at `/odm/firmware/` | ADB ✅ |
| All 56 sensors running | ADB: `Total 56 h/w sensors, 56 running` ✅ |
| PCM device 32 (`pcmC0D32c`) exists in ALSA card | ADB: `ls /dev/snd/` ✅ |
| PCM devices 24–28 absent from ALSA card (D23 → D29 gap) | ADB: `ls /dev/snd/ \| sort -t D -k2 -n` confirms D24–D28 missing ✅ |
| TFA9874 calibration applied: L=6294 mΩ (0x34), R=6023 mΩ (0x35) — within 5000–8000 mΩ | ADB logcat session 5: `tfa_dev_start success (0)` on both chips ✅ |
| 24-bit deep_buffer_24 (app_type 69936) active at 48 kHz | ADB logcat session 5: `Allowing 24 and above bits playback on speaker` ✅ |
| Speaker produces audible output | Confirmed live by user — session 5 ✅ |
| No `spkr_prot_start_processing` errors | ADB logcat session 5: zero occurrences ✅ |



## END OF TODO - begin usage of flash boot and creating



Here is the consolidated reference for your next build and flash session.

---

# Build and Boot Reference: `instantnoodlep`

## 1. Build and Flash Sequence (Slot `b`)

Use this block to compile the necessary images and deploy them via `fastbootd`. the vendorimage odmimage down there are just as examples

```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-user # release shipping variant for testing ajdust it to userdebug so we can use adb root and debug tools if needed only for relseasing, use the user build
m vendorimage odmimage -j$(nproc) # example targets; adjust as needed

adb reboot bootloader # necassery
fastboot reboot fastboot # necassery
fastboot flash vendor_b out/target/product/instantnoodlep/vendor.img # example target; adjust if you built a different image
fastboot flash odm_b out/target/product/instantnoodlep/odm.img # example target; adjust if you built a different image
fastboot reboot

```

Unlock phone (SIM-safe routine)

```bash
# 0) Safety check: never auto-send lockscreen PIN when SIM PIN is still required
sim_state=$(adb shell getprop gsm.sim.state | tr -d '\r')
if echo "$sim_state" | grep -Eq "PIN_REQUIRED|PUK_REQUIRED"; then
  echo "SIM PIN/PUK required. Unlock SIM manually on device first, then continue."
  exit 1
fi

# 1) Swipe up to reveal the screen-lock keypad
adb shell input swipe 500 1500 500 300
sleep 1

# 2) Enter only the lockscreen PIN (replace 1234)
adb shell input text "1234"
adb shell input keyevent 66

# 3) Optional fallback (userdebug-only): verify user 0 unlock state
# adb shell locksettings verify --old 1234
```

> This guard prevents accidental SIM lockouts caused by sending the lockscreen PIN to the SIM PIN prompt.



## 2. Boot Capture (Diagnostics)

Run this after a clean reboot to verify `ISensors` and `spkr_prot` initialization.

```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/boot_capture_${ts}.log
adb shell logcat -b all -c
adb reboot
for i in $(seq 1 180); do adb get-state >/dev/null 2>&1 && break; sleep 1; done
adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
adb shell logcat -b all -d -v threadtime > "$out"

rg -n "ISensors/default|sscrpcd|apps_dev_init failed|remote_handle_open|adsp_default_listener|Transport endpoint|accelerometer|gyro|onbody|spkr_prot|speaker-protected" "$out" # or whatever regex you want to check for

```

## 3. Runtime Capture (Verification)

Run this while testing audio output or shake gestures to catch real-time errors or denials.

```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/runtime_capture_${ts}.log
adb shell logcat -b all -c
timeout 40s adb shell logcat -b all -v threadtime > "$out"

rg -n "audio_hw|spkr|speaker|sensors-hal|accelerometer|gyro|shake|gesture|ISensors/default|avc: denied" "$out" # or whatever regex you want to check for

```

## 4. Power-Off Incident Triage (2026-03-13)

Observed once: device was found powered off and not visible on `adb`/`fastboot` for ~144s, then came back online.

**Collected facts (root + adb):**
- `getprop persist.sys.boot.reason.history`:
  - `reboot,1773405658` => `2026-03-13 13:40:58 CET`
  - `shutdown,userrequested,1773349554` => `2026-03-12 22:05:54 CET`
  - `reboot,shell,1773339181` => `2026-03-12 19:13:01 CET`
- `cat /sys/power/pon_reason` => `[0x80]Triggered from KPD (Power Key Press) and 'cold' boot`
- `cat /sys/power/poff_reason` => `Unknown[0x   0]`
- `cat /proc/sys/kernel/boot_reason` => `8`
- No kernel panic trace available (`/proc/last_kmsg` missing), no thermal shutdown (`dumpsys thermalservice` status `0`).

**Conclusion:**
No evidence of a ROM crash or thermal kill for this incident. Most likely cause is a power-key-triggered cycle (accidental long-press or manual key event).

**Follow-up re-check (session 19, 2026-03-13 14:14–14:17 CET):**
- `persist.sys.boot.reason.history` still shows only reboot markers (`1773407647`, `1773407850`) with no panic/watchdog indicator.
- `/data/tombstones` has no new entries after `2026-03-12 16:00`.
- `/data/system/dropbox` at these times contains only `SYSTEM_BOOT@...` records (no new `system_app_native_crash`).
- Fresh `logcat -b all -d` scan has no `FATAL EXCEPTION`, native `Fatal signal`, watchdog kill, or kernel panic marker.

**Quick command to re-check after any future unexpected power-off:**
```bash
adb root
adb shell 'getprop ro.boot.bootreason; getprop sys.boot.reason; getprop persist.sys.boot.reason.history; cat /sys/power/pon_reason; cat /sys/power/poff_reason; cat /proc/sys/kernel/boot_reason'
```

## 5. Recovery Shipping Routine (validated 2026-03-13)

Use this for release-oriented recovery artifacts and flashing.  
No `adb wait-for-device` is used.

```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-user
m recoveryimage bootimage dtboimage vbmetaimage vbmetasystemimage -j$(nproc)

# Flash slot b
adb reboot bootloader
fastboot flash dtbo_b out/target/product/instantnoodlep/dtbo.img
fastboot flash vbmeta_b out/target/product/instantnoodlep/vbmeta.img
fastboot flash recovery_b out/target/product/instantnoodlep/recovery.img
fastboot reboot recovery
```

Reusable helper script:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./flash_recovery_fastboot.sh b
```

Current build checksums (session 20):
```text
recovery.img      f163af715fec0774edfbc14ba30acd0b4fc5ca9cea2a4aabece6335b05901039
boot.img          4aecad9466aabb6fe03768bda18b4c1c37e5b783975111adafa29ede5370e236
dtbo.img          7d2c85c3dadd9d1a60cfd36e7600547dd2b040711318da102d54bb636720cfe6
vbmeta.img        4af6305942cb0dc6f8e2ec5d1c6af4c2a7d1da30db855c807cd42fb31a9ca447
vbmeta_system.img 24fb2812de3a81a867f6b6a51eb8464bfe253f66a1684bb2c2201fed31d0338b
```

If ADB shows `unauthorized` while in recovery, reboot from the recovery UI (`Reboot system now`) and re-authorize USB debugging after Android boots.

### Distribution artifact (session 22)

```text
Folder: /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/releases/instantnoodlep-recovery-fastboot-20260313/
Zip:    /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/releases/instantnoodlep-recovery-fastboot-20260313.zip
SHA256: c5c6b7b9b4e06b6123c0ba2f300a491f7b6d9763a5e2a7be2e6fd062da9aaec7
Guide:  /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/releases/instantnoodlep-recovery-fastboot-20260313/PUBLIC_HANDOVER.md
```

## 6. Session 23 Closeout — user/userdebug split + release-ready state

### Final status

- All blocking bring-up issues are fixed in tree.
- `user` is the shipping variant (release behavior).
- `userdebug` is the debugging variant (SetupWizard bypassed for faster cycles).
- Remaining low-level log noise is cosmetic/monitor-only and does not block release.

### Variant behavior now enforced

- `device/oneplus/instantnoodlep/aosp_instantnoodlep.mk`
  - `userdebug`: `ro.setupwizard.mode=DISABLED`
  - `user`: SetupWizard enabled
  - Build fingerprint/desc set to `release-keys`

### Build routines (separated output dirs)

Scripts added:
- `device/oneplus/instantnoodlep/tools/build_variant.sh`
- `device/oneplus/instantnoodlep/tools/build_user.sh`
- `device/oneplus/instantnoodlep/tools/build_userdebug.sh`

Defaults:
- `user OUT_DIR`: `/home/lal3lu/android/pixelos/out_user` (symlink -> `/mnt/androidbuild/out-user`)
- `userdebug OUT_DIR`: `/home/lal3lu/android/pixelos/out_userdebug` (symlink -> `/home/lal3lu/android/pixelos_out_userdebug`)
- shared ccache: `/mnt/androidbuild/ccache`

Optional overrides:
```bash
export PIXELOS_OUT_USER=/path/on/ssd1/out-user
export PIXELOS_OUT_USERDEBUG=/path/on/ssd2/out-userdebug
export CCACHE_DIR=/path/shared/ccache
```

Build `user`:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./build_user.sh
```

Build `userdebug`:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./build_userdebug.sh
```

### Flash routine reference (same for both variants)

```bash
adb reboot bootloader
fastboot flash dtbo_b out/target/product/instantnoodlep/dtbo.img
fastboot flash vbmeta_b out/target/product/instantnoodlep/vbmeta.img
fastboot flash recovery_b out/target/product/instantnoodlep/recovery.img
fastboot reboot recovery

# in recovery: Apply update -> ADB sideload
adb sideload out/target/product/instantnoodlep/lineage-*.zip
```

### Release gate before shipping user build

1. Clean flash of final signed `user` package.
2. Call audio (earpiece + speaker + mic) passes.
3. Fingerprint enroll/unlock passes.
4. Camera photo/video quick pass.
5. Mobile data + WiFi + Bluetooth quick pass.
6. Play Integrity + target banking app smoke test passes at expected level for unlocked-bootloader custom ROM distribution.

---

## PLAY INTEGRITY INTEGRATION PLAN (Session 24+)

**Status:** 🟡 PENDING (waiting for batch compilation to complete, then implementing strong integrity chain)  
**Default behavior:** No root access exposed to users; integrity checks performed silently via property spoofing + KernelSU optional module.  
**Target:** `MEETS_STRONG_INTEGRITY` on stock Google Play, selective app unlock for valid Play certificates.

### Phase 1: Base Property Spoofing (NO ROOT EXPOSURE)

**Timeline:** Immediately after batch finishes  
**Priority:** P0 (core integrity foundation)

| Task | File | Details | Status |
|------|------|---------|--------|
| A1 | Create system property overrides | `device/oneplus/instantnoodlep/system.prop` | NOT STARTED |
| A2 | Add properties to build | `device.mk` or `aosp_instantnoodlep.mk` | NOT STARTED |
| A3 | Verify properties on device | `adb shell getprop \| grep -E "fingerprint\|api_level\|gms"` | NOT STARTED |
| A4 | Boot clean flash, test Play Services | Test Play Integrity API response | NOT STARTED |

**Properties to set (spoofing layer):**
```
ro.product.first_api_level=29
ro.product.model=IN2025
ro.build.version.release=10
ro.vendor.extension_library=/vendor/lib64/libqti-perfd-client.so
ro.com.google.clientidbase=android-google
ro.com.google.gmsversion=gms_20_202009
```

**Expected result after Phase 1:** Basic integrity pass but not strong; "MEETS_DEVICE_INTEGRITY" level.

---

### Phase 2: KernelSU Integration (OPTIONAL, FOR ADVANCED USERS)

**Timeline:** After Phase 1 validation OR if user has KernelSU already flashed  
**Priority:** P1 (enables optional module-based integrity hardening)

| Task | File | Details | Status |
|------|------|---------|--------|
| B1 | Confirm KernelSU on device | `adb shell getprop ro.kernel.android.checkjni` or `ls /system/kernelsu` | NOT STARTED |
| B2 | If yes: package PIF module | `device/oneplus/instantnoodlep/kernelsu/pif/module.prop` | NOT STARTED |
| B3 | If yes: package TrickyStore module | `device/oneplus/instantnoodlep/kernelsu/trickystore/module.prop` | NOT STARTED |
| B4 | Create init trigger for module loading (optional auto-init) | `init/zz_integrity_modules.rc` | NOT STARTED |
| B5 | Test module installation & execution | Flash ROM, verify module loads on reboot | NOT STARTED |

**KernelSU detection command:**
```bash
adb shell "[ -d /system/kernelsu ] && echo 'KernelSU installed' || echo 'Not installed'"
```

**Expected result after Phase 2 (conditional):** If KernelSU present, enhanced integrity via:
- PIF dynamic property injection (fingerprint spoofing at framework level)
- TrickyStore keybox + attestation hook (prevents downgrade of integrity response)
- "MEETS_STRONG_INTEGRITY" for apps that verify TrickyStore presence

---

### Phase 3: One-Tap Integrity Setup (USER INTERACTION LAYER)

**Timeline:** After Phase 2 (only if Phase 2 modules prepared)  
**Priority:** P2 (user convenience, not required)

| Task | File | Details | Status |
|------|------|---------|--------|
| C1 | Create setup activity | `frameworks/.../IntegritySetupActivity.kt` (in app module if added) | NOT STARTED |
| C2 | Add intent filter to system apps | Register in `AndroidManifest.xml` | NOT STARTED |
| C3 | Create notification trigger | Trigger on first boot after integrity props are set | NOT STARTED |
| C4 | Implement one-tap KSU module init | User taps → runs `integrity_init.sh` (if Phase 2 modules present) | NOT STARTED |
| C5 | Test UX flow: first boot → notification → tap → modules load → reboot → integrity ✅ | User journey validation | NOT STARTED |

**Expected flow:**
1. First boot after flash → System detects Phase 1 props active
2. Notification: "Tap to activate advanced integrity protection" (if KSU available)
3. User taps → script loads PIF + TrickyStore + reboots
4. After reboot → "MEETS_STRONG_INTEGRITY" → apps unlock

---

### Phase 4: Policy & SELinux (INTEGRITY DOMAIN HARDENING)

**Timeline:** If Phase 2/3 modules added (concurrent with B/C)  
**Priority:** P2 (security hardening)

| Task | File | Details | Status |
|------|------|---------|--------|
| D1 | Create `integrity_module.te` SELinux policy | Define domain for KSU module init scripts | NOT STARTED |
| D2 | Grant module domain access to properties | Allow PIF/TrickyStore to set `ro.build.*` + `ro.product.*` | NOT STARTED |
| D3 | Audit for AVC denials during module load | Post-reboot logcat capture | NOT STARTED |

**Expected result:** No AVC denials when modules load; integrity services run cleanly.

---

### Phase 5: Testing & Validation

**Timeline:** After each phase  
**Priority:** P0 (per-phase validation gate)

| Test | Command | Expected Result | Status |
|------|---------|-----------------|--------|
| **Phase 1 Property Check** | `adb shell getprop ro.build.fingerprint` | Shows spoofed string (not device-specific) | NOT STARTED |
| **Phase 1 Play API Test** | Open Play Services Settings → Play Integrity API test call | `MEETS_DEVICE_INTEGRITY` (or basic) | NOT STARTED |
| **Phase 2 KSU Module Test** | After reboot post-KSU install | No AVC denials, `integrity_init.sh` completes | NOT STARTED |
| **Phase 2 Play API Test (Enhanced)** | After modules loaded | `MEETS_STRONG_INTEGRITY` if TrickyStore + keybox set | NOT STARTED |
| **Banking App Smoke Test** | Open target banking app configured to require strong integrity | App launches without denial | NOT STARTED |

---

### Architecture Overview (High-Level)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  PHASE 1: Base Property Spoofing (No Root)                      │
│  ┌──────────────────┐                                           │
│  │ device.mk        │ →  PRODUCT_SYSTEM_PROPERTIES              │
│  │ system.prop      │ →  ro.build.fingerprint (spoofed)         │
│  │ vendor.prop      │ →  ro.product.first_api_level=29         │
│  └──────────────────┘                                           │
│           ↓                                                      │
│  Framework reads props → basic integrity certificate           │
│  Play API response: "MEETS_DEVICE_INTEGRITY"                   │
│           ↓                                                      │
│  ┌─ PHASE 2 (Optional): KernelSU Modules ─────┐                │
│  │  IF KernelSU flashed on device:            │                │
│  │  ┌────────────────────────────────────┐    │                │
│  │  │ PIF Module                         │    │                │
│  │  │ ├─ Injects fingerprint at runtime  │    │                │
│  │  │ ├─ Hooks Play Integrity API        │    │                │
│  │  │ └─ Survives SecurityException      │    │                │
│  │  ├────────────────────────────────────┤    │                │
│  │  │ TrickyStore Module                 │    │                │
│  │  │ ├─ Sets valid keybox               │    │                │
│  │  │ ├─ Cross-checks attestation        │    │                │
│  │  │ ├─ Prevents Play from flagging     │    │                │
│  │  │ └─ Result: "MEETS_STRONG_INTEGRITY"│    │                │
│  │  └────────────────────────────────────┘    │                │
│  └────────────────────────────────────────────┘                │
│                                                                 │
│  PHASE 3 (Optional): One-Tap Setup Activity                    │
│  ┌────────────────────────────────────────────┐               │
│  │ First boot notification (if KSU available) │               │
│  │ → User taps → runs integrity_init.sh       │               │
│  │ → Reboot → Modules active                  │               │
│  │ → Apps unlock (higher integrity tier)      │               │
│  └────────────────────────────────────────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Decision Trees

**Q: Does Phase 1 alone satisfy Play Integrity requirements?**
- ✅ For unlocked-bootloader custom ROM: YES (basic integrity)
- ❌ For closed apps requiring strong integrity: MAYBE (depends on app and Play version)
- Best approach: Phase 1 + optional Phase 2 for users who need it

**Q: Do users see a root shell or root access prompt?**
- ✅ Phase 1: **NO** (property spoofing is build-time, users get clean device)
- ⚠️ Phase 2: **Only IF they choose to install KernelSU separately** (not forced)
- ✅ Phase 3: Single notification → one tap → automatic (no manual root use)

**Q: What if user doesn't want any integrity hacks?**
- ✅ Supported: Flash `user` build, Phase 1 props are inert (basic spoofing), can disable KSU modules
- Device operates normally with native Play Integrity response (lower tier but honest)

---

### Build Batch Completion Wait

**Status:** ROM compilation in progress (bacon running)  
**Next step:** Upon batch completion, run Phase 1 immediately (property-only, no code)  
**Then:** Validation gate #1 (property check on device)  
**Then:** Decision on Phase 2/3 (KernelSU optional, only if user has it)

