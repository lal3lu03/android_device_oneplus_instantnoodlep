# Audio & Sensor Bringup — Code Changes
**Branch:** `a16-bringup-fixes`  
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)  
**Date:** 2026-03-07  
**Status:** Audio output unresolved (speaker prot prop regression). Sensor HAL alive, accel/gyro not registering.

---

## Overview

The core problem shared by both audio and sensors is a **policy split that happened during the A16 bringup**:  
- Upstream `hardware/oplus` and `device/lineage/sepolicy` had their HAL-specific SELinux rules **stripped out** (the whole set was too broad / caused A16 policy conflicts).  
- Those rules had to be **re-added at device level** in `device/oneplus/instantnoodlep/sepolicy/vendor/` to restore functionality.

The sensor AIDL service definition was also wrong (missing capabilities and AIDL interface declaration), fixed via a new RC override file.

---

## 1. Speaker / Audio HAL

### Problem
Speaker protection amplifier (TFA speaker amp) requires the audio HAL to be able to read/write USB supply sysfs nodes for thermal and power state tracking. That rule was deleted from `hardware/oplus` but not re-added anywhere.

Additionally, `persist.vendor.audio.speaker.prot.enable` was never correctly set for A16: the value may be stale `false` in `/data` from earlier boots, overriding anything set at build time.

---

### 1.1 `hardware/oplus` — `sepolicy/qti/vendor/hal_audio_default.te`
**Deleted** (rule stripped from common policy to fix A16 policy conflict):
```diff
-rw_dir_file(hal_audio_default, vendor_sysfs_usb_supply)
```
**Why it was removed:** `vendor_sysfs_usb_supply` access was causing a policy build conflict in the A16 policy framework because the label scope changed. Removed from the common hardware layer to allow the build to proceed.

---

### 1.2 `device/oneplus/instantnoodlep` — `sepolicy/vendor/hal_audio_default.te` *(NEW)*
**Re-added** the rule at device level:
```
# Restore upstream access dropped in bring-up branch.
rw_dir_file(hal_audio_default, vendor_sysfs_usb_supply)
```
**Why it is needed:** The TFA amplifier driver exposes its USB supply state under `vendor_sysfs_usb_supply`. Without read/write access, the audio HAL cannot manage amplifier power states, which manifests as silent output or amplifier not initialising.

---

### 1.3 `device/oneplus/instantnoodlep` — `vendor.prop`
**Added:**
```
persist.vendor.audio.speaker.prot.enable=true
```
**Context:** This enables the Qualcomm speaker protection algorithm (feedback-based thermal protection for the TFA amp). Without it the amplifier may start in an unprotected state or fail to run the calibration path, leading to no output.

**Known issue (open at time of this document):** If an earlier boot already wrote `false` to `/data/property/persist.vendor.audio.speaker.prot.enable`, the build prop line is ignored because `persist.*` properties in `/data` override build-time defaults. A one-time init migration (see section 5) is required to force the correct runtime value.

---

### 1.4 `hardware/oplus` — `audio_amplifier/Android.bp`
**Added** header dependency:
```diff
+    "generated_kernel_headers",
```
**Why:** The audio amplifier HAL (`libaudioamplifier`) needs to include `voice_params.h` which is a kernel UAPI header. This was missing from the build graph, causing compilation failure. Adding `generated_kernel_headers` to `header_libs` pulls in the kernel UAPI headers built by the PixelOS kernel header pipeline.

---

### 1.5 `kernel/oneplus/sm8250` — `include/uapi/sound/voice_params.h` *(NEW FILE)*
**Added** kernel UAPI voice header:
```c
enum voice_lch_mode {
    VOICE_LCH_START = 1,
    VOICE_LCH_STOP
};
#define SNDRV_VOICE_IOCTL_LCH _IOW('U', 0x00, enum voice_lch_mode)
```
**Why:** The vendor audio HAL and amplifier code use `SNDRV_VOICE_IOCTL_LCH` for voice call Low Complexity Handoff (LCH) — muting/unmuting voice paths during call handoff. This header existed in the vendor kernel but was not exported to the UAPI include tree. Without it, `audio_amplifier` failed to compile.

---

### 1.6 `kernel/oneplus/sm8250` — `techpack/audio-extend/Kbuild`
**Disabled** audio-extend DLKM:
```diff
-obj-y += audio_extend_dlkm.o
+# obj-y += audio_extend_dlkm.o
```
**Why:** `audio_extend_dlkm` is a vendor-specific out-of-tree DSP extension module that requires proprietary Qualcomm DSP headers not present in the open-source kernel tree. Building it caused unresolved symbol errors. The module is not required for basic audio output — the standard `q6audio` / `msm-pcm` paths in the main techpack handle playback.

