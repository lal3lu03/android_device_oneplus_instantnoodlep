# Android 16 Bringup Code Changes
**Branch:** `a16-bringup-fixes`  
**Base:** `fork/lineage-23.2` (upstream LineageOS 23.2)  
**Target:** PixelOS sixteen-qpr1 (`aosp_instantnoodlep-bp3a-userdebug`)  
**Date:** 2026-03-07

All 8 repos that carry local commits ahead of `m/sixteen-qpr1`:

| Repo | Commits |
|---|---|
| `device/oneplus/instantnoodlep` | 3 |
| `device/oneplus/sm8250-common` | 1 |
| `device/lineage/sepolicy` | 1 |
| `device/qcom/sepolicy` | 1 |
| `device/qcom/sepolicy_vndr/legacy-um` | 1 |
| `hardware/oplus` | 1 |
| `kernel/oneplus/sm8250` | 1 |
| `vendor/lineage` | 1 |

---

## device/oneplus/instantnoodlep

### Android.bp
**Added** — soong namespace import for WLAN CAF hardware:
```
imports: [
    "hardware/qcom-caf/wlan",
]
```

---

### AndroidProducts.mk
**Changed** — product makefile pointer:
```diff
-    $(LOCAL_DIR)/lineage_instantnoodlep.mk
+    $(LOCAL_DIR)/aosp_instantnoodlep.mk
```
`lineage_instantnoodlep.mk` is now unused (replaced by `aosp_instantnoodlep.mk`).

---

### BoardConfig.mk
**Added:**
- `CUSTOM_BUILD := instantnoodlep` fallback — needed because PixelOS's `vendor/custom/envsetup` exports `CUSTOM_BUILD` as empty for non-`custom_*` products, but aosp_* lunch combos need it set.
- `BOARD_PREBUILT_DTBOIMAGE` — exports the built dtbo.img into `target-files` / releasetools metadata.
- `AB_OTA_PARTITIONS := $(filter-out recovery,$(AB_OTA_PARTITIONS))` — removes `recovery` from the A/B OTA partition list (device has no recovery partition slot).
- `TARGET_NO_RECOVERY := true` — explicitly disables recovery image generation.

---

### aosp_instantnoodlep.mk *(NEW FILE — replaces lineage_instantnoodlep.mk)*
Full replacement product config for PixelOS / AOSP builds. Key differences vs the old lineage file:

| Item | Value / Note |
|---|---|
| OMX service | `TARGET_SUPPORTS_OMX_SERVICE := false` — disabled, not available in A16 vendor |
| SetupWizard | `ro.setupwizard.mode=DISABLED` — skips SUW; workaround for A16 window/touch-dispatch race |
| NFC packages removed | `NfcNci`, `framework-nfc`, `framework-nfc.impl` filtered out — APEX-only in A16, replaced by `com.android.nfcservices` |
| Build fingerprint | OOS13 fingerprint (`OnePlus8Pro:13/RKQ1.211119.001/…`) set via `PRODUCT_BUILD_PROP_OVERRIDES` |
| Debug mode | Optional `INSECURE_ADB_DEBUG=true` build-time flag — sets `ro.adb.secure=0`, `ro.debuggable=1`, `persist.sys.usb.config=adb` for bootloop diagnosis |

---

### device.mk
**Added** — `PRODUCT_COPY_FILES` entries for new init RC overrides:
```
init/zz_fps_hal_override.rc          → $(TARGET_COPY_OUT_ODM)/etc/init/
init/zz_vl53l1_daemon_override.rc    → $(TARGET_COPY_OUT_ODM)/etc/init/
init/zz_vendor.aidl_hal_overrides.rc → $(TARGET_COPY_OUT_VENDOR)/etc/init/
input/touchpanel.idc                 → $(TARGET_COPY_OUT_VENDOR)/usr/idc/
```

**Added:**
- `PRODUCT_PRECOMPILED_SEPOLICY := false` — disables precompiled sepolicy; required to load the new per-device `.te` additions at boot without a full framework OTA.
- LiveDisplay soong config:
  ```
  soong_config_set_bool OPLUS_LINEAGE_LIVEDISPLAY_HAL ENABLE_SE true
  soong_config_set_bool OPLUS_LINEAGE_LIVEDISPLAY_HAL ENABLE_PA true
  ```
  Enables SunlightEnhancement and PictureAdjustment AIDL implementations.

---

### vendor.prop
**Added:**
```
persist.vendor.audio.speaker.prot.enable=true
```
Keeps speaker protection enabled for normal amplifier bring-up. (Runtime debugging may toggle this.)

---

### init/ — New files

