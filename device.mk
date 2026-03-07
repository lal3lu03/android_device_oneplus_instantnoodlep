#
# Copyright (C) 2018-2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_platform_info_intcodec.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info_intcodec.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(LOCAL_PATH)/audio/sound_trigger_mixer_paths.xml:$(TARGET_COPY_OUT_ODM)/etc/sound_trigger_mixer_paths.xml \
    $(LOCAL_PATH)/audio/sound_trigger_platform_info.xml:$(TARGET_COPY_OUT_ODM)/etc/sound_trigger_platform_info.xml

# Boot animation
TARGET_SCREEN_HEIGHT := 2376
TARGET_SCREEN_WIDTH := 1080

# Configstore
PRODUCT_PACKAGES += \
    disable_configstore

# Device init scripts
PRODUCT_PACKAGES += \
    fstab.qcom \
    fstab.qcom.ramdisk

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/zz_fps_hal_override.rc:$(TARGET_COPY_OUT_ODM)/etc/init/zz_fps_hal_override.rc \
    $(LOCAL_PATH)/init/zz_vl53l1_daemon_override.rc:$(TARGET_COPY_OUT_ODM)/etc/init/zz_vl53l1_daemon_override.rc \
    $(LOCAL_PATH)/init/zz_vendor.aidl_hal_overrides.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/zz_vendor.aidl_hal_overrides.rc

# Display
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/display_id_4630947194340276609.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947194340276609.xml

# Input
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/input/touchpanel.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/touchpanel.idc

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    KeyHandlerResTarget \
    OPlusFrameworksResTarget \
    OPlusSettingsProviderResTarget \
    OPlusSettingsResTarget \
    OPlusSystemUIResTarget

# PowerShare
PRODUCT_PACKAGES += \
    vendor.lineage.powershare-service.oplus

# Shipping API
PRODUCT_SHIPPING_API_LEVEL := 29

# SELinux
PRODUCT_PRECOMPILED_SEPOLICY := false

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Touch
$(call soong_config_set,OPLUS_LINEAGE_TOUCH_HAL,INCLUDE_DIR,$(LOCAL_PATH)/touch/include)

# LiveDisplay
$(call soong_config_set_bool,OPLUS_LINEAGE_LIVEDISPLAY_HAL,ENABLE_SE,true)
$(call soong_config_set_bool,OPLUS_LINEAGE_LIVEDISPLAY_HAL,ENABLE_PA,true)

# Inherit from the common OEM chipset makefile.
$(call inherit-product, device/oneplus/sm8250-common/common.mk)


# Inherit from the proprietary files makefile.
$(call inherit-product, vendor/oneplus/instantnoodlep/instantnoodlep-vendor.mk)