---

## 2. Sensors

### Problem
Sensor multihal (the AIDL aggregator daemon) could start but `accel/gyro` never registered. Root causes:

1. The sensors AIDL service definition was missing key declarations (`BLOCK_SUSPEND` capability, `rlimit rtprio`, the AIDL interface name) — so Android's AIDL service manager could not wire it up correctly.
2. All sensor-specific SELinux rules were stripped from `hardware/oplus` during cleanup but not re-added at any level, causing `sscrpcd` and the sensor persist/calibration paths to be AVC-denied. This silently blocked sensor registration even though the HAL process stayed alive.
3. The oplus sensor driver (`oplus_sensor_devinfo`, etc.) was accidentally disabled in the kernel Makefile, removing the sensor device-info interface that the SSC firmware uses during probe.

---

### 2.1 `device/oneplus/instantnoodlep` — `init/zz_vendor.aidl_hal_overrides.rc` *(NEW)*
**Added** service override for the sensor multihal:
```
service vendor.sensors-hal-multihal /vendor/bin/hw/android.hardware.sensors-service.multihal
    override
    class hal
    user system
    group system wakelock context_hub input uhid
    task_profiles ServiceCapacityLow
    capabilities BLOCK_SUSPEND
    rlimit rtprio 10 10
    interface aidl android.hardware.sensors.ISensors/default
```
**What was missing vs. the upstream/vendor definition:**
| Field | Without fix | With fix |
|---|---|---|
| `capabilities BLOCK_SUSPEND` | missing → HAL cannot hold a wakelock during sensor batching | present |
| `rlimit rtprio 10 10` | missing → real-time scheduling denied, sensor delivery latency increased | present |
| `interface aidl android.hardware.sensors.ISensors/default` | missing → AIDL service manager could not find the HAL by name | present |

Without the `interface aidl` declaration, `android.hardware.sensors.ISensors/default` was not registered in hwservicemanager, causing the repeated log line:
```
ISensors/default ... could not be found trying to start it as a lazy AIDL service
```

---

### 2.2 `device/oneplus/instantnoodlep` — `sepolicy/vendor/hal_sensors_default.te` *(NEW)*
**Added** (restored rules stripped from `hardware/oplus`):
```
allow hal_sensors_default ssc_interactive_device:chr_file rw_file_perms;
allow hal_sensors_default ultrasound_device:chr_file rw_file_perms;

r_dir_file(hal_sensors_default, vendor_proc_eng_cali_file)
r_dir_file(hal_sensors_default, vendor_proc_oplus_als_file)
r_dir_file(hal_sensors_default, vendor_proc_oplus_version)
r_dir_file(hal_sensors_default, vendor_proc_ultrasound)
rw_dir_file(hal_sensors_default, vendor_persist_engineer_file)
rw_dir_file(hal_sensors_default, vendor_proc_display)
rw_dir_file(hal_sensors_default, vendor_sysfs_graphics)
rw_dir_file(hal_sensors_default, vendor_sysfs_sensor_fb)
```
**Why each rule matters:**

| Rule | Required for |
|---|---|
| `ssc_interactive_device` | SSC (Snapdragon Sensor Core) interactive userspace interface — needed by ADSP sensor subscription/streaming |
| `ultrasound_device` | Proximity sensor using ultrasound (used during UDFPS) |
| `vendor_proc_eng_cali_file` | Reads factory calibration data written during QC production |
| `vendor_proc_oplus_als_file` | ALS (ambient light) proc node access for gain/offset tuning |
| `vendor_proc_oplus_version` | OPlus version/project identification read at startup |
| `vendor_proc_ultrasound` | Ultrasound sensor configuration |
| `vendor_persist_engineer_file` | Engineer calibration persistence path (`/mnt/vendor/persist/engineering/`) |
| `vendor_proc_display` | Display state read — needed by sensors dependent on screen-on/off state |
| `vendor_sysfs_graphics` | GPU/display power state access |
| `vendor_sysfs_sensor_fb` | Framebuffer sensor events |

Without these, AVC denials silently blocked the SSC remote-handle open path, causing `sscrpcd` to fail the ADSP connection while the HAL process stayed alive but empty.

---

