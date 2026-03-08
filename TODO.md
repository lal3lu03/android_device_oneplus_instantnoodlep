# Audio, Sensor & System Fix TODO
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)  
**Last updated:** 2026-03-08 (session 4 — Option A fix applied, audio_io_policy.conf fully cleaned, new SELinux .te files)  
**Branch:** `a16-bringup-fixes`

> `✅ FIXED` = verified correct in the current tree (file read or ADB confirmed).  
> `🔴 OPEN` = known bug, actionable fix listed.  
> `🟡 OPTIONAL` = low-priority, won't block audio/sensor function.

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
| 12 | Audio | TFA9874 kernel DT missing `tfa_use_i2s` — both chips bind to PRIMARY I2S, HAL routes to TERT_MI2S → data never reaches amp | **P0** | 🔴 OPEN |
| 13 | Audio | WSA DAPM route failures at boot — `SpkrLeft IN` / `SpkrRight IN` widgets missing from TFA DAPM graph | P1 | 🔴 OPEN |
| 14 | Audio | `audio_io_policy.conf` dead 24-bit profiles — `#ifdef OPLUS_FEATURE_PLAYBACK_24BIT` treated as comment, app_type falls back to default | P2 | ✅ FIXED |
| 15 | SELinux | `/dev/oplus_sensor_devinfo` unlabeled (`file_contexts` untracked) | P2 | 🟡 OPTIONAL |
| 16 | Audio | `spkr_prot_start_processing` opens PCM device 25 (doesn't exist) — QCOM spkr_prot conflicts with TFA HAL | **P0** | 🟠 FIX APPLIED — needs device test |
| 17 | SELinux | `shell.te`, `tri-state-key-calibrate.te`, `vendor_qti_init_shell.te` untracked | P2 | ✅ FIXED |

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

## AUDIO STATUS — 3 OPEN PROBLEMS (P0 root cause identified this session)

All config files confirmed deployed: `audio_policy_configuration.xml` loading from XML, `audio_io_policy.conf` 0× `#ifdef`, `audio_tuning_mixer.txt` present, `spkr_prot.enable=true`, `external_speaker*.enable=true`. TFA9874 probes OK on I2C 0x34+0x35. AudioFlinger writes signal. Speaker still silent.

**Current P0 blocker (session 3 finding):** `spkr_prot_start_processing: cannot open device 25 for card 0: No such file or directory` — QCOM `libspkrprot` retries every ~5 seconds, `enable_snd_device` always returns error, speaker is never enabled. See Problem 16.

---

### PROBLEM 11 — `vendor.audio.feature.spkr_prot.enable=false` (regression) ✅ FIXED

**File:** `sm8250-common/vendor.prop`  
**Fix applied:** `vendor.audio.feature.spkr_prot.enable=false` → `true`  
**Confirmed on device (session 3):** `[vendor.audio.feature.spkr_prot.enable]: [true]` ✅

> **NOTE:** Enabling `spkr_prot` surfaced a new problem — see **Problem 16**. With `spkr_prot=true` the QCOM `libspkrprot` tries to open PCM device 25 for VI-feedback TX, which doesn't exist on this kernel. Turning this flag on moved the failure from "library not loaded" to "PCM open error", which gave us the precise root cause.

---

### PROBLEM 12 — TFA9874 kernel DT missing `tfa_use_i2s` → DAI bound to wrong I2S bus ⚠️ LIKELY ROOT CAUSE

**Evidence:** Both TFA9874 probes log `no defined tfa_use_i2s, use primary i2s`  
**Source:** `kernel/oneplus/sm8250` device tree, TFA9874 node

The `tfa98xx` driver reads a device-tree property (typically `oneplus,tfa_i2s_id` or `nxp,tfa_use_i2s`) to know which CPU-side MI2S bus it is wired to. Without the property, both chips default to "primary i2s" (MI2S instance 0).

The audio HAL and mixer paths configure the speaker output on **TERT_MI2S_RX** (MI2S instance 2, confirmed in `mixer_paths.xml`: `TERT_MI2S_RX Audio Mixer MultiMedia5 = 1`). The codec DAI link in the machine driver must match.

If the TFA9874 codec DAI registers itself under PRIMARY I2S but the ALSA backend configured by the HAL is TERT_MI2S, then:
- The ALSA session opens on TERT_MI2S on the DSP side
- The codec (TFA9874) is clocked/enabled on PRIMARY I2S
- Audio data flows into TERT_MI2S but the TFA chip is listening on a different I2S bus
- **No audio reaches the speaker**

**Fix area:** Add the correct `tfa_use_i2s` or `oneplus,tfa_i2s_id` property to the TFA9874 I2C device tree nodes (`sound-tfa98xx` or equivalent in the board DTS for SM8250). The correct value is `2` (TERT MI2S).

---

### PROBLEM 13 — WSA DAPM route failures at every boot

**Evidence:** `ASoC: no sink widget found for SpkrLeft IN` / `SpkrRight IN`  
**Kernel log:**
```
kona-asoc-snd: ASoC: Failed to add route WSA_SPK1 OUT -> direct -> SpkrLeft IN
kona-asoc-snd: ASoC: Failed to add route WSA_SPK2 OUT -> direct -> SpkrRight IN
```

The kona machine driver registers DAI links and DAPM routes for WSA smart speaker (a QCOM-native amp found on Snapdragon reference designs). The OnePlus 8 Pro uses TFA9874 instead — TFA9874's DAPM output widget is named differently (e.g., `SPKL` / `SPKR` or `OUT`) and does not expose `SpkrLeft IN` / `SpkrRight IN`. These DAPM failures mean the kernel ALSA graph for the speaker path has unresolvable routes.

Depending on whether the kona machine driver uses the WSA routes as a required path to enable TERT_MI2S, this could prevent the TERT_MI2S backend PCM device from opening. Related to Problem 12 — if the DT correctly sets `tfa_use_i2s`, the machine driver may register TFA-appropriate widget names instead.

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

### PROBLEM 16 — `spkr_prot_start_processing: cannot open device 25` � FIX APPLIED — needs device test

**Source:** ADB logcat session 3 (repeating every ~5 s):
```
E audio_hw_spkr_prot: spkr_prot_start_processing: spkr snd_device(95: speaker-protected)
E audio_hw_spkr_prot: spkr_prot_start_processing: cannot open device 25 for card 0: No such file or directory
E audio_hw_primary: enable_snd_device: spkr_start_processing failed
```

**Effect:** `enable_snd_device()` always returns error → speaker is never enabled → complete silence.

**Root cause:** Two speaker-protection stacks run simultaneously:
- `libspkrprot.so` (QCOM) — hardcoded default opens `pcmC0D25c`; that device does **not exist** (ALSA gap: D23 → D29). XML override to D32 not applied at runtime.
- `audio_amplifier.kona.so` (TFA HAL) — already maps to `pcm_dev_tx_id = 32` (`pcmC0D32c` **exists**) ✅

QCOM `libspkrprot` intercepts `enable_snd_device` before TFA HAL runs, causing abort.

**Fix applied (session 4):** Option A — `vendor.audio.feature.spkr_prot.enable=false` in `sm8250-common/vendor.prop`  
→ disables QCOM `libspkrprot` loading, removing the PCM-25 failure entirely.  
→ TFA HAL (`audio_amplifier.kona.so`) handles speaker protection exclusively via PCM D32.

#### ⚠️ Prop name table — two different properties, no conflict

| Property | Set where | Value | Purpose |
|----------|-----------|-------|---------|
| `vendor.audio.feature.spkr_prot.enable` | `sm8250-common/vendor.prop` | **`false`** | Controls whether QCOM `libspkrprot.so` loads during `adev_open`. **Must be false** to avoid PCM-25 failure. |
| `persist.vendor.audio.speaker.prot.enable` | `bringup.rc` + `migration.rc` | **`true`** | Tells TFA HAL to apply saved calibration data. **Must be true** for correct TFA amplitude. |

These are unrelated props controlling different subsystems. The comment in `bringup.rc` ("Enable QCOM speaker protection") is **misleading** — it actually sets the TFA persist prop. No action needed on the value; optionally fix the comment.

**Needs:** flash next build and verify `spkr_prot_start_processing` error is gone from logcat, and audio plays.

---

## SENSOR STATUS — COMPLETE ✅

Live ADB check (`dumpsys sensorservice`) confirms **Total 56 h/w sensors, 56 running**.  
All types working: lsm6dsm (accel+gyro), mmc5603x (mag), tcs3701 (ALS), stk2232 (proximity), SX9324UP (SAR), OPlus custom (infrared, elevator, OCA, AMD, pedometer), UDFPS.  
**No further sensor work needed.**

---

## REMAINING ITEMS

### System — `lpm_levels.sleep_disabled=1` ✅ FIXED in this session (`BoardConfigCommon.mk`)

Removed. Will require `boot.img` rebuild when kernel is rebuilt for Problem 12 DT fix.

---

## NEXT BUILD STEPS

### Step 1 — Flash and verify P16 fix (Option A applied in source)

Option A (`vendor.audio.feature.spkr_prot.enable=false`) is now set in `sm8250-common/vendor.prop`. Build and flash `vendor` partition, then:
```bash
# Confirm prop landed
adb shell getprop vendor.audio.feature.spkr_prot.enable   # expect: false
# Confirm no PCM-25 error
adb logcat | grep spkr_prot_start_processing
# Play audio — speaker should now produce sound
```
If audio plays → Problem 16 **CONFIRMED FIXED**. If still silent, check logcat for new error.

### Step 2 — Identify PCM device 32 name (requires root / eng build)
```bash
adb shell cat /proc/asound/pcm | grep "32:"
# expected: "00-32: Tertiary MI2S TX Hostless Capture ..."
# if name differs, update SPK_VI_HOSTLESS in audio_platform_info_intcodec.xml
```

### Step 3 — Kernel DT fix for Problems 12 & 13 (requires boot.img rebuild)
- Find TFA9874 DTS node in `kernel/oneplus/sm8250`
- Add `oneplus,tfa_i2s_id = <2>` (or equivalent property name from `tfa98xx.c`)
- Rebuild `bootimage` and flash `boot_b`
- Recheck WSA DAPM route errors (Problem 13 may resolve with correct DT binding)

### Step 4 — git add new untracked files
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep
git add sepolicy/vendor/shell.te sepolicy/vendor/tri-state-key-calibrate.te sepolicy/vendor/vendor_qti_init_shell.te
git add init/sensor_recover.sh init/zz_audio_prop_migration.rc
git add TODO.md
```

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