#### `init/hidl_rpcpool_compat.cpp` *(NEW)*
HIDL RPC threadpool compatibility shim. Constructor-attributed function that calls `configureRpcThreadpool(1, true)` to satisfy legacy HIDL HALs that expect a threadpool to be configured before they initialize.

#### `init/init.instantnoodlep-bringup.rc` *(NEW)*
RC snippet that explicitly starts HAL services on `post-fs-data` to work around AIDL service manager timing:
```
start vendor.touch-hal
start fps_hal
start vendor.fps_hal_oplus
```

#### `init/zz_fps_hal_override.rc` *(NEW)*
Overrides the `fps_hal` service definition to use the ODM binary path and explicitly declares all fingerprint HIDL interface versions (2.1 through 2.3 + OPlus custom):
```
service fps_hal /odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service
    override
    class late_start
    user system
    group system input uhid
    interface vendor.oplus.hardware.biometrics.fingerprint@2.1::IBiometricsFingerprint default
    interface android.hardware.biometrics.fingerprint@2.1::IBiometricsFingerprint default
    interface android.hardware.biometrics.fingerprint@2.2::IBiometricsFingerprint default
    interface android.hardware.biometrics.fingerprint@2.3::IBiometricsFingerprint default
```

#### `init/zz_vendor.aidl_hal_overrides.rc` *(NEW)*
Overrides two vendor HAL services to use AIDL interfaces instead of older HIDL registrations:

- **`vendor.sensors-hal-multihal`** — adds AIDL interface declaration `android.hardware.sensors.ISensors/default` and correct capabilities (`BLOCK_SUSPEND`, `rtprio 10`)
- **`vendor.livedisplay-hal`** — registers AIDL interfaces `vendor.lineage.livedisplay.IPictureAdjustment/default` and `vendor.lineage.livedisplay.ISunlightEnhancement/default`

#### `init/zz_vendor.touch-hal.override.rc` *(NEW)*
Overrides `vendor.touch-hal` with AIDL interfaces:
```
interface aidl vendor.lineage.touch.IGloveMode/default
interface aidl vendor.lineage.touch.IHighTouchPollingRate/default
interface aidl vendor.lineage.touch.ITouchscreenGesture/default
```

#### `init/zz_vl53l1_daemon_override.rc` *(NEW)*
Overrides the ToF (Time-of-Flight, vl53l1) proximity daemon with a safer runtime profile:
- Removed automatic restart (`oneshot` instead of persistent)
- Drops from `root` to `cameraserver` user to avoid DAC bypass
- Keeps the `vl53l1_daemon` socket with `660 cameraserver system` permissions

---

### input/touchpanel.idc *(NEW FILE)*
Input device configuration for the touchscreen:
```
device.internal = 1
touch.deviceType = touchScreen
touch.orientationAware = 1
```

---

### overlay/OPlusFrameworksResTarget/res/values/config.xml
**Added** to existing overlay:
```xml
<bool name="config_hasAlertSlider">true</bool>

<string-array name="config_deviceKeyHandlerLibs" translatable="false">
    <item>/system_ext/app/KeyHandler/KeyHandler.apk</item>
</string-array>

<string-array name="config_deviceKeyHandlerClasses" translatable="false">
    <item>org.lineageos.settings.device.KeyHandler</item>
</string-array>
```
Declares the hardware alert slider and wires up the KeyHandler APK (standalone RRO).

---

### overlay/OPlusSystemUIResTarget/res/values/custom_config.xml *(NEW FILE)*
```xml
<bool name="config_audioPanelOnLeftSide">true</bool>
```
Places the volume panel on the left side to match the physical volume keys on OnePlus 8 Pro.

---

### sepolicy/vendor/ — All new files

