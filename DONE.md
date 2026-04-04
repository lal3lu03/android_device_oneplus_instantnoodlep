# Completed Work — `instantnoodlep` A16 Bringup
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)
**Branch:** `a16-bringup-fixes`

All items below are verified fixed in the current tree (ADB confirmed or source reviewed).

---

## STATUS SUMMARY — ALL RESOLVED

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
| 13 | Audio | WSA DAPM route failures at boot — 4 unknown pins | P2 | 🟡 COSMETIC (no fix needed) |
| 14 | Audio | `audio_io_policy.conf` dead 24-bit profiles — all preprocessor guards removed | P2 | ✅ FIXED |
| 15 | SELinux | `/dev/oplus_sensor_devinfo` unlabeled | P2 | ✅ FIXED |
| 16 | Audio | QCOM `libspkrprot` opens PCM device 25 (missing) | **P0** | ✅ FIXED (Option A: `spkr_prot.enable=false`) |
| 17 | SELinux | `shell.te`, `tri-state-key-calibrate.te`, `vendor_qti_init_shell.te` untracked | P2 | ✅ FIXED |
| 18 | Audio | `Audio Stream Capture 32 App Type Cfg` mixer ctrl missing | P3 | 🟡 COSMETIC |
| 19 | Audio | `volume_listener: Failed to set gain dep cal level` → retry on each playback start | P3 | 🟡 COSMETIC |
| 20 | Kernel | `oplus,dac-vendor` DT property absent | P3 | 🟡 COSMETIC |
| 21 | Kernel | `No DT match for tdm max slots` — falls back to default 8; correct | P3 | 🟡 COSMETIC |
| 22 | Fingerprint | UDFPS HBM UI-ready handshake broken — stale `/dev/oplus_display` fd | **P0** | ✅ FIXED (validated 2026-03-11) |
| 23 | Call Audio | In-call earpiece/speaker playback silent | **P0** | ✅ FIXED (validated 2026-03-10) |
| 24 | Call Audio | In-call microphone dead | **P0** | ✅ FIXED (validated 2026-03-10) |
| 25 | Audio | Internal-codec HAL expects `audio_platform_info_intcodec.xml`; build shipped only `audio_platform_info.xml` | **P0** | ✅ FIXED (session 9 + 11) |
| 26 | Power | Sleep of Death (SoD) — battery drain / phone does not wake from deep sleep | **P0** | ✅ FIXED (2026-03-13) |
| 27 | SELinux | `hal_power_default` denied `{ read }` on `idle_state` sysfs node | **P0** | ✅ FIXED (2026-03-11) |
| 28 | SELinux | `hal_lineage_health_default` denied on `vendor_sysfs_usb_supply` | P1 | ✅ FIXED (2026-03-11) |
| 29 | SELinux | `vendor_hal_oplus_sensor_default` denied on ALS + pressure calibration proc | P2 | ✅ FIXED (2026-03-11) |
| 30 | Bluetooth | `com.android.bluetooth` SIGABRT in `bt_stack_manage` teardown race | P2 | ✅ FIXED (2026-03-12) |
| 31 | SELinux | `vendor_poweroffalarm_app` + `vendor_wcnss_service` property set denied | P2 | ✅ FIXED (2026-03-11) |
| 32 | SELinux | `rild` denied write `system_data_root_file` + read `cache_file`/`default_prop` | P2 | ✅ FIXED (log-cleanup) |
| 33 | SELinux | `vendor_init` denied `{ set }` on `vendor_persist_camera_prop` | P2 | ✅ FIXED |
| 34 | SELinux | `init` denied `{ transition }` to `vendor_shell` for `sensor_recover.sh` | P2 | ✅ FIXED |
| 35 | SELinux | `vendor_pd_mapper` denied `{ read }` on `system_prop` | P2 | ✅ FIXED |
| 36 | WiFi | `cnss: Failed to load BDF: qca6390/regdb.bin` | P2 | ✅ FIXED |
| 37 | WiFi | `cnss: Coex antenna switch_to_mdm resp wait failed -22` | P2 | ✅ CONFIRMED CLEAN (2026-03-12) |
| 38 | Camera | `CAM-OIS: get download,fw failed rc=-22` — DT property `download,fw` missing | P3 | ✅ FIXED (2026-03-13) |
| 39 | Display | Settings UI text overlapping / garbled — wrong DPI (560 → 420) | P1 | ✅ FIXED (2026-03-12) |
| 40 | Stability | App-switch reboot (YouTube → Photos) — not reproducible | P2 | 🟡 MONITOR |
| 41 | Release | `TARGET_NO_RECOVERY` + `AB_OTA recovery` filter disabled recovery build | P1 | ✅ FIXED (session 20) |
| 42 | Power/Display | Black-screen + severe idle drain — PPR property | **P0** | ✅ FIXED (2026-03-15, PPR disabled) |

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

