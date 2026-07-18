# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common PBRP stuff.
$(call inherit-product, vendor/pb/config/common.mk)

# Inherit from ums91581h10 device
$(call inherit-product, device/fortuneship/ums91581h10/device.mk)

PRODUCT_DEVICE := ums91581h10
PRODUCT_NAME := pb_ums91581h10
PRODUCT_BRAND := RongYue
PRODUCT_MODEL := E5
PRODUCT_MANUFACTURER := fortuneship

PRODUCT_GMS_CLIENTID_BASE := android-fortuneship

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="TS305_V03_20241128_2301"

BUILD_FINGERPRINT := UNISOC/ums91581h10_cmcc/ums91581h10:13/TP1A.220624.014/2024112822:user/release-keys