| File | What it allows |
|---|---|
| `genfs_contexts` | Labels `proc/tee_bind_core` as `vendor_proc_tee_bind_core` |
| `hal_audio_default.te` | `rw` access to `vendor_sysfs_usb_supply` |
| `hal_camera_default.te` | `rw` to `vendor_proc_camera`, `vendor_sysfs_tof` |
| `hal_fingerprint_default.te` | read `vendor_proc_fingerprint`; `rw` to `vendor_proc_display`, read `vendor_sysfs_battery_supply`, `rw` to `vendor_proc_tee_bind_core`; defines `vendor_proc_tee_bind_core` type |
| `hal_lineage_livedisplay_qti.te` | `find` on `vendor_qdisplay_service`; binder `call` on `hal_graphics_composer_default` |
| `hal_power_default.te` | `rw` to `vendor_proc_display`, `vendor_sysfs_sde_crtc` |
| `hal_sensors_default.te` | `rw` to `ssc_interactive_device`, `ultrasound_device`; read various oplus proc/sysfs nodes; `rw` to `vendor_persist_engineer_file`, `vendor_proc_display`, `vendor_sysfs_graphics`, `vendor_sysfs_sensor_fb` |
| `horae.te` | read `vendor_proc_oplus_version`; `rw` to `proc_horae` |
| `oplus_touchdaemon.te` | `rw` to `proc_bus_input`, `proc_horae`, `vendor_data_file`, `vendor_proc_display` |
| `system_server.te` | read `vendor_proc_tri_state_key` (alert slider); `rw` to `vendor_proc_oplus_scheduler` |
| `vendor_hal_oplus_sensor_default.te` | read `vendor_persist_engineer_file`, `vendor_persist_sensors_file` |
| `vendor_hal_perf_default.te` | `rw` to `proc_sched` |
| `vendor_sensors.te` | `rw` to `vendor_persist_camera_file`, `vendor_persist_engineer_file`, `vendor_proc_eng_cali_file`, `vendor_proc_oplus_version`, `vendor_sysfs_sensor_fb` |
| `vl53l1_daemon_main.te` | read `vendor_persist_camera_file`, `vendor_sysfs_tof`; `rw` to `mnt_vendor_file` |

---

## device/oneplus/sm8250-common

### Android.bp
**Added** — same WLAN CAF namespace import as instantnoodlep:
```
imports: [
    "hardware/qcom-caf/wlan",
]
```

---

### BoardConfigCommon.mk
**Added:**
- `BOARD_SHIPPING_API_LEVEL := 34` — moved here from `common.mk` (was `30` there, now correctly reflects A16 target API)
- `BUILD_BROKEN_MISSING_REQUIRED_MODULES := true` — suppresses build errors for missing required modules during bring-up
- `KERNEL_ARCH := arm64` and `TARGET_KERNEL_ARCH := arm64` — explicit arch flags
- `TARGET_KERNEL_MAKE_CMD := make` — explicit make command for kernel build
- `TARGET_KERNEL_VERSION := 4.19` — marks kernel version for build system

**Changed:**
```diff
-VENDOR_SECURITY_PATCH := 2024-10-05
+VENDOR_SECURITY_PATCH := 2026-02-05
```

---

### build_dtbo.mk *(NEW FILE)*
Custom make rule to create `dtbo.img` from compiled `.dtbo` files. Needed because the automatic DTBO build is not triggered for `ap2a` / PixelOS variants.

```makefile
DTBO_SOURCE_DIR := $(PRODUCT_OUT)/obj/DTB_OBJ/arch/arm64/boot/dts/vendor/oplus
MKDTBOIMG := $(HOST_OUT_EXECUTABLES)/mkdtboimg

.PHONY: dtbo_custom
dtbo_custom: $(MKDTBOIMG)
    # scans DTBO_SOURCE_DIR for *.dtbo, packs into dtbo.img with page_size=4096
```

---

### common.mk
**Removed:**
```diff
-# Board API level
-BOARD_SHIPPING_API_LEVEL := 30
```
(Value moved to `BoardConfigCommon.mk` and bumped to 34.)

**Added** to `PRODUCT_SOONG_NAMESPACES`:
```diff
-    hardware/oplus
+    hardware/oplus \
+    hardware/qcom-caf/wlan \
+    hardware/qcom-caf/wlan/qcwcn
```

**Added** at end of file:
```makefile
# Custom dtbo.img build task
-include device/oneplus/sm8250-common/build_dtbo.mk
```

---

---

## device/lineage/sepolicy

### common/public/property.te
**Changed** — removed duplicate property declarations that now live in `device/qcom/sepolicy`:
```diff
-system_vendor_config_prop(vendor_persist_camera_prop)
+# Defined in device/qcom/sepolicy/generic/public/property.te
+# system_vendor_config_prop(vendor_persist_camera_prop)

-system_vendor_config_prop(vendor_persist_nfc_prop)
+# Defined in device/qcom/sepolicy/generic/public/property.te
+# system_vendor_config_prop(vendor_persist_nfc_prop)
```

### common/vendor/file_contexts
**Deleted** line — PowerShare HAL exec label removed (service no longer shipped):
```diff
-/(vendor|system/vendor)/bin/hw/vendor\.lineage\.powershare-service\.default u:object_r:hal_lineage_powershare_default_exec:s0
```

### common/vendor/hal_lineage_powershare_default.te *(DELETED)*
Entire file removed. The PowerShare HIDL HAL domain definition is gone because this device uses the OPlus charger AIDL HAL instead.

### common/vendor/hal_lineage_touch_default.te *(DELETED)*
Entire file removed. Touch HAL domain definition removed — replaced by the AIDL touch HAL declared in `device/oneplus/instantnoodlep/sepolicy/vendor/`.