**Shake control:** `sns_multishake.json` deployed with correct soc_id=356. Works after enabling in Settings.

---

## AUDIO STATUS — COMPLETE ✅ (session 5 confirmed)

- `tfa_dev_start success (0)` on both TFA9874 chips (I2C 0x34 + 0x35) ✅
- Calibration: 0x35 = 6023 mΩ, 0x34 = 6294 mΩ (both within 5000–8000 mΩ limit) ✅
- 24-bit 48kHz active, `deep_buffer_24` profile selected ✅
- `enable_snd_device: snd_device(2: speaker)` + `snd_device(217: vi-feedback)` ✅
- No SELinux AVC denials for audio ✅
- In-call earpiece routes to top earpiece (not bottom speaker) ✅
- In-call microphone active ✅

Remaining cosmetic issues (P13, P18–P21) do not block audio function.

**Prop disambiguation (important for future reference):**

| Property | Value | Purpose |
|----------|-------|---------|
| `vendor.audio.feature.spkr_prot.enable` | `false` | QCOM `libspkrprot` gate — **must be false** on TFA devices |
| `persist.vendor.audio.speaker.prot.enable` | `true` | TFA HAL calibration data flag — **must be true** |

---

## DETAILED PROBLEM WRITEUPS (Historical Reference)

### PROBLEM 11 — `vendor.audio.feature.spkr_prot.enable=false` (regression) ✅ FIXED

**File:** `sm8250-common/vendor.prop`
**Fix applied:** `vendor.audio.feature.spkr_prot.enable=false` → `true`
**Confirmed on device (session 3):** `[vendor.audio.feature.spkr_prot.enable]: [true]` ✅

