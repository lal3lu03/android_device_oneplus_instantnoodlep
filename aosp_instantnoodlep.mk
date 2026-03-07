#
# Copyright (C) 2018 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# PixelOS versioning expects CUSTOM_BUILD to be non-empty.
ifeq ($(strip $(CUSTOM_BUILD)),)
CUSTOM_BUILD := instantnoodlep
endif

# Inherit from instantnoodlep device
$(call inherit-product, device/oneplus/instantnoodlep/device.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/custom/config/common_full_phone.mk)

# Temporary A16 bringup workaround:
# SetupWizard window can remain NOT_VISIBLE/NO_INPUT_CHANNEL and block touch dispatch.
# Skip SUW until framework/package compatibility is fixed.
# Do not override setupwizard.feature.baseline_setupwizard_enabled here because
# Pixel GMS product config already sets it in PRODUCT_PRODUCT_PROPERTIES.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.setupwizard.mode=DISABLED

# NFC - Remove platform NFC packages (APEX-only, use com.android.nfcservices instead)
PRODUCT_PACKAGES := $(filter-out NfcNci framework-nfc framework-nfc.impl,$(PRODUCT_PACKAGES))

PRODUCT_NAME := aosp_instantnoodlep
PRODUCT_DEVICE := instantnoodlep
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := IN2025

PRODUCT_GMS_CLIENTID_BASE := android-oneplus

# Temporary bootloop diagnostics mode.
# Enable only when explicitly requested at build time:
#   INSECURE_ADB_DEBUG=true m bacon ...
# Do not use this mode for public release builds.
ifeq ($(INSECURE_ADB_DEBUG),true)
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    ro.debuggable=1 \
    persist.sys.usb.config=adb
endif

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="OnePlus8Pro-user 13 RKQ1.211119.001 Q.204faf2-2-7cfdc8 test-keys" \
    BuildFingerprint=OnePlus/OnePlus8Pro/OnePlus8Pro:13/RKQ1.211119.001/Q.204faf2-2-7cfdc8:user/test-keys \
    DeviceName=OnePlus8Pro \
    DeviceProduct=OnePlus8Pro \
    SystemDevice=OnePlus8Pro \
    SystemName=OnePlus8Pro
