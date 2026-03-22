# HANDOVER — 2026-03-15 Session 24 Closeout (All P0/P1 Clear)

## 1) Scope of this handover

This handover captures the final state after:
- dual output split (`user` vs `userdebug`)
- variant-specific SetupWizard behavior
- release-key cleanup in product fingerprint overrides
- **P42 fix: black-screen + drain regression resolved (PPR disabled)**
- TODO/BUILD_FIXES_LOG synchronized (215 issues logged)
- Play Integrity 4-phase plan in TODO.md — Phase 1 is next action

**Session 24 outcome:**
- P42 (black-screen + severe idle drain) — **FIXED** (PPR property disabled, validated)
- All P0/P1 blockers confirmed clear — device stable for daily use
- `userdebug` build batch in progress (started for P42 debug; still useful for Phase 1 testing)
- Play Integrity Phase 1 is the **immediate next task** (property-only, no major code change)

Device target: **OnePlus 8 Pro** (`instantnoodlep`, sm8250)
Tree root: `/home/lal3lu/android/pixelos`

---

## 2) Where everything is

Device tree:
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep`

Common tree:
- `/home/lal3lu/android/pixelos/device/oneplus/sm8250-common`

Primary tracking docs:
- TODO: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/TODO.md`
- Fix history: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/BUILD_FIXES_LOG.md`
- This handover: `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/HANDOVER_2026-03-15_RELEASE_CLOSEOUT.md`

Tools:
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/build_variant.sh`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/build_user.sh`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/build_userdebug.sh`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/flash_recovery_fastboot.sh`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/blackscreen_diag_capture.sh`
- `/home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools/ondevice_crash_capture.sh`

---

## 3) Current policy (important)

File: `device/oneplus/instantnoodlep/aosp_instantnoodlep.mk`

- `userdebug` only:
  - `ro.setupwizard.mode=DISABLED`
- `user`:
  - SetupWizard enabled (release behavior)
- Build overrides use `release-keys` string in:
  - `BuildDesc`
  - `BuildFingerprint`

---

## 4) Build workflow (split outputs)

Default output paths:
- `user`: `/home/lal3lu/android/pixelos/out_user` (symlink -> `/mnt/androidbuild/out-user`)
- `userdebug`: `/home/lal3lu/android/pixelos/out_userdebug` (symlink -> `/home/lal3lu/android/pixelos_out_userdebug`)
- shared ccache: `/mnt/androidbuild/ccache`

Override paths when needed:
```bash
export PIXELOS_OUT_USER=/path/on/ssd1/out-user
export PIXELOS_OUT_USERDEBUG=/path/on/ssd2/out-userdebug
export CCACHE_DIR=/path/shared/ccache
```

Run `user` build:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./build_user.sh
```

Run `userdebug` build:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./build_userdebug.sh
```

Direct generic form:
```bash
./build_variant.sh user
./build_variant.sh userdebug
```

---

## 5) Flash routine (no `adb wait-for-device`)

Fastboot + recovery:
```bash
adb reboot bootloader
fastboot flash dtbo_b out/target/product/instantnoodlep/dtbo.img
fastboot flash vbmeta_b out/target/product/instantnoodlep/vbmeta.img
fastboot flash recovery_b out/target/product/instantnoodlep/recovery.img
fastboot reboot recovery
```

Recovery sideload:
```bash
adb sideload out/target/product/instantnoodlep/lineage-*.zip
```

Helper:
```bash
cd /home/lal3lu/android/pixelos/device/oneplus/instantnoodlep/tools
./flash_recovery_fastboot.sh b
```

---

## 6) Release signing routine (user shipping)

If output package still needs final signing normalization:
1. Build `user` target-files/OTA artifacts.
2. Sign target-files with release keyset.
3. Generate signed OTA from signed target-files.
4. Ship only signed artifact (`release-keys`).

Reference key location used previously:
- `/home/lal3lu/android/keys/instantnoodlep-release-20260313/`

---

## 7) Validation gate before shipping

Required:
1. Clean flash final signed `user` build.
2. SetupWizard path behaves as expected.
3. Calls: earpiece/speaker/mic pass.
4. Fingerprint: enroll + unlock pass.
5. Camera: photo/video quick pass.
6. WiFi + LTE data + Bluetooth quick pass.
7. Play Integrity + target banking app smoke test.