### common/vendor/vendor_init.te
**Changed** — NFC property `set_prop` removed; `vendor_persist_nfc_prop` is now `system_restricted` in QCOM sepolicy and cannot be set from `vendor_init`.

### qcom/dynamic/genfs_contexts *(DELETED)*
Removed 4 livdisplay sysfs `genfscon` labels for DSI display primary (acl, cabc, dc, hbm). These are now handled at device level.

### qcom/dynamic/hal_lineage_livedisplay_qti.te *(DELETED)*
Removed QTI LiveDisplay HAL domain. LiveDisplay is now AIDL; policy moved to `device/oneplus/instantnoodlep/sepolicy/vendor/hal_lineage_livedisplay_qti.te`.

### qcom/dynamic/hal_lineage_livedisplay_sysfs.te *(DELETED)*
Removed sysfs LiveDisplay policy file.

### qcom/vendor/file_contexts
**Deleted** line — LiveDisplay HIDL service exec label removed:
```diff
-/(vendor|system/vendor)/bin/hw/vendor\.lineage\.livedisplay-service\.sdm u:object_r:hal_lineage_livedisplay_qti_exec:s0
```

### qcom/vendor/fm_app.te
**Deleted** line — `get_prop` for FM radio app property removed.

### qcom/vendor/hal_gnss_qti.te
**Deleted** line — `dontaudit` for xtra control property removed.

### qcom/vendor/hal_lineage_health_default.te *(DELETED)*
Entire file removed — Lineage Health HAL sysfs battery/USB supply rules deleted.

### qcom/vendor/hal_lineage_livedisplay_qti.te *(DELETED)*
Entire file removed — full HIDL LiveDisplay QTI domain (type declarations, `init_daemon_domain`, binder, vndbinder, data file rules) all gone.

### qcom/vendor/hal_power_default.te *(DELETED)*
Entire file removed — power HAL sysfs rules (`proc_sched`, `sysfs_devfreq`, `sysfs_graphics`, `sysfs_kgsl`, `sysfs_scsi_host`) deleted from common policy. Per-device overrides live in `device/oneplus/instantnoodlep/sepolicy/vendor/hal_power_default.te`.

### qcom/vendor/location.te
**Deleted** line — `get_prop` for `xtra_control_prop` in location domain removed.

---

## device/qcom/sepolicy

### generic/private/property.te
**Added** (as comments) — two duplicate declarations that were conflicting are commented out:
```
#system_internal_prop(vendor_persist_camera_prop)  # duplicate declaration
#system_internal_prop(vendor_persist_nfc_prop)      # duplicate declaration
```

### generic/public/property.te
**Added** — two property types re-declared here at the correct visibility level:
```
system_restricted_prop(vendor_persist_camera_prop)
system_restricted_prop(vendor_persist_nfc_prop)
```
Moved from `system_vendor_config_prop` in lineage sepolicy to `system_restricted_prop` here so QCOM framework code has the authoritative definition.

---

## device/qcom/sepolicy_vndr/legacy-um

### generic/vendor/common/qtelephony.te
**Deleted** line:
```diff
-get_prop(vendor_qtelephony, vendor_persist_camera_prop)
```
Property visibility changed to `system_restricted`; telephony vendor process no longer needs access.

### generic/vendor/test/snapcam.te
**Deleted** line:
```diff
-get_prop(vendor_snapcam_app, vendor_persist_camera_prop)
```

### qva/vendor/test/seccam2_app.te
**Deleted** line:
```diff
-get_prop(vendor_sys_seccam2_app, vendor_persist_camera_prop)
```

---

## hardware/oplus

### audio_amplifier/Android.bp
**Added** header lib dependency:
```diff
+    "generated_kernel_headers",
```
Needed so the audio amplifier HAL can pick up the `voice_params.h` UAPI header added to the kernel.

### packages/Doze/src/…/PickupSensor.kt
**Changed** — API call updated for A16 compatibility:
```diff
-powerManager.wakeUpWithProximityCheck(
+powerManager.wakeUp(
     SystemClock.uptimeMillis(),
     PowerManager.WAKE_REASON_GESTURE,
     TAG,
```
`wakeUpWithProximityCheck` was removed in A16; replaced with the standard `wakeUp` call.

### packages/KeyHandler/res/values/strings.xml *(NEW FILE)*
Added missing string resources for the alert slider KeyHandler UI:
- Alert slider mode strings (None, Normal, Vibration, Silent, DND variants)
- UI strings for category title, mute media option, position labels, notification dialog

