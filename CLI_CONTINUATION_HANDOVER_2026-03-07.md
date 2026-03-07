# PixelOS A16 OnePlus 8 Pro CLI Handover (2026-03-07)

## 1) Current repository context
- Repo path: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep`
- Branch: `a16-bringup-fixes`
- HEAD: `52adc43`
- Worktree: dirty (expected during bring-up; do not reset)

## 2) What was already validated as working
- Black screen after unlock: fixed.
- Lock PIN and fingerprint unlock flow: working in latest successful state noted in session.
- Wi-Fi/Bluetooth/charging: previously confirmed working.
- Volume panel side (left): enabled via SystemUI overlay.

## 3) Known regressions still under active debugging
- No speaker audio output in some boots/tests (YouTube plays, no sound).
- Shake/gesture behavior incomplete or inconsistent depending on build/flash iteration.

## 4) Most important pending patch (added but not yet built/flashed)
- New SELinux fix file:
  - `sepolicy/vendor/vendor_hal_oplus_sensor_default.te`
- Purpose:
  - Allows sensor HAL access to persist engineer/sensors dirs blocked at boot.
- Rules added:
  - `r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_engineer_file)`
  - `r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_sensors_file)`
- Status:
  - File exists in tree.
  - Not yet included in a rebuilt/flashed `vendor.img` after timestamp `2026-03-06 18:07`.

## 5) File map by subsystem (what each file controls)

### Build wiring
- `BoardConfig.mk`
  - Adds `BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor`
- `device.mk`
  - Copies init overrides and IDC:
    - `init/zz_fps_hal_override.rc` -> `/odm/etc/init/`
    - `init/zz_vl53l1_daemon_override.rc` -> `/odm/etc/init/`
    - `init/zz_vendor.aidl_hal_overrides.rc` -> `/vendor/etc/init/`
    - `input/touchpanel.idc` -> `/vendor/usr/idc/`
  - Enables LiveDisplay soong flags:
    - `ENABLE_SE=true`
    - `ENABLE_PA=true`
  - Sets `PRODUCT_PRECOMPILED_SEPOLICY := false`
- `aosp_instantnoodlep.mk`
  - `ro.setupwizard.mode=DISABLED`
  - Optional insecure adb debug mode gated by:
    - `INSECURE_ADB_DEBUG=true`
- `vendor.prop`
  - `persist.vendor.audio.speaker.prot.enable=true`

### Init overrides / services
- `init/zz_vendor.aidl_hal_overrides.rc`
  - `vendor.sensors-hal-multihal` override (AIDL `ISensors/default`)
  - `vendor.livedisplay-hal` override
- `init/zz_vendor.touch-hal.override.rc`
  - `vendor.touch-hal` override (Lineage touch AIDL interfaces)
- `init/zz_fps_hal_override.rc`
  - Fingerprint HAL override service and interfaces
- `init/zz_vl53l1_daemon_override.rc`
  - Re-enables TOF daemon as `oneshot`, user `cameraserver`
- `init/init.instantnoodlep-bringup.rc`
  - Starts touch/fingerprint related services on `post-fs-data`

### SELinux overlays added/restored
- `sepolicy/vendor/hal_audio_default.te`
- `sepolicy/vendor/hal_camera_default.te`
- `sepolicy/vendor/hal_fingerprint_default.te`
- `sepolicy/vendor/hal_lineage_livedisplay_qti.te`
- `sepolicy/vendor/hal_power_default.te`
- `sepolicy/vendor/hal_sensors_default.te`
- `sepolicy/vendor/horae.te`
- `sepolicy/vendor/oplus_touchdaemon.te`
- `sepolicy/vendor/system_server.te`
- `sepolicy/vendor/vendor_hal_perf_default.te`
- `sepolicy/vendor/vendor_sensors.te`
- `sepolicy/vendor/vl53l1_daemon_main.te`
- `sepolicy/vendor/genfs_contexts`
- `sepolicy/vendor/vendor_hal_oplus_sensor_default.te` (newest, pending rebuild/flash)

### UI overlays / input
- `overlay/OPlusFrameworksResTarget/res/values/config.xml`
  - Alert slider support + key handler entries
- `overlay/OPlusSystemUIResTarget/res/values/custom_config.xml`
  - Sets volume panel to left side
- `input/touchpanel.idc`
  - Marks touchpanel as internal touch screen

### Long-form changelog
- `BUILD_FIXES_LOG.md`
  - Current file has entries up to Issue 177.
  - New `vendor_hal_oplus_sensor_default` policy addition should be logged as next issue.

## 6) Important logs and artifacts

### Debug logs
- `/tmp/reboot_startup_20260306_184026.log` (key startup AVC evidence)
- `/tmp/after_flash_long_20260306_182913.log`
- `/tmp/after_flash_baseline_20260306_182716.log`
- `/home/lal3lu/bootloop-logs/OT_fixes.txt`
- `/home/lal3lu/bootloop-logs/OT_fixes_after_flash.txt`

### Current built images in output dir
- `/home/lal3lu/android/pixelos/out/target/product/instantnoodlep/vendor.img` (Mar 6 18:07)
- `/home/lal3lu/android/pixelos/out/target/product/instantnoodlep/odm.img` (Mar 6 18:07)
- `/home/lal3lu/android/pixelos/out/target/product/instantnoodlep/boot.img` (Mar 6 12:16)
- `/home/lal3lu/android/pixelos/out/target/product/instantnoodlep/lineage-.zip` (Mar 5 19:07)

## 7) Last concrete root-cause evidence (from startup log)
- Domain: `vendor_hal_oplus_sensor_default`
- Denials:
  - `search` on `vendor_persist_engineer_file`
  - `search` on `vendor_persist_sensors_file`
- Symptom correlation:
  - Repeated attempts to start `android.hardware.sensors.ISensors/default`.
- Why next step is vendor rebuild:
  - Fix is in `device/.../sepolicy/vendor`, so vendor sepolicy/image must be rebuilt and flashed.

## 8) Resume commands (recommended exact order)

```bash
set -euo pipefail

cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-userdebug

# 1) Validate policy first
m sepolicy_neverallows -j10

# 2) Rebuild only vendor (patch is vendor sepolicy)
m vendorimage -j10

# 3) Flash to active slot b target
adb reboot fastboot
fastboot --set-active=b
fastboot flash vendor_b /home/lal3lu/android/pixelos/out/target/product/instantnoodlep/vendor.img
fastboot reboot

# 4) Capture reboot-startup log after patch
adb wait-for-device
adb logcat -b all -c
adb reboot
adb wait-for-device
sleep 70
adb logcat -b all -d -v threadtime > /tmp/reboot_startup_after_vendor_hal_sensor_fix.log

# 5) Check if the specific sensor-HAL denials are gone
rg -n "vendor_hal_oplus_sensor_default|vendor_persist_engineer_file|vendor_persist_sensors_file|ISensors/default|wait_for_mandatory_sensors" /tmp/reboot_startup_after_vendor_hal_sensor_fix.log
```

## 9) Audio-focused repro capture after sensor patch

```bash
adb logcat -b all -c
# Reproduce: open YouTube, play media, volume max
adb logcat -b all -d -v threadtime > /tmp/audio_repro_after_sensorfix.log
rg -n "avc:  denied|audio_hw|AudioFlinger|audiopolicy|AUDIO_DEVICE_OUT_SPEAKER|spkr|speaker|agm|acdb|mute|silence" /tmp/audio_repro_after_sensorfix.log
```

## 10) Safety notes
- Keep slot target explicit as `b` in all flashes for this phase.
- Avoid full-flash unless partition mismatch requires it.
- Do not run destructive git cleanup while bring-up branches/forks are being compared.
