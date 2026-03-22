# Handover: Audio + Shake Debug (slot b)

**Date:** 2026-03-07
**Device:** OnePlus 8 Pro (`instantnoodlep`)
**Active slot:** `_b`
**Goal in this session:** continue runtime bring-up for audio output + shake control (accelerometer/gyro path)

## 1. What was done in this session

### 1.1 Read handover context
- Reviewed:
  - `BUILD_FIXES_LOG.md`
  - `CLI_INTRO_NEXT_STEPS.md`

### 1.2 Audio-side code change applied
- Edited `vendor.prop` and removed the local persistent speaker-protection override.
- Effective result in tree: no `persist.vendor.audio.speaker.prot.enable=*` line is present now.

### 1.3 Build + flash performed
- Built:
  - `vendorimage`
  - `odmimage`
- Flashing details:
  - Bootloader-level flash to `vendor` failed with `(vendor_b) No such partition`.
  - Correct method for this device is userspace fastboot (`fastbootd`) and then flashing `vendor_b` / `odm_b`.
- Successful flash sequence that worked:
  1. `adb reboot bootloader`
  2. `fastboot reboot fastboot`  (enter fastbootd)
  3. `fastboot flash vendor_b out/target/product/instantnoodlep/vendor.img`
  4. `fastboot flash odm_b out/target/product/instantnoodlep/odm.img`
  5. `fastboot reboot`

### 1.4 Runtime capture and boot capture performed
- 40s runtime capture (while user reproduced):
  - `/tmp/runtime_capture_20260307_131602.log`
- Fresh reboot startup capture:
  - `/tmp/boot_capture_20260307_131800.log`

## 2. Current observed state (post-flash)

### 2.1 Sensors / shake are still broken
- `dumpsys sensorservice` shows only 12 sensors (ALS/prox/SAR/rear-light + UDFPS), still no accel/gyro stack.
- `Trustlet_Onbody` reports: device lacks accelerometer.
- Boot still shows repeated lazy-start attempts for:
  - `android.hardware.sensors.ISensors/default`
- Sensor HAL eventually appears, but accel/gyro never surface.

### 2.2 Audio still unresolved
- Audio output still reported broken by user.
- Important nuance: removing the `persist.vendor.audio.speaker.prot.enable` line from build props does **not** guarantee runtime reset if the persist prop is already stored in `/data` from earlier boots.
- Attempt to set at runtime from adb shell failed (permission denied), so persisted value may still be stale.

## 3. Key evidence snippets

### 3.1 Boot capture indicators
From `/tmp/boot_capture_20260307_131800.log`:
- Repeated:
  - `ISensors/default ... could not be found trying to start it as a lazy AIDL service`
  - `ctl.interface_start for 'aidl/android.hardware.sensors.ISensors/default'`
- Later:
  - `Trustlet onbody not supported, device lacks accelerometer`

### 3.2 Runtime capture indicators
From `/tmp/runtime_capture_20260307_131602.log`:
- Continuous ambient-light events from sensors HAL.
- No accel/gyro event stream observed.

## 4. Repository state at end of session

`git status --short` (in `device/oneplus/instantnoodlep`):
- Modified:
  - `BUILD_FIXES_LOG.md`
  - `device.mk`
  - `init/init.instantnoodlep-bringup.rc`
  - `sepolicy/vendor/hal_fingerprint_default.te`
  - `vendor.prop`
- Untracked:
  - `CLI_INTRO_NEXT_STEPS.md`
  - `build.log`
  - `init/sensor_recover.sh`
  - `out/`
  - `sepolicy/vendor/file_contexts`
  - `sepolicy/vendor/property.te`
  - `sepolicy/vendor/property_contexts`
  - `sepolicy/vendor/tri-state-key-calibrate.te`
  - `sepolicy/vendor/vendor_qti_init_shell.te`

## 5. What likely matters next (highest priority)

### P0: force-correct speaker protection property migration
Reason:
- If `persist.vendor.audio.speaker.prot.enable` was previously persisted as `false`, removing the build prop line alone is insufficient.

Action options for next session:
1. Add one-time init migration in a vendor-loaded `.rc`:
   - `setprop persist.vendor.audio.speaker.prot.enable true`
   - Trigger on early boot/post-fs-data so init context can write it.
2. Or clear stale persist property via root/recovery path.

### P0: isolate why accel/gyro registration never appears
Reason:
- HAL process lives, some sensors publish, but motion sensors remain absent.
- This suggests a lower-layer SSC/ADSP or sensor-registry path issue, not total HAL death.

Immediate checks next session:
1. Collect **very early** boot logs again and grep for:
   - `sscrpcd`
   - `apps_dev_init failed`
   - `remote_handle_open`
   - `adsp_default_listener`
   - `Transport endpoint is not connected`
2. Confirm no startup SELinux denials touching:
   - sensor persist registry files
   - `sscrpcd` / `sensors.qti` domains
3. Compare current `sensor_recover.sh` behavior to known-good branch and avoid altering persisted sensor calibration/registry content beyond minimum required path creation.

## 6. Exact command blocks for next session

### 6.1 Build and flash (slot b)
```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-userdebug
m vendorimage odmimage -j$(nproc)

adb reboot bootloader
fastboot reboot fastboot
fastboot flash vendor_b out/target/product/instantnoodlep/vendor.img
fastboot flash odm_b out/target/product/instantnoodlep/odm.img
fastboot reboot
```

### 6.2 Boot capture template
```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/boot_capture_${ts}.log
adb shell logcat -b all -c
adb reboot
adb wait-for-device
adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
adb shell logcat -b all -d -v threadtime > "$out"

rg -n "ISensors/default|sscrpcd|apps_dev_init failed|remote_handle_open|adsp_default_listener|Transport endpoint|accelerometer|gyro|onbody|spkr_prot|speaker-protected" "$out"
```

### 6.3 Interactive 40s runtime capture template
```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/runtime_capture_${ts}.log
adb shell logcat -b all -c
timeout 40s adb shell logcat -b all -v threadtime > "$out"

rg -n "audio_hw|spkr|speaker|sensors-hal|accelerometer|gyro|shake|gesture|ISensors/default|avc: denied" "$out"
```

## 7. Manual device-side actions needed from user next session

1. Reproduce during runtime capture:
   - Play YouTube audio
   - Toggle shake control on/off
2. (Recommended) Enable `ADB root` in Developer options for deeper kernel/permission diagnostics:
   - Developer options -> Rooted debugging / ADB root (wording varies by build)
   - Without this, `dmesg` and several `/mnt/vendor/persist/*` checks are blocked.

## 8. Cross-repo comparison note captured in-session

A parallel explorer suggested two rollback candidates for audio sanity testing:
1. Revert `TARGET_AUDIO_PLATFORM_INFO_FILE := ...audio_platform_info_intcodec.xml` override in `device.mk` (use common default for test).
2. Ensure speaker protection is explicitly enabled (`persist.vendor.audio.speaker.prot.enable=true`) for migration from stale persisted false state.

Treat this as a hypothesis to validate, not final root cause proof.