### sepolicy/qti/vendor/file_contexts
**Deleted** two exec label entries:
```diff
-/vendor/bin/hw/vendor\.lineage\.powershare-service\.oplus   u:object_r:hal_lineage_powershare_default_exec:s0
-/vendor/bin/hw/vendor\.lineage\.livedisplay-service\.oplus  u:object_r:hal_lineage_livedisplay_qti_exec:s0
-/vendor/bin/hw/vendor\.lineage\.touch-service\.oplus        u:object_r:hal_lineage_touch_default_exec:s0
```
These services now use AIDL and have new exec labels / domain declarations at device level.

### sepolicy/qti/vendor/hal_audio_default.te
**Deleted:**
```diff
-rw_dir_file(hal_audio_default, vendor_sysfs_usb_supply)
```
Moved to `device/oneplus/instantnoodlep/sepolicy/vendor/hal_audio_default.te`.

### sepolicy/qti/vendor/hal_camera_default.te
**Deleted:**
```diff
-rw_dir_file(hal_camera_default, vendor_proc_camera)
-rw_dir_file(hal_camera_default, vendor_sysfs_tof)
```
Moved to device-level sepolicy.

### sepolicy/qti/vendor/hal_fingerprint_default.te
**Deleted:**
```diff
-rw_dir_file(hal_fingerprint_default, vendor_persist_fingerprint_file)
-rw_dir_file(hal_fingerprint_default, vendor_proc_display)
-rw_dir_file(hal_fingerprint_default, vendor_sysfs_graphics)
-r_dir_file(hal_fingerprint_default, vendor_proc_fingerprint)
```
Moved to device-level sepolicy with updated access pattern.

### sepolicy/qti/vendor/hal_lineage_livedisplay_qti.te *(DELETED)*
Removed `allow hal_lineage_livedisplay_qti graphics_device:chr_file rw_file_perms`. Domain moved to device-level AIDL policy.

### sepolicy/qti/vendor/hal_lineage_powershare_default.te *(DELETED)*
Entire file removed — PowerShare not present on this device.

### sepolicy/qti/vendor/hal_lineage_touch_default.te *(DELETED)*
Entire file removed — touch HAL now uses AIDL, old HIDL domain gone.

### sepolicy/qti/vendor/hal_oplus_charger_aidl.te
**Deleted** 6 `rw_dir_file` rules — charger sysfs/proc node access rules were removed from common hardware policy. These were causing policy conflicts since device-level rules already cover them.

### sepolicy/qti/vendor/hal_oplus_esim_aidl.te
**Deleted:**
```diff
-rw_dir_file(hal_oplus_esim_aidl, oplus_reserve_radio_file_type)
```

### sepolicy/qti/vendor/hal_oplus_performance_aidl.te
**Deleted:**
```diff
-rw_dir_file(hal_oplus_performance_aidl, vendor_proc_oplus_ctp)
-rw_dir_file(hal_oplus_performance_aidl, vendor_proc_oplus_scheduler)
```

### sepolicy/qti/vendor/hal_oplus_sensor_aidl.te
**Deleted** 4 lines — sensor AIDL HAL persist/proc node access removed from common level.

### sepolicy/qti/vendor/hal_oplus_touch_aidl.te
**Deleted:**
```diff
-rw_dir_file(hal_oplus_touch_aidl, oplus_touchdaemon_device)
-rw_dir_file(hal_oplus_touch_aidl, vendor_proc_display)
```

### sepolicy/qti/vendor/hal_power_default.te
**Deleted:**
```diff
-rw_dir_file(hal_power_default, vendor_proc_display)
-rw_dir_file(hal_power_default, vendor_sysfs_sde_crtc)
```
Moved to device-level sepolicy.

### sepolicy/qti/vendor/hal_sensors_default.te
**Deleted** 8 lines — all oplus-specific sensor proc/sysfs/persist access rules removed from common level; re-added at device level.

### sepolicy/qti/vendor/horae.te
**Deleted:**
```diff
-r_dir_file(horae, vendor_proc_oplus_version)
-rw_dir_file(horae, proc_horae)
```
Moved to device-level sepolicy.

### sepolicy/qti/vendor/legacy-um/vendor_qti_init_shell.te
**Deleted:**
```diff
-create_dir_file(vendor_qti_init_shell, vendor_persist_wcnss_service_file)
```

### sepolicy/qti/vendor/oplus_touchdaemon.te
**Deleted** 4 `rw_dir_file` rules for `proc_bus_input`, `proc_horae`, `vendor_data_file`, `vendor_proc_display` — moved to device-level sepolicy.

### sepolicy/qti/vendor/rild.te
**Deleted:**
```diff
-rw_dir_file(rild, oplus_reserve_radio_file_type)
-allow rild vendor_proc_display:file r_file_perms;
-r_dir_file(rild, vendor_proc_engineer)
```