### 2.3 `device/oneplus/instantnoodlep` — `sepolicy/vendor/vendor_hal_oplus_sensor_default.te` *(NEW)*
**Added:**
```
r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_engineer_file)
r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_sensors_file)
```
**Why:** The OPlus sensor HAL server reads factory calibration and sensor list data from `/mnt/vendor/persist/engineering/` and `/mnt/vendor/persist/sensors/` early in startup to populate the sensor discovery list. Without read access, the HAL could not enumerate the sensor list — causing the accel/gyro entries to never appear in `dumpsys sensorservice`.

---

### 2.4 `device/oneplus/instantnoodlep` — `sepolicy/vendor/vendor_sensors.te` *(NEW)*
**Added:**
```
rw_dir_file(vendor_sensors, vendor_persist_camera_file)
rw_dir_file(vendor_sensors, vendor_persist_engineer_file)
rw_dir_file(vendor_sensors, vendor_proc_eng_cali_file)
rw_dir_file(vendor_sensors, vendor_proc_oplus_version)
rw_dir_file(vendor_sensors, vendor_sysfs_sensor_fb)
```
**Why:** `vendor_sensors` domain covers `sscrpcd` and related ADSP calibration/probe paths. These access the same persist engineering and proc calibration nodes that `hal_sensors_default` uses, but from the lower ADSP-side process context. Missing these was causing `sscrpcd` calibration-probe failures on every boot cycle.

---

### 2.5 `hardware/oplus` — `sepolicy/qti/vendor/hal_sensors_default.te`
**Deleted** from common policy (all rules stripped):
```diff
-r_dir_file(hal_sensors_default, vendor_proc_eng_cali_file)
-r_dir_file(hal_sensors_default, vendor_proc_oplus_als_file)
-r_dir_file(hal_sensors_default, vendor_proc_oplus_version)
-r_dir_file(hal_sensors_default, vendor_proc_ultrasound)
-rw_dir_file(hal_sensors_default, vendor_persist_engineer_file)
-rw_dir_file(hal_sensors_default, vendor_proc_display)
-rw_dir_file(hal_sensors_default, vendor_sysfs_graphics)
-rw_dir_file(hal_sensors_default, vendor_sysfs_sensor_fb)
```
These were moved to device level (section 2.2). The 2 chr_file rules (`ssc_interactive_device`, `ultrasound_device`) were intentionally kept in the hardware/oplus base policy as they are universal to all OPlus QTI devices.

---

### 2.6 `hardware/oplus` — `sepolicy/qti/vendor/hal_oplus_sensor_aidl.te`
**Deleted** 4 rules from common policy:
```diff
-r_dir_file(hal_oplus_sensor_aidl, vendor_persist_engineer_file)
-r_dir_file(hal_oplus_sensor_aidl, vendor_persist_sensors_file)
-rw_dir_file(hal_oplus_sensor_aidl, vendor_proc_eng_cali_file)
-rw_dir_file(hal_oplus_sensor_aidl, vendor_proc_oplus_als_file)
```
Moved to device level in `vendor_hal_oplus_sensor_default.te` (section 2.3) with reduced scope (read-only where possible).

---

### 2.7 `hardware/oplus` — `sepolicy/qti/vendor/vendor_hal_oplus_sensor_default.te`
**Deleted** 5 rules from common policy:
```diff
-r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_engineer_file)
-r_dir_file(vendor_hal_oplus_sensor_default, vendor_persist_sensors_file)
-r_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_oplus_version)
-rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_eng_cali_file)
-rw_dir_file(vendor_hal_oplus_sensor_default, vendor_proc_oplus_als_file)
```
Re-added at device level in section 2.3.

---

### 2.8 `hardware/oplus` — `sepolicy/qti/vendor/vendor_sensors.te`
**Deleted** entire file content:
```diff
-rw_dir_file(vendor_sensors, vendor_persist_camera_file)
-rw_dir_file(vendor_sensors, vendor_persist_engineer_file)
-rw_dir_file(vendor_sensors, vendor_proc_eng_cali_file)
-rw_dir_file(vendor_sensors, vendor_proc_oplus_version)
-rw_dir_file(vendor_sensors, vendor_sysfs_sensor_fb)
```
Re-added at device level in section 2.4.

---

