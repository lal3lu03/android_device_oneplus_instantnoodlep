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

# NFC - Remove platform NFC packages (APEX-only, use com.android.nfcservices instead)
PRODUCT_PACKAGES := $(filter-out NfcNci framework-nfc framework-nfc.impl,$(PRODUCT_PACKAGES))

PRODUCT_NAME := aosp_instantnoodlep
PRODUCT_DEVICE := instantnoodlep
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := IN2025

PRODUCT_GMS_CLIENTID_BASE := android-oneplus

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="OnePlus8Pro-user 13 RKQ1.211119.001 Q.204faf2-2-7cfdc8 release-keys" \
    BuildFingerprint=OnePlus/OnePlus8Pro/OnePlus8Pro:13/RKQ1.211119.001/Q.204faf2-2-7cfdc8:user/release-keys \
    DeviceName=OnePlus8Pro \
    DeviceProduct=OnePlus8Pro \
    SystemDevice=OnePlus8Pro \
    SystemName=OnePlus8Pro
