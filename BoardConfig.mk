#
# Copyright (C) 2018 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Include the common OEM chipset BoardConfig.
include device/oneplus/sm8250-common/BoardConfigCommon.mk

DEVICE_PATH := device/oneplus/instantnoodlep

# PixelOS build context for aosp_* lunch combos.
# vendor/custom/envsetup exports CUSTOM_BUILD as empty for non-custom_* products,
# so default it explicitly when unset/blank.
ifeq ($(strip $(CUSTOM_BUILD)),)
CUSTOM_BUILD := instantnoodlep
endif

# Ensure dtbo is exported into target-files/releasetools metadata.
BOARD_PREBUILT_DTBOIMAGE ?= $(TARGET_OUT_INTERMEDIATES)/DTBO_OBJ/arch/$(TARGET_ARCH)/boot/dtbo.img

# Display
TARGET_SCREEN_DENSITY := 450

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Partitions
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 7511998464
BOARD_SUPER_PARTITION_SIZE := 15032385536
AB_OTA_PARTITIONS := $(filter-out recovery,$(AB_OTA_PARTITIONS))

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.qcom
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 103
TARGET_NO_RECOVERY := true

# Include the proprietary files BoardConfig.
include vendor/oneplus/instantnoodlep/BoardConfigVendor.mk