### sepolicy/qti/vendor/subsystem_daemon.te
**Deleted:**
```diff
-r_dir_file(subsystem_daemon, vendor_proc_engineer)
-rw_dir_file(subsystem_daemon, vendor_olog_file)
```

### sepolicy/qti/vendor/system_server.te
**Deleted** entire content:
```diff
-rw_dir_file(system_server, vendor_proc_oplus_scheduler)
```
Moved to device-level sepolicy with additional alert slider rules.

### sepolicy/qti/vendor/tri-state-key-calibrate.te
**Deleted** 2 lines (content not shown in partial diff, but recorded in stat: 2 deletions).

### sepolicy/qti/vendor/ueventd.te
**Deleted** 1 line.

### sepolicy/qti/vendor/vendor_hal_oplus_sensor_default.te
**Deleted** 5 lines — persist engineer/sensor file access moved to device-level sepolicy.

### sepolicy/qti/vendor/vendor_qti_init_shell.te *(DELETED)*
Entire file removed.

### sepolicy/qti/vendor/vendor_rmt_storage.te
**Deleted** 2 lines.

### sepolicy/qti/vendor/vendor_sensors.te
**Deleted** 5 lines — sensor persist/proc/sysfs access moved to device-level sepolicy.

### sepolicy/qti/vendor/vendor_wcnss_service.te
**Deleted** 1 line.

### sepolicy/qti/vendor/vl53l1_daemon_main.te
**Deleted** 3 lines — ToF daemon path access moved to device-level sepolicy.

---

## kernel/oneplus/sm8250

### arch/arm64/configs/vendor/oplus.config
**Added** 9 config entries needed for A16 compatibility:
```
# CONFIG_AFS_FS is not set          # AFS filesystem disabled (not needed)
# CONFIG_VIRTIO_IOMMU is not set    # VirtIO IOMMU disabled
CONFIG_FS_DAX=y                     # Direct Access filesystem support
CONFIG_ANDROID_VENDOR_HOOKS=y       # Android vendor hook infrastructure
CONFIG_TRANSPARENT_HUGEPAGE=y       # THP support (required by A16 mm)
# CONFIG_CNIC is not set            # Broadcom CNIC disabled (fixes build conflict)
CONFIG_IP_ROUTE_MULTIPATH=y         # IP multipath routing
# CONFIG_NFT_FIB_IPV4 is not set    # NFTables FIB IPv4 disabled
# CONFIG_USB_GSPCA is not set       # USB webcam driver disabled
```

### arch/arm64/include/asm/proc-fns.h
**Changed** — commented out the `cpu_soft_restart` declaration that conflicts with the vendor implementation in `cpu-reset.h`:
```diff
+/* Commented out - conflicts with vendor implementation in cpu-reset.h
 void cpu_soft_restart(phys_addr_t cpu_reset,
                unsigned long addr) __attribute__((noreturn));
+*/
```

### arch/arm64/net/bpf_jit_comp.c
**Changed** — wrapped vendor hook trace calls in `CONFIG_ANDROID_VENDOR_HOOKS` guard:
```diff
+#ifdef CONFIG_ANDROID_VENDOR_HOOKS
 trace_android_vh_set_memory_ro(…);
 trace_android_vh_set_memory_x(…);
+#endif
```
Prevents compile error when `CONFIG_ANDROID_VENDOR_HOOKS` is not set.

### drivers/Makefile
**Changed** — INFINIBAND driver disabled (causes build conflict on this kernel):
```diff
-obj-$(CONFIG_INFINIBAND)       += infiniband/
+# obj-$(CONFIG_INFINIBAND)     += infiniband/
```

### drivers/gpio/gpiolib.c
**Changed** — removed OPlus VOOC adapter GPIO fast-charge path that calls unavailable functions (`oplus_vooc_adapter_update_is_rx_gpio`, `oplus_vooc_adapter_update_is_tx_gpio`). Replaced with standard kernel GPIO read/write path:
- `gpiod_get_raw_value_commit`: removed `get_oplus_vooc` callback branch
- `gpiod_set_raw_value_commit`: removed `set_oplus_vooc` callback branch

### drivers/usb/gadget/configfs.c
**Changed** — guarded `schedule_work(&gi->work)` with `CONFIG_USB_CONFIGFS_UEVENT`:
```diff
+#ifdef CONFIG_USB_CONFIGFS_UEVENT
 schedule_work(&gi->work);
+#endif
```
Prevents build error when the UEvent config option is absent.

### drivers/usb/gadget/function/f_uac2.c
**Deleted** — removed `module_init`/`module_exit` boilerplate from UAC2 function driver. The function driver is registered via `DECLARE_USB_FUNCTION_INIT` and must not also have standalone `module_init`/`module_exit` when built into a composite gadget.

