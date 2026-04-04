# TODO — `instantnoodlep` A16 Bringup
**Device:** OnePlus 8 Pro (`instantnoodlep`, sm8250)
**Branch:** `a16-bringup-fixes`
**Last updated:** 2026-04-04

> Completed bringup items are in [DONE.md](DONE.md).

---

## NEXT MILESTONE

- [ ] Android 16.2 bring-up and validation on `instantnoodlep`

---

## OPEN TASKS — Play Integrity Integration (Session 24+)

All bringup blockers are cleared. Next work is Play Integrity.

### Phase 1 — Base Property Spoofing (NO ROOT EXPOSURE) — P0

| Task | File | Details | Status |
|------|------|---------|--------|
| A1 | Create system property overrides | `device/oneplus/instantnoodlep/system.prop` | NOT STARTED |
| A2 | Add properties to build | `device.mk` or `aosp_instantnoodlep.mk` | NOT STARTED |
| A3 | Verify properties on device | `adb shell getprop \| grep -E "fingerprint\|api_level\|gms"` | NOT STARTED |
| A4 | Boot clean flash, test Play Services | Test Play Integrity API response | NOT STARTED |

**Properties to set:**
```
ro.product.first_api_level=29
ro.product.model=IN2025
ro.build.version.release=10
ro.vendor.extension_library=/vendor/lib64/libqti-perfd-client.so
ro.com.google.clientidbase=android-google
ro.com.google.gmsversion=gms_20_202009
```

**Quick check after flashing Phase 1:**
```bash
# Verify current build fingerprint spoof is active
adb shell getprop ro.build.fingerprint
# Expected: OnePlus/OnePlus8Pro/OnePlus8Pro:13/RKQ1.211119.001/...release-keys
```

**Expected result:** `MEETS_DEVICE_INTEGRITY` minimum.

---

### Phase 2 — KernelSU Integration (OPTIONAL) — P1

| Task | File | Details | Status |
|------|------|---------|--------|
| B1 | Confirm KernelSU on device | `adb shell "[ -d /system/kernelsu ] && echo yes"` | NOT STARTED |
| B2 | Package PIF module | `device/oneplus/instantnoodlep/kernelsu/pif/module.prop` | NOT STARTED |
| B3 | Package TrickyStore module | `device/oneplus/instantnoodlep/kernelsu/trickystore/module.prop` | NOT STARTED |
| B4 | Create init trigger (optional auto-init) | `init/zz_integrity_modules.rc` | NOT STARTED |
| B5 | Test module install & execution | Flash ROM, verify module loads on reboot | NOT STARTED |

**Expected result (if KSU present):** `MEETS_STRONG_INTEGRITY` via PIF dynamic fingerprint injection + TrickyStore keybox attestation.

---

### Phase 3 — One-Tap Integrity Setup (USER CONVENIENCE) — P2

| Task | File | Details | Status |
|------|------|---------|--------|
| C1 | Create setup activity | `frameworks/.../IntegritySetupActivity.kt` | NOT STARTED |
| C2 | Add intent filter | Register in `AndroidManifest.xml` | NOT STARTED |
| C3 | First-boot notification trigger | Fires if Phase 1 props active + KSU available | NOT STARTED |
| C4 | One-tap KSU module init | User taps → runs `integrity_init.sh` | NOT STARTED |
| C5 | Test UX flow end-to-end | First boot → notification → tap → reboot → ✅ | NOT STARTED |

---

### Phase 4 — SELinux Hardening (CONCURRENT WITH PHASE 2/3) — P2

| Task | File | Status |
|------|------|--------|
| D1 | `integrity_module.te` — domain for KSU module init scripts | NOT STARTED |
| D2 | Grant module domain access to `ro.build.*` + `ro.product.*` | NOT STARTED |
| D3 | Audit AVC denials post-module-load | NOT STARTED |

---

### Phase 5 — Validation Gates

| Test | Command | Expected | Status |
|------|---------|----------|--------|
| Phase 1 property check | `adb shell getprop ro.build.fingerprint` | Spoofed string | NOT STARTED |
| Phase 1 Play API test | Play Services Settings → Integrity API | `MEETS_DEVICE_INTEGRITY` | NOT STARTED |
| Phase 2 KSU module test | Reboot post-KSU install | No AVC, `integrity_init.sh` completes | NOT STARTED |
| Phase 2 enhanced Play API | After modules loaded | `MEETS_STRONG_INTEGRITY` | NOT STARTED |
| Banking app smoke test | Open target app requiring strong integrity | App launches without denial | NOT STARTED |

---

## RELEASE GATE (before shipping user build)

1. Clean flash of signed `user` build
2. SetupWizard completes without error
3. Call audio: earpiece + speaker + mic both directions
4. Fingerprint: enroll + unlock passes
5. Camera: photo + video quick pass
6. WiFi + LTE + Bluetooth quick pass
7. Play Integrity + target banking app smoke test
8. Sign + package OTA + ship

---

---

# Build and Boot Reference: `instantnoodlep`

