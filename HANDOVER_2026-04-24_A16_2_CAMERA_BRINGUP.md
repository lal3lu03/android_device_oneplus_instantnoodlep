# HANDOVER — 2026-04-24 A16.2 Camera Bring-up

## 1) Scope

This handover captures the current state of the PixelOS Android 16.2 bring-up on OnePlus 8 Pro (`instantnoodlep`) after the large 16.1 stabilization cycle and the current OOS camera integration work.

Use this file to restart a new session without losing:
- current target device and slot
- what is already fixed
- what was staged in source but still needs runtime validation
- where the authoritative runbooks live

Tree root:
- `/home/lal3lu/android/pixelos`

Primary device tree:
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep`

Canonical OOS camera blob source:
- `/home/lal3lu/android/OOS_CAM_blobs`

Additional camera debug notes:
- `/home/lal3lu/android/OOS_CAM_DEBUG_WORKSPACE.md`

## 2) Source Of Truth Files

Current session should always read these first:
- TODO: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/TODO.md`
- Fix history: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/BUILD_FIXES_LOG.md`
- Repo policy: `/home/lal3lu/android/pixelos/AGENTS.md`
- This handover: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/HANDOVER_2026-04-24_A16_2_CAMERA_BRINGUP.md`

Older handovers still matter for historical context:
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/HANDOVER_2026-03-07_AUDIO_SHAKE.md`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/HANDOVER_2026-03-08_AUDIO_SENSORS_FIXED.md`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/HANDOVER_2026-03-15_RELEASE_CLOSEOUT.md`

## 3) Current Device / Slot Policy

Active debug phone for current cycle:
- Serial: `6c170bdd`
- Role: dev/debug phone
- Fixed slot for current bring-up cycle: `_a`

Do not switch slots during debugging unless explicitly requested.

AGENTS policy currently says:
- use `userdebug` consistently for bring-up/debug
- flash partial images on `_a` first

Lockscreen PIN for the dev phone:
- `123456`

## 4) What Is Already Done

### 4.1 16.1 baseline

The 16.1 cycle is functionally closed enough to use as the stable reference:
- call audio fixed
- earpiece routing fixed
- sensors fixed
- fingerprint restored
- deep sleep working
- major random black-screen drain regression fixed earlier by disabling PPR
- release flow, flashing routine, user/userdebug split, and packaging docs already exist

Those details are already captured in:
- the earlier handovers
- `BUILD_FIXES_LOG.md`

### 4.2 16.2 bring-up

The Android 16.2 tree was brought up and compiled successfully.

The main open functional work at this point is the OnePlus camera stack on 16.2 userdebug.

### 4.3 OOS camera integration progress

The OOS camera stack is not starting from zero. A large amount of work is already done and logged as issues `220` through `226` in `BUILD_FIXES_LOG.md`.

Completed/staged camera work:
- OOS OnePlus Camera app stack integrated without OnePlus Gallery
- Google Photos kept as gallery handoff target
- board/product packaging adjusted for Android 16 build rules
- OOS provider boot/runtime fixes applied
- missing vendor libs added
- `libc++_shared.so` added for ultrawide path
- pic-proc chain dependencies added
- provider executable SELinux transition fixed for the `.oplus` provider binary
- provider startup timing improved with `zz_oos_camera_provider_override.rc`
- calibration/config files included:
  - `fwk_config.json`
  - `calibrationOutput_uw.bin`
  - `calibrationOutput_wt.bin`
  - `calibrationOutput_IR.bin`
- `oplus.permission.OPLUS_COMPONENT_SAFE` path was added earlier in source

## 5) Current Camera State

Most recent camera work was focused on making the OOS stack complete and consistent.

Important current finding:
- the remaining meaningful runtime error was an SELinux denial where `platform_app` could not `find` `vendor.qti.hardware.camera.postproc::IPostProcService`

Observed symptom pair from runtime logs:
- AVC denial on `vendor_hal_camera_postproc_hwservice`
- OnePlus Camera spam:
  - `Failed to query component interface for required system resources: 6`

The direct `allow platform_app ... find` approach was rejected conceptually because Qualcomm vendor policy only allows `find` for domains tagged as `hal_camera_client`.

Current staged source fix:
- file: `device/oneplus/instantnoodlep/sepolicy/vendor/platform_app.te`
- content:
  - `typeattribute platform_app hal_camera_client;`

This is the key newest staged change.

## 6) Current Runtime Status

As of this handover:
- the image with the latest changes was generated and flashed by the user
- the device is booting / has booted after the latest flash
- a fresh runtime validation of camera after the latest flash is still required

What is still pending after the latest flash:
1. open OnePlus Camera
2. test all rear lenses:
   - main
   - `0.6x` ultrawide
   - tele
3. test mode switching:
   - photo
   - video
4. capture a fresh 30-40s log window during live use
5. confirm whether issue `226` is now resolved at runtime

## 7) Important Modified Files In Current Tree

Current dirty state in `device/oneplus/instantnoodlep` includes:
- `BUILD_FIXES_LOG.md`
- `BoardConfig.mk`
- `TODO.md`
- `aosp_instantnoodlep.mk`
- `device.mk`
- `sepolicy/vendor/file_contexts`
- `sepolicy/vendor/hal_camera_default.te`
- `sepolicy/vendor/property_contexts`
- `sepolicy/vendor/vendor_qti_init_shell.te`

Current untracked additions include:
- `configs/permissions/`
- `graphify-out/`
- `init/zz_oos_camera_provider_override.rc`
- `sepolicy/vendor/platform_app.te`

Do not discard any of these without reviewing them against the camera/session work.

## 8) Build / Flash Routine

Current default build target for bring-up:
```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-userdebug
m bacon -j12
```

Partial image rebuild when camera/vendor changes are touched:
```bash
m vendorimage odmimage -j12
```

Release routine remains the one documented in:
- `AGENTS.md`
- `TODO.md`

Current slot rule for debug testing:
- flash `_a`
- validate on `_a`

## 9) ADB / Session Caveat

There was an environment-specific issue during this session:
- direct ADB control from the Codex sandbox was unstable because the sandbox could not always start its own local `adb` server socket

Practical result:
- if ADB commands fail inside the session, start the host ADB server in the normal shell first:

```bash
adb start-server
adb devices -l
```

After that, retry capture from the assistant session.

This is a tooling/runtime constraint of the session environment, not a ROM bug.

## 10) Exact Next Steps

When resuming, do this in order:

1. Read:
   - `AGENTS.md`
   - `TODO.md`
   - `BUILD_FIXES_LOG.md` entries `220-226`
   - this handover

2. Confirm target:
```bash
adb devices -l
adb -s 6c170bdd shell getprop ro.boot.slot_suffix
```

3. Stay on slot `_a`

4. Run a fresh camera capture while the user performs:
   - app open
   - photo on all lenses
   - switch to video
   - short video start/stop

5. Parse for:
   - `vendor.qti.hardware.camera.postproc::IPostProcService`
   - `Failed to query component interface for required system resources: 6`
   - `avc: denied`
   - provider restart / `SIGABRT` / `SIGSEGV`
   - missing library errors

6. If the denial is gone and all lenses/modes work:
   - mark issue `226` as validated in `BUILD_FIXES_LOG.md`
   - update `TODO.md` camera state accordingly

7. If camera still fails:
   - continue from the OOS camera source at `/home/lal3lu/android/OOS_CAM_blobs`
   - treat the current tree state as canonical
   - do not roll back broad camera integration blindly

## 11) Summary

The project is not in general bring-up chaos anymore.

The current work is narrow:
- Android 16.2 is up
- OOS camera integration is largely in place
- the latest meaningful staged fix is the `platform_app -> hal_camera_client` policy tag
- the next session should focus on runtime validation of the flashed build on `6c170bdd`, slot `_a`

If that validation passes, the camera track can move from source bring-up into normal functional testing and closeout.
