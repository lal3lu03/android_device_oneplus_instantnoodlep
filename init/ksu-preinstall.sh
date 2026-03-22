#!/system/bin/sh
# KernelSU module pre-installer
# Runs once on first boot after a fresh flash.
# Copies pre-bundled module ZIPs from vendor partition into /data/adb/modules/
# so KernelSU can load them on the NEXT reboot.
#
# Boot sequence:
#   Boot 1 (after flash): this script runs, extracts modules → /data/adb/modules/
#   Boot 2: KernelSU mounts modules, ZygiskNext+PIF+TrickyStore active
#            → MEETS_STRONG_INTEGRITY (if valid keybox present)

PREINSTALL_DIR="/vendor/etc/ksu-preinstall"
MODULES_DIR="/data/adb/modules"
TRICKY_CFG_DIR="/data/adb/tricky_store"
FLAG_FILE="/data/adb/.ksu-preinstalled"

# Guard: only run once
[ -f "$FLAG_FILE" ] && exit 0

# Guard: KernelSU must be active (/data/adb/ is a KSU-managed path)
[ ! -d "/data/adb" ] && exit 0

# Guard: must have something to install
[ ! -d "$PREINSTALL_DIR" ] && exit 0

mkdir -p "$MODULES_DIR"
mkdir -p "$TRICKY_CFG_DIR"

# Install each module ZIP
for mod in PIF ZygiskNext TrickyStore; do
    zip="$PREINSTALL_DIR/$mod/module.zip"
    dst="$MODULES_DIR/$mod"

    [ ! -f "$zip" ] && continue
    [ -d "$dst" ] && continue

    mkdir -p "$dst"
    # Extract module ZIP into the module directory
    unzip -q "$zip" -d "$dst" 2>/dev/null || {
        # unzip not available — copy ZIP as-is for KSU to handle
        cp "$zip" "$dst/update.zip"
    }
    # Ensure module is marked enabled (remove disable flag if present)
    rm -f "$dst/disable"
    # Mark for update pick-up by KernelSU
    touch "$dst/update"
done

# Deploy TrickyStore configuration
if [ -f "$PREINSTALL_DIR/tricky_store/keybox.xml" ]; then
    cp "$PREINSTALL_DIR/tricky_store/keybox.xml" "$TRICKY_CFG_DIR/keybox.xml"
fi
if [ -f "$PREINSTALL_DIR/tricky_store/target.txt" ]; then
    cp "$PREINSTALL_DIR/tricky_store/target.txt" "$TRICKY_CFG_DIR/target.txt"
fi

# Deploy PIF custom fingerprint config
# osm0sis PlayIntegrityFork reads /data/adb/modules/PIF/custom.pif.prop
if [ -f "$PREINSTALL_DIR/PIF/custom.pif.prop" ]; then
    cp "$PREINSTALL_DIR/PIF/custom.pif.prop" "$MODULES_DIR/PIF/custom.pif.prop"
fi

# Mark installation complete
touch "$FLAG_FILE"

exit 0