### drivers/usb/gadget/function/f_uvc.c
**Deleted** — same fix as f_uac2.c: removed duplicate `module_init`/`module_exit` from UVC function driver.

### include/uapi/sound/voice_params.h *(NEW FILE)*
Added missing UAPI header required by vendor audio HAL:
```c
enum voice_lch_mode { VOICE_LCH_START = 1, VOICE_LCH_STOP };
#define SNDRV_VOICE_IOCTL_LCH _IOW('U', 0x00, enum voice_lch_mode)
```

### scripts/link-vmlinux.sh
**Changed** — disabled BTF ID resolution at link time; `resolve_btfids` tool is not available for this kernel version:
```diff
-if [ -n "${CONFIG_DEBUG_INFO_BTF}" ]; then
-info BTFIDS vmlinux
-${RESOLVE_BTFIDS} vmlinux
-fi
+# BTF ID resolution disabled - resolve_btfids tool not available
```

### security/lockdown/lockdown.c
**Changed** — removed `CONFIG_SECURITY_LOCKDOWN_LSM_EARLY` conditional; always use `DEFINE_LSM` instead of `DEFINE_EARLY_LSM`:
```diff
-#ifdef CONFIG_SECURITY_LOCKDOWN_LSM_EARLY
-DEFINE_EARLY_LSM(lockdown) = {
-#else
 DEFINE_LSM(lockdown) = {
-#endif
```

### Other files (Makefile/build compatibility fixes)
The following files received minor `#ifdef` guards, Makefile comment-outs, or stub changes to fix compilation against the A16 build system. No functional kernel behavior changes:

| File | Fix |
|---|---|
| `drivers/crypto/Makefile` | Build guard fix |
| `drivers/dax/device.c` | `CONFIG_FS_DAX` guard |
| `drivers/gpu/drm/Makefile` | Module list adjustment |
| `drivers/input/misc/Makefile` | Build guard fix |
| `drivers/iommu/Makefile` | Build guard fix |
| `drivers/media/usb/Makefile` | Disabled conflicting USB media drivers |
| `drivers/net/ethernet/broadcom/cnic.c` | `CONFIG_CNIC` guard (matches config disable) |
| `drivers/nvdimm/pmem.c` | DAX compat fix |
| `drivers/scsi/ufs/Makefile` | UFS build fix |
| `drivers/soc/oplus/sensor/Makefile` | Sensor module list fix |
| `drivers/staging/Makefile` | Build guard |
| `drivers/video/fbdev/Makefile` | fbdev build fix |
| `fs/Makefile` | AFS disabled (matches config) |
| `fs/afs/cmservice.c` | AFS compile guard |
| `fs/fuse/dax.c` | DAX compat |
| `fs/gfs2/aops.c` | GFS2 compat |
| `fs/nfs/client.c`, `fs/nfs/read.c` | NFS compat |
| `fs/open.c` | Open flags compat |
| `fs/proc/task_mmu.c` | THP compat (matches `CONFIG_TRANSPARENT_HUGEPAGE`) |
| `include/linux/ftrace.h` | ftrace hook guard |
| `include/linux/mmu_notifier.h` | MMU notifier A16 compat |
| `include/net/page_pool.h`, `net/core/page_pool.c` | Page pool hooks |
| `include/trace/hooks/memory.h`, `include/trace/hooks/syscall_check.h` | Vendor hook stubs |
| `kernel/bpf/bpf_struct_ops.c`, `kernel/bpf/core.c`, `kernel/bpf/syscall.c`, `kernel/bpf/trampoline.c` | BPF vendor hook guards |
| `kernel/rcu/tasks.h` | RCU tasks compat |
| `kernel/taskstats.c` | taskstats compat |
| `kernel/trace/trace_stack.c` | stacktrace compat |
| `mm/huge_memory.c`, `mm/khugepaged.c`, `mm/migrate.c`, `mm/util.c` | THP/migrate compat |
| `net/Makefile`, `net/ipv4/Makefile`, `net/ipv6/Makefile`, `net/xdp/Makefile` | Net build guards |
| `net/core/lwt_bpf.c`, `net/core/skmsg.c` | BPF socket compat |
| `net/ipv4/fib_frontend.c`, `net/ipv4/fib_semantics.c` | IP route multipath compat |
| `net/ipv4/netfilter/Makefile`, `net/ipv6/netfilter/Makefile` | NFT build guards |
| `net/ipv4/tcp_input.c`, `net/ipv4/tcp_minisocks.c`, `net/ipv4/tcp_output.c` | TCP vendor hook guards |
| `techpack/audio-extend/Kbuild` | Audio techpack build fix |