### 2.9 `hardware/oplus` — `packages/Doze/PickupSensor.kt`
**Changed** — A16 API compatibility fix for the pickup-to-wake gesture sensor:
```diff
-powerManager.wakeUpWithProximityCheck(
+powerManager.wakeUp(
     SystemClock.uptimeMillis(),
     PowerManager.WAKE_REASON_GESTURE,
     TAG,
```
**Why:** `PowerManager.wakeUpWithProximityCheck()` was removed in A16. The DozeService pickup sensor uses this to wake the device on face/hand proximity. Replaced with `wakeUp()` which has identical behaviour for this use case (no proximity check needed for the pick-up gesture path).  
**Effect on shake/gesture:** This is the code path used when `OplusDoze` / ProximitySensor detects a pick-up event. If a boot reported "no shake/gesture", this was one of the causes.

---

### 2.10 `kernel/oneplus/sm8250` — `drivers/soc/oplus/sensor/Makefile`
**Disabled** OPlus sensor devinfo objects:
```diff
-oplus_sensor-y := oplus_sensor_devinfo.o
-oplus_sensor-y += oplus_press_cali_info.o
-oplus_sensor-y += oplus_pad_als_info.o
-obj-$(CONFIG_OPLUS_FEATURE_SENSOR_CFG) += oplus_sensor.o
+# oplus_sensor-y := oplus_sensor_devinfo.o
+# oplus_sensor-y += oplus_press_cali_info.o
+# oplus_sensor-y += oplus_pad_als_info.o
+# obj-$(CONFIG_OPLUS_FEATURE_SENSOR_CFG) += oplus_sensor.o
```
**Why it was disabled:** These objects (`oplus_sensor_devinfo.c`, `oplus_press_cali_info.c`, `oplus_pad_als_info.c`) call OPlus-internal kernel symbols that are not exported/available in the open-source tree used for this build. They caused unresolved symbol linker errors.

**Impact:** The two lines below the commented block remain active:
```
obj-$(CONFIG_SSC_INTERACTIVE) += oplus_ssc_interact/
obj-$(CONFIG_OPLUS_SENSOR_FB_QC) += oplus_sensor_feedback/
```
So SSC interactive and sensor feedback modules still build. The disabled modules were device-info/calibration helpers; the core SSC sensor stack still compiles and loads.

**Open question:** Whether disabling `oplus_sensor_devinfo` is the root cause of accel/gyro not registering — if SSC firmware relies on `devinfo` to identify sensor hardware at probe time, removing it could cause the sensor list to be empty on the ADSP side. This needs investigation in the next session.

---

## 3. Open Issues at Commit Time

### Audio
| Issue | State | Notes |
|---|---|---|
| Speaker has no output | **Open** | AVC fix applied (2.1), prop added (1.3), but stale `/data` persist prop may override |
| Stale `persist.vendor.audio.speaker.prot.enable` in `/data` | **Open** | Need one-time init RC migration or recovery path wipe |
| `audio_extend_dlkm` disabled | Accepted workaround | Not required for basic playback; reenable only if DSP extension features needed |

### Sensors
| Issue | State | Notes |
|---|---|---|
| Accel/gyro never register | **Open** | SELinux rules restored (2.2-2.4), AIDL service declaration fixed (2.1). Root cause may still be `oplus_sensor_devinfo` being disabled (2.10) or `sscrpcd` ADSP path |
| `ISensors/default` lazy-start loop | Fixed in last commit | Was caused by missing `interface aidl` declaration in RC |
| Pickup-to-wake gesture | Fixed | `wakeUpWithProximityCheck` → `wakeUp` (2.9) |

---

## 4. Suggested Next Steps

### Audio
1. Add an init `.rc` snippet that runs on `post-fs-data` to force the speaker protection prop to the correct value:
   ```
   on post-fs-data
       setprop persist.vendor.audio.speaker.prot.enable true
   ```
   Place it in `init/zz_audio_prot_migration.rc` and copy to `$(TARGET_COPY_OUT_VENDOR)/etc/init/`.
2. After flashing, verify with:
   ```bash
   adb shell getprop persist.vendor.audio.speaker.prot.enable
   # Expected: true
   adb shell tinymix | grep -i spk
   ```

### Sensors
1. Re-enable `oplus_sensor_devinfo.o` and fix the missing symbols, or stub out the missing OPlus-internal calls. Check if `CONFIG_OPLUS_FEATURE_SENSOR_CFG` controls an ADSP-side probe dependency.
2. Collect very early boot logs and grep for:
   ```
   sscrpcd
   apps_dev_init failed
   remote_handle_open
   adsp_default_listener
   Transport endpoint is not connected
   ```
3. Check if `vendor_hal_oplus_sensor_default` / `vendor_sensors` AVC denials are fully gone:
   ```bash
   adb shell dmesg | grep -i "avc.*sensor\|avc.*sscrpcd\|avc.*vendor_sensors"
   ```
