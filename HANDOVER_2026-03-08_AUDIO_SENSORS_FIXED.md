# Handover: Audio & Sensor Bring-up Complete
**Date:** March 8, 2026  
**Device:** OnePlus 8 Pro (`instantnoodlep`)  
**Status:** SPEAKER AUDIO WORKING | ALL 56 SENSORS LIVE | SYSTEM STABLE

---

## 1. CURRENT STATE SUMMARY
The OnePlus 8 Pro has reached a functional bring-up state for PixelOS 16.1. The major P0 blockers (silent audio and missing sensors) have been resolved.

### Subsystem Status
- **Audio:** **WORKING.** High-quality 24-bit 48kHz output is active. Dual TFA9874 amplifiers are correctly calibrated and bound to Tertiary MI2S.
- **Sensors:** **WORKING.** All 56 system and motion sensors are operational (LSM6DSM, MMC5603X, etc.). Shake gestures are functional.
- **Power:** **FIXED.** CPU deep sleep (LPM) is restored, preventing thermal throttling and excessive battery drain.
- **Stability:** **STABLE.** No bootloops, EDL crashes, or major SELinux denials.

---

## 2. KEY RECENT FIXES (Session 10)
- **TFA Binding:** Corrected the TFA amplifier registration from SoundWire to I2C auxiliary devices.
- **Pinctrl Deferral:** Implemented `EPROBE_DEFER` in the machine driver and `msm-cdc-pinctrl` to resolve race conditions with ADSP.
- **Audio-Extend:** Enabled and patched the `audio-extend` techpack to dynamically support the OPlus-specific speaker configuration.
- **DAPM Mismatch:** Switched to base widget names in `ignore_suspend` calls to match component-specific DAPM contexts.
- **DT Cleanup:** Added `qcom,tdm-max-slots` and `oplus,dac-vendor` to clear boot-time warnings.

---

## 3. VERIFICATION COMMANDS

### Audio Playback & Logs
```bash
# Start a test playback
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main -d "https://m.youtube.com/watch?v=BhrpaOP2IUM"

# Check TFA startup and calibration
adb shell "logcat -d | grep -i tfa_dev_start"
# Expected: "tfa_dev_start success (0)" for both 0x34 and 0x35

# Verify 24-bit profile selection
adb shell "logcat -d | grep -i deep_buffer_24"
```

### Sensor Status
```bash
# Check running sensors
adb shell dumpsys sensorservice | grep -A 56 "Active sensors"
# Expected: 56 sensors running
```

---

## 4. REMAINING COSMETIC ITEMS
These items appear in the logs but do not affect functionality:
- **P13:** Legacy WSA DAPM routes (`SpkrLeft IN`, etc.) still show "unknown pin" at boot.
- **P18:** `Audio Stream Capture 32 App Type Cfg` mixer control is missing (non-fatal).
- **P19:** `volume_listener` reports one gain-dep cal failure on the first write (automatically retried and succeeds).

---

## 5. NEXT STEPS FOR MAINTAINER
1. **Commit Working State:** All changes are currently in the working tree. 
   - `device/oneplus/instantnoodlep`
   - `device/oneplus/sm8250-common`
   - `kernel/oneplus/sm8250` (techpack and dts)
   - `hardware/qcom-caf/sm8250/audio`
   - `hardware/oplus/audio_amplifier`
2. **Cleanup:** Optional removal of redundant WSA route definitions in `kona.c` to fully eliminate boot-time log noise.
3. **Validation:** Perform a long-term stability test and verify Bluetooth audio/headset jack transitions.