---

## vendor/lineage

### build/soong/Android.bp
**Removed** — both `lineage_generator` rules (`generated_kernel_includes` and `prebuilt_kernel_includes`) are commented out entirely. These drove LineageOS's own kernel header extraction pipeline, which conflicts with PixelOS's build system that handles kernel headers independently.

**Changed** — `generated_kernel_header_defaults` and `prebuilt_kernel_header_defaults` cc_defaults are now stub entries (no `generated_headers` / `export_generated_headers` properties). Modules that need kernel headers link against PixelOS's `generated_kernel_headers` instead.

### build/tasks/bacon.mk
**Rewrote** the `bacon` target for PixelOS/A16 compatibility:

- Old: direct hard-link from `INTERNAL_OTA_PACKAGE_TARGET` to the output zip
- New: builds `target-files-package` first, then calls `ota_from_target_files` explicitly to generate the OTA zip. Added error checking for both the target-files package and the final zip.

```makefile
# New bacon target flow:
bacon: target-files-package
    # 1. Verify target files exist
    # 2. Call OTA_FROM_TARGET_FILES to produce the zip
    # 3. Generate sha256sum
    # 4. Error out clearly if either step fails
```

### build/tasks/kernel.mk
**Changed:**
- `DTC` path: changed from `$(HOST_OUT_EXECUTABLES)/dtc` to `out/host/linux-x86/bin/dtc` (hardcoded path that matches the actual install location in PixelOS tree)
- `KERNEL_CC` extended with full LLVM toolchain variables:
  ```diff
  -KERNEL_CC := CC="$(CCACHE_BIN) clang" LD=ld.lld
  +KERNEL_CC := CC="$(CCACHE_BIN) clang" LD=ld.lld OBJCOPY=llvm-objcopy AR=llvm-ar NM=llvm-nm STRIP=llvm-strip OBJDUMP=llvm-objdump
  ```
- Added `KERNEL_MAKE_FLAGS += DEPMOD=true` — disables depmod during `modules_install` (Android manages modules separately)
- Added `KERNEL_MAKE_CMD` variable wiring so `TARGET_KERNEL_MAKE_CMD` set in device tree is forwarded to the actual kernel build invocation

### config/version.mk
**Added** — PixelOS version passthrough:
```makefile
ifneq ($(CUSTOM_VERSION),)
    LINEAGE_VERSION := $(CUSTOM_VERSION)
endif
```
PixelOS sets `CUSTOM_VERSION` in its own build system; this forwards it so the `bacon` artifact filename uses the PixelOS version string rather than the LineageOS one.

---

## Summary of deletions

| What | Repo | Reason |
|---|---|---|
| `lineage_instantnoodlep.mk` | `device/oneplus/instantnoodlep` | Replaced by `aosp_instantnoodlep.mk` for PixelOS |
| `BOARD_SHIPPING_API_LEVEL := 30` in `common.mk` | `device/oneplus/sm8250-common` | Moved to `BoardConfigCommon.mk` as `34` |
| `NfcNci`, `framework-nfc`, `framework-nfc.impl` packages | `device/oneplus/instantnoodlep` | APEX-only delivery in A16 |
| `hal_lineage_powershare_default.te` | `device/lineage/sepolicy` | PowerShare not present |
| `hal_lineage_touch_default.te` | `device/lineage/sepolicy` | Replaced by AIDL touch HAL policy |
| `qcom/dynamic/genfs_contexts` | `device/lineage/sepolicy` | LiveDisplay sysfs labels moved to device level |
| `qcom/dynamic/hal_lineage_livedisplay_qti.te` | `device/lineage/sepolicy` | LiveDisplay HIDL domain gone |
| `qcom/dynamic/hal_lineage_livedisplay_sysfs.te` | `device/lineage/sepolicy` | Same |
| `qcom/vendor/hal_lineage_health_default.te` | `device/lineage/sepolicy` | Lineage Health HAL removed from common |
| `qcom/vendor/hal_lineage_livedisplay_qti.te` | `device/lineage/sepolicy` | HIDL LiveDisplay domain gone |
| `qcom/vendor/hal_power_default.te` | `device/lineage/sepolicy` | Power HAL rules moved to device level |
| `hal_lineage_livedisplay_qti.te` | `hardware/oplus` | HIDL domain gone |
| `hal_lineage_powershare_default.te` | `hardware/oplus` | PowerShare not present |
| `hal_lineage_touch_default.te` | `hardware/oplus` | HIDL touch domain gone |
| `vendor_qti_init_shell.te` | `hardware/oplus` | File emptied and removed |
| `lineage_generator` rules | `vendor/lineage` | Replaced by PixelOS kernel header pipeline |