---

## Device Mapping (USB Serials)

Use this mapping before any flash or log capture to avoid targeting the wrong phone.

| Serial | Role | Current build type | Typical slot |
|---|---|---|---|
| `84064e34` | **USER phone** (daily / release validation + active crash debug) | `userdebug` on `_b`, `user` on `_a` | `_b` active |
| `6c170bdd` | **DEV phone** (debug / compare / fallback) | `user` (adb-root capable when enabled) | `_b` |

Quick verify:
```bash
adb devices -l
adb -s 84064e34 shell 'getprop ro.build.type; getprop ro.boot.slot_suffix'
adb -s 6c170bdd shell 'getprop ro.build.type; getprop ro.boot.slot_suffix'
```

## In-Call Proximity Parity Check

Before comparing call-screen/proximity behavior between the two phones, make sure both use the same Dialer generation.

Observed mismatch (2026-04-02):
- `84064e34` had Play-updated Dialer beta (`215.0.888983929-publicbeta-pixel`)
- `6c170bdd` had stock system Dialer (`174.0.764060808`)

Check and rollback:
```bash
adb -s <serial> shell dumpsys package com.google.android.dialer | rg -n 'codePath=|versionName=|versionCode='
# Rollback if needed:
adb -s <serial> shell pm uninstall com.google.android.dialer
```

---

## 1. Build and Flash Sequence (Slot `b`)

```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-userdebug  # use 'user' for release builds

m vendorimage odmimage -j$(nproc)  # adjust targets as needed

adb reboot bootloader
fastboot reboot fastboot
fastboot flash vendor_b out/target/product/instantnoodlep/vendor.img
fastboot flash odm_b out/target/product/instantnoodlep/odm.img
fastboot reboot
```

Or use the build scripts:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./build_userdebug.sh   # for debug
./build_user.sh        # for release
```

Unlock phone after flash (SIM-safe):
```bash
sim_state=$(adb shell getprop gsm.sim.state | tr -d '\r')
if echo "$sim_state" | grep -Eq "PIN_REQUIRED|PUK_REQUIRED"; then
  echo "SIM PIN/PUK required. Unlock SIM manually first."; exit 1
fi
adb shell input swipe 500 1500 500 300
sleep 1
adb shell input text "1234"
adb shell input keyevent 66
```

---

## 2. Boot Capture (Diagnostics)

```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/boot_capture_${ts}.log
adb shell logcat -b all -c
adb reboot
for i in $(seq 1 180); do adb get-state >/dev/null 2>&1 && break; sleep 1; done
adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
adb shell logcat -b all -d -v threadtime > "$out"

rg -n "ISensors/default|sscrpcd|apps_dev_init failed|remote_handle_open|adsp_default_listener|Transport endpoint|accelerometer|gyro|onbody|spkr_prot|speaker-protected" "$out"
```

---

## 3. Runtime Capture (Verification)

```bash
ts=$(date +%Y%m%d_%H%M%S)
out=/tmp/runtime_capture_${ts}.log
adb shell logcat -b all -c
timeout 40s adb shell logcat -b all -v threadtime > "$out"

rg -n "audio_hw|spkr|speaker|sensors-hal|accelerometer|gyro|shake|gesture|ISensors/default|avc: denied" "$out"
```

---

## 4. Backup Routine (run BEFORE any flash)

```bash
# 1. Note active slot
adb shell getprop ro.boot.slot_suffix    # e.g. "_a" → flash to _b

# 2. Pull WiFi config
adb pull /data/misc/wifi/WifiConfigStore.xml /tmp/wifi_backup_$(date +%Y%m%d).xml

# 3. Snapshot props
adb shell getprop > /tmp/preflash_props_$(date +%Y%m%d_%H%M%S).txt

# 4. Capture logcat baseline
adb logcat -b all -d -v threadtime > /tmp/preflash_logcat_$(date +%Y%m%d_%H%M%S).txt

# 5. Note build fingerprint
adb shell getprop ro.build.fingerprint
adb shell getprop ro.build.version.release
```

---

## 5. Recovery Shipping Routine

```bash
cd /home/lal3lu/android/pixelos
source build/envsetup.sh
lunch aosp_instantnoodlep-bp3a-user
m recoveryimage bootimage dtboimage vbmetaimage vbmetasystemimage -j$(nproc)

adb reboot bootloader
fastboot flash dtbo_b out/target/product/instantnoodlep/dtbo.img
fastboot flash vbmeta_b out/target/product/instantnoodlep/vbmeta.img
fastboot flash recovery_b out/target/product/instantnoodlep/recovery.img
fastboot reboot recovery
```

Reusable script:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./flash_recovery_fastboot.sh b
```

---

## 6. Power-Off Incident Quick Re-check

```bash
adb root
adb shell 'getprop ro.boot.bootreason; getprop sys.boot.reason; getprop persist.sys.boot.reason.history; cat /sys/power/pon_reason; cat /sys/power/poff_reason; cat /proc/sys/kernel/boot_reason'
```
