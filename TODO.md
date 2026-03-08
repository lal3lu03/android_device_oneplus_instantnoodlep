# Audio, Sensor & System Fix TODO
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)  
**Last updated:** 2026-03-08 (session 5 — audio confirmed working, full diagnostic pass)  
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

## SENSOR STATUS — COMPLETE ✅

Live ADB check (`dumpsys sensorservice`) confirms **Total 56 h/w sensors, 56 running**.  
All types working: lsm6dsm (accel+gyro), mmc5603x (mag), tcs3701 (ALS), stk2232 (proximity), SX9324UP (SAR), OPlus custom (infrared, elevator, OCA, AMD, pedometer), UDFPS.  
**No further sensor work needed.**

---

## REMAINING ITEMS

All P0 audio blockers resolved. Remaining items are cosmetic kernel/DT issues (P13, P18–P21).

---

## NEXT BUILD STEPS

All P0 blockers are resolved and confirmed on device (session 5). No mandatory build steps remain.

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