Notes:
- On unlocked-bootloader custom ROM distribution, universal `MEETS_STRONG_INTEGRITY` cannot be guaranteed for every app/user configuration.
- No root-based integrity bypass path is integrated.

---

## 8) Session closeout statement

All blocking functional defects are now fixed and validated. Device is stable for daily use.

Session 24 delivered:
- Split output build paths (`user` / `userdebug` isolated)
- Variant-specific SUW behavior (userdebug skips, user ships with it)
- Release-oriented user build workflow
- **P42 black-screen + drain fixed (PPR disabled)**
- Play Integrity 4-phase plan documented and ready to execute
- TODO + BUILD_FIXES_LOG + HANDOVER synchronized (215 issues total)
- Capture script `tools/blackscreen_diag_capture.sh` deployed for future regressions

---

## 9) P42 Fix — Black-Screen + Drain (CLOSED 2026-03-15)

**Root cause:** PPR (Panel Power Reset) property was enabled; triggered display power-down path that blocked deep sleep → severe drain.

**Fix:** PPR property disabled in device tree.

**Validation:** User confirmed no recurrence.

**Status:** ✅ FIXED — no further action needed.

---

## 10) Play Integrity Integration — NEXT ACTION

**Status:** Phase 1 ready to implement (P42 now clear)

**What's ready:**
- TODO.md has detailed 4-phase rollout plan (full detail in `PLAY INTEGRITY INTEGRATION PLAN` section)
- `aosp_instantnoodlep.mk` already spoof-builds `BuildFingerprint` to OxygenOS 13 (`release-keys`)
- Phase 1 is property-only — no structural code changes

**Immediate next steps:**

1. **Phase 1 (Do now):** Add base spoofing properties to `device/oneplus/instantnoodlep/system.prop`:
   ```
   ro.product.first_api_level=29
   ro.product.model=IN2025
   ro.build.version.release=10
   ro.com.google.clientidbase=android-google
   ro.com.google.gmsversion=gms_20_202009
   ```
   - Rebuild `userdebug` (batch already in progress), flash, test:
     ```bash
     adb shell getprop ro.build.fingerprint   # should show OxygenOS 13 spoof
     # Open Play Services Settings → Play Integrity API test
     ```
   - Expected: `MEETS_DEVICE_INTEGRITY` at minimum

2. **Phase 2 (Conditional — only if KernelSU on device):**
   ```bash
   adb shell "[ -d /system/kernelsu ] && echo YES || echo NO"
   ```
   - YES → package PIF + TrickyStore KSU modules → `MEETS_STRONG_INTEGRITY`
   - NO → Phase 1 alone is sufficient for standard custom ROM distribution

3. **Phase 3 (Optional):** One-tap first-boot setup notification (only if Phase 2 modules present)

4. **Phase 4 (Concurrent with Phase 2/3):** SELinux policy for integrity module domains

**Timeline:**
- Phase 1: 15–30 min
- Phase 2–4: 1–2 hrs (conditional on KernelSU)

---

## 11) Build Artifacts (as of session 24 close)

**Active build:**
- `userdebug` batch (`bacon`) in progress — check output:
  ```bash
  ls /home/lal3lu/android/pixelos/out_userdebug/target/product/instantnoodlep/
  ```

**Output paths:**
- `user`: `/home/lal3lu/android/pixelos/out_user/target/product/instantnoodlep/`
- `userdebug`: `/home/lal3lu/android/pixelos/out_userdebug/target/product/instantnoodlep/`

**Last known stable recovery artifact (session 22):**
```
Folder: releases/instantnoodlep-recovery-fastboot-20260313/
Zip:    releases/instantnoodlep-recovery-fastboot-20260313.zip
SHA256: c5c6b7b9b4e06b6123c0ba2f300a491f7b6d9763a5e2a7be2e6fd062da9aaec7
```

**Expected from current batch when done:**
- `aosp_instantnoodlep-userdebug.zip` (OTA for sideload)
- `boot.img`, `vendor.img`, `system.img`, `recovery.img` (fastboot images)
- Build fingerprint: OxygenOS 13 spoof (`OnePlus8Pro:13/RKQ1.211119.001/.../release-keys`)