> **NOTE:** Enabling `spkr_prot` surfaced P16 — QCOM `libspkrprot` opens PCM device 25 for VI-feedback TX (doesn't exist). This moved the failure from "library not loaded" to "PCM open error", revealing the precise root cause.

---

### PROBLEM 12 — TFA9874 DT `tfa_use_i2s` absent ✅ NON-ISSUE

**Session 5 outcome:** Audio plays correctly. `tfa_use_i2s` log only appeared at the very first cold boot. `extend_codec_be_dailink` registers DAI links correctly against TERT_MI2S regardless of the DT property. **No kernel DT change needed.**

---

### PROBLEM 13 — WSA DAPM route failures at boot 🟡 COSMETIC

```
E tfa98xx 2-0035: ASoC: unknown pin SpkrRight IN
E tfa98xx 2-0034: ASoC: unknown pin SpkrLeft IN
E bolero-codec: ASoC: unknown pin WSA AIF VI
```
OnePlus 8 Pro has TFA9874, not QCOM WSA. These routes fail at probe but audio plays correctly via TERT_MI2S. **Not worth fixing** unless kernel patch to guard WSA route registration behind a DT flag.

---

### PROBLEM 14 — `audio_io_policy.conf` preprocessor guards ✅ FIXED

All `#ifdef OPLUS_FEATURE_PLAYBACK_24BIT`, `#ifndef OPLUS_BUG_COMPATIBILITY`, `#ifdef OPLUS_ARCH_EXTENDS` guards removed. `record_compress_*` profiles and correct sampling-rate sets now unconditionally visible to HAL parser.

---

### PROBLEM 16 — QCOM `libspkrprot` opens PCM device 25 (missing) ✅ FIXED

**Fix:** `vendor.audio.feature.spkr_prot.enable=false` in `sm8250-common/vendor.prop`. QCOM `libspkrprot` disabled; TFA HAL handles speaker protection via `pcm_dev_tx_id=32`.

---

### PROBLEM 22 — UDFPS HBM UI-ready handshake ✅ FIXED (2026-03-11)

**Root cause:** `@2.3` bridge held an invalid `/dev/oplus_display` fd opened once at service start. If node unavailable at that instant, it stayed invalid forever.

**Fix:** Lazy reopen logic (`ensureDisplayFd()`) so each panel ioctl path recovers and opens `/dev/oplus_display` at runtime. HIDL onUiReady replay added in framework (`HidlToAidlSessionAdapter`).

**Validation (`fingerprint_fd_reopen_test_20260311_145346_60s.txt`):**
- `Opened /dev/oplus_display fd=7` ✅
- `onEnrollResult(... rem=0)` + `FingerprintEnrollFinish` shown ✅
- User confirmation: enrollment works ✅

---

### PROBLEM 23/24 — In-call audio silent + microphone dead ✅ FIXED (2026-03-10)

**Root cause chain:**
1. `platform.c` internal-codec path calls `platform_info_init(...audio_platform_info_intcodec.xml)` — no fallback.
2. Build shipped only `audio_platform_info.xml`, not `audio_platform_info_intcodec.xml`.
3. Without it, HAL defaulted to PCM 44/45 — not present on this kernel → `cannot open device 44`.

**Fix:** Deploy platform info under both names in `device.mk`.

**Call earpiece routing fix (session 11):**
- Hypothesis: `qcom,wsa-aux-dev-prefix = "SpkrLeft", "SpkrRight"` caused mixer controls to be prefixed.
- Updated `mixer_paths.xml` to write both prefixed and legacy control names.
- Kernel patch: re-evaluate `TFA_CHIP_SELECTOR` on every unmute.
- Result: handset mode correctly routes to top earpiece (2-0034, selector:1).

---

### PROBLEM 26 — Sleep of Death / battery drain ✅ FIXED (2026-03-13)

**Root cause:** P27 SELinux denial blocked Power HAL from reading `idle_state` → `mHalAutoSuspendModeEnabled=false` → kernel never enters suspend → ~2%/minute drain.

**Fix:** `r_dir_file(hal_power_default, vendor_sysfs_graphics)` in `hal_power_default.te`.
**Validation:** Overnight deep sleep confirmed stable (2026-03-13).

---

### PROBLEM 27 — Power HAL `idle_state` SELinux denial ✅ FIXED

```
r_dir_file(hal_power_default, vendor_sysfs_graphics)
```
Added to `device/oneplus/instantnoodlep/sepolicy/vendor/hal_power_default.te`. No AVC in post-flash boot capture.

---

### PROBLEM 28 — Health HAL `oplus_chg` AVC denial ✅ FIXED

Created `sepolicy/vendor/hal_lineage_health_default.te`:
```
rw_dir_file(hal_lineage_health_default, vendor_sysfs_usb_supply)
```

---

### PROBLEM 29 — Sensor ALS + pressure calibration proc denials ✅ FIXED

Updated `sepolicy/vendor/vendor_hal_oplus_sensor_default.te`:
```
rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_oplus_als_file)
rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_eng_cali_file)
```

---

### PROBLEM 30 — Bluetooth SIGABRT teardown race ✅ FIXED (2026-03-12)

**Root cause:**
- `StorageModule` destructor cleared/deleted `handler_` even though lifetime is owned by `Stack`.
- `Stack::Stop()` also tore down `stack_handler_`, causing double-clear/double-delete.

**Fixes (BT APEX source):**
- `storage_module.cc`: removed destructor-side handler clear/delete.
- `stack.cc`: always `WaitUntilStopped()` after `Clear()`; stop `stack_thread_` before deleting handler.
- `snoop_logger.cc`: removed destructor handler teardown.
- `handler.cc`: teardown-time `Post()`/`Clear()` on already-cleared handler is now no-op.

**Validation:** 8× BT toggle stress — no SIGABRT, no FORTIFY, no destroyed mutex.

---

### PROBLEM 31 — `poweroffalarm` + `wcnss_service` property set denials ✅ FIXED

- `sepolicy/vendor/vendor_poweroffalarm_app.te`: `set_prop(vendor_poweroffalarm_app, system_prop)`
- `sepolicy/vendor/property.te`: `vendor_internal_prop(vendor_cnss_daemon_prop)` + `vendor_internal_prop(vendor_vold_serialno_prop)`
- `sepolicy/vendor/property_contexts`: context entries for `persist.vendor.cnss-daemon.*` + `vendor.vold.serialno`
- `sepolicy/vendor/vendor_wcnss_service.te`: `set_prop` for both new types

---

### PROBLEM 39 — Display DPI / UI overlap ✅ FIXED (2026-03-12)

`display_id_4630947194340276609.xml`: 1440p density 560→420, 1080p 450→420.
`BoardConfig.mk`: `TARGET_SCREEN_DENSITY` 450→420.
Verification: `Physical density: 420` on device.

---

### PROBLEM 41 — Recovery build disabled ✅ FIXED (session 20)

`TARGET_NO_RECOVERY` + AB_OTA recovery filter removed. Recovery build re-enabled and live flash validated.

Distribution artifact (session 22):
```
Folder: .../releases/instantnoodlep-recovery-fastboot-20260313/
Zip SHA256: c5c6b7b9b4e06b6123c0ba2f300a491f7b6d9763a5e2a7be2e6fd062da9aaec7
```

---

### PROBLEM 42 — Black-screen + severe idle drain (PPR) ✅ FIXED (2026-03-15)

PPR property disabled. Black-screen + drain resolved. Validated by user.

---

## ADB HEALTH CHECK — Session 13 (2026-03-11) — All Major Subsystems PASS

| Subsystem | Result |
|-----------|--------|
| Sensors | `Total 56 h/w sensors, 56 running` ✅ |
| Audio | HAL running, `mMode=NORMAL`, speaker routing active ✅ |
| Camera | 8 devices detected (0–7), all closed-idle ✅ |
| Telephony/SIM | SIM1 `IN_SERVICE` LTE (A1 / 232-01), rsrp=-105, level=3 ✅ |
| WiFi daemon | `wificond` running ✅ |
| Display composer | `vendor.qti.hardware.display.composer-service` running ✅ |
| `mHalAutoSuspendModeEnabled` | **true** ✅ |
| Screen-off suspend blockers | Both `false` ✅ |
| Deep sleep overnight soak | ✅ Stable (2026-03-13) |
| SIM internet / LTE / call | ✅ LTE Band 3, rmnet_data1 UP, ping 0% loss |
| WiFi + LTE coexistence | ✅ Both routing simultaneously, no coex errors |
| Current boot AVC | Only `bluetooth_lea_prop` upstream denial — all device-specific AVC clean ✅ |

---

## VERIFIED — NO ACTION NEEDED

| Item | Verified |
|------|---------|
| `audio_policy_configuration.xml` loading from XML | ADB: `Config source: /vendor/etc/audio_policy_configuration.xml` ✅ |
| `audio_platform_info_intcodec.xml` deployed as `audio_platform_info.xml` | `device.mk` ✅ |
| Generic kona `audio_platform_info.xml` removed from `common.mk` | ✅ |
| `audio_io_policy.conf` deployed, 0× `#ifdef` guards | ADB: `grep -c ifdef` → `0` ✅ |
| `audio_tuning_mixer.txt` deployed to vendor | ADB ✅ |
| TFA flags `external_speaker*.enable=true` | `sm8250-common/vendor.prop` ✅ |
| `vendor.audio.feature.spkr_prot.enable=false` | `sm8250-common/vendor.prop` ✅ |
| `audio_amplifier.kona.so` present and loading; TX mapped to device 32 | ADB: `pcm_dev_tx_id = 32` ✅ |
| `AUDIO_FEATURE_ENABLED_EXT_AMPLIFIER := true` | `BoardConfigCommon.mk` ✅ |
| TFA9874 kernel driver probed on I2C 0x34 + 0x35 | ADB: `TFA9874 detected` ✅ |
| `persist.vendor.audio.speaker.prot.enable=true` | ADB ✅ |
| ACDB files at `/odm/etc/acdbdata/` | `instantnoodlep-vendor.mk` ✅ |
| `tfa98xx.cnt` firmware at `/odm/firmware/` | ADB ✅ |
| All 56 sensors running | ADB: `Total 56 h/w sensors, 56 running` ✅ |
| PCM device 32 (`pcmC0D32c`) exists in ALSA card | ADB ✅ |
| PCM devices 24–28 absent (as expected) | ADB confirms D24–D28 missing ✅ |
| TFA9874 calibration: L=6294 mΩ, R=6023 mΩ — within 5000–8000 mΩ | ADB ✅ |
| 24-bit `deep_buffer_24` (app_type 69936) active at 48 kHz | ADB ✅ |
| Speaker produces audible output | Confirmed live — session 5 ✅ |

---

## SESSION 23 CLOSEOUT — user/userdebug split

### Build variants
- `userdebug`: `ro.setupwizard.mode=DISABLED` (faster debug cycles)
- `user`: SetupWizard enabled (shipping variant)
- Build fingerprint/desc set to `release-keys`

### Separated output dirs
- `user OUT_DIR`: `/home/lal3lu/android/pixelos/out_user` (symlink → `/mnt/androidbuild/out-user`)
- `userdebug OUT_DIR`: `/home/lal3lu/android/pixelos/out_userdebug`
- Shared ccache: `/mnt/androidbuild/ccache`

### Scripts added
- `tools/build_variant.sh`
- `tools/build_user.sh`
- `tools/build_userdebug.sh`
- `tools/flash_payload_slot_b.sh`

### Slot mapping (84064e34, 2026-04-03)
- `_a` = `user`
- `_b` = `userdebug`
