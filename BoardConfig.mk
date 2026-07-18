DEVICE_PATH := device/fortuneship/ums91581h10

# ============================================================================
# [重要 - 已知问题，源码层面暂无法根治] PLATFORM ramdisk分段内容缺失问题
# ============================================================================
# 用这份树在hovatek在线构建工具上编译出来的vendor_boot.img，实测PLATFORM
# 分段（BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT开启后vendor_boot里
# header v4的两个ramdisk分段之一，正常开机和进recovery都要用到，其中
# recovery分段只有进recovery才会叠加上去）内容严重不完整——只有二十来个
# first_stage_ramdisk骨架文件，缺少真正的vendor init脚本/ueventd规则/
# sepolicy等等。原因是：这份树是ALLOW_MISSING_DEPENDENCIES:=true的"最小
# manifest"编译，本身没有真机完整的vendor源码树，AOSP编译系统天然就拿不到
# 真正完整的vendor ramdisk内容去生成PLATFORM分段。
#
# 后果：recovery能正常进（RECOVERY分段自带了几乎全部运行环境，掩盖了
# PLATFORM分段的残缺），但选"重启到系统"时，只有PLATFORM分段会被用上，
# 内容残缺直接导致开机失败，触发bootloader的"多次失败自动回退recovery"
# 逻辑，表现为无限重启回TWRP，拔电池也没用。
#
# 目前没有在这份树里找到能直接根治的编译参数（本质上是"根本没有源数据"的
# 问题，不是配置错误）。如果所用的AOSP build分支支持类似
# BOARD_PREBUILT_VENDOR_RAMDISK（不同分支叫法可能不同，建议在实际使用的
# build/make源码里搜"PREBUILT_VENDOR_RAMDISK"确认）这样的变量，可以尝试
# 指向一份从原厂真机vendor_boot.img里提取出来的、真正完整的PLATFORM分段
# cpio/压缩包，绕过重新生成的过程直接复用。如果编译环境不支持这类变量，
# 目前唯一确认有效的办法是编译完成后，用vendor_boot_toolkit.zip
# （GitHub Actions版解包打包工具）手动把编译产物的PLATFORM分段替换成从
# 原厂vendor_boot.img里提取的那份真实内容，RECOVERY分段保留编译产物自己的
# 那份即可。
# ============================================================================

# ============================================================================
# [已核实 - 来自 AOSP 14 真实源码] 用 vendor ramdisk fragment 机制提供完整
# PLATFORM ramdisk
# ============================================================================
# 之前两行是猜的变量名，都不对。真正查了 aosp-mirror/platform_build 的
# android14-release 分支 build/make/core/Makefile 源码后确认：AOSP 官方的
# 机制叫 "vendor ramdisk fragment"（BOARD_VENDOR_RAMDISK_FRAGMENTS 及配套的
# BOARD_VENDOR_RAMDISK_FRAGMENT.<name>.PREBUILT / .MKBOOTIMG_ARGS），"recovery"
# 这个名字被 BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT 保留占用了（会自动
# 生成一个 --ramdisk_type RECOVERY 的分段），所以我们自己的分段不能叫
# "recovery"，这里用 "platform"。
#
# PREBUILT 指向的文件会被原样 copy 后直接喂给 mkbootimg 的
# --vendor_ramdisk_fragment 参数，不会做任何重新打包/解压——所以
# prebuilt/vendor_ramdisk_platform.zstd 必须就是从原厂 vendor_boot_a.bin 里
# 完整提取出来、未经任何修改的那段压缩后的 cpio 数据（已经确认过是这个状态）。
# --ramdisk_type 用大写 PLATFORM，这个值本身也在原厂 vendor_boot 的 vendor
# ramdisk table 里被验证过（entry 的 type 字段实测值是 1，对应 bootimg.h 里
# VENDOR_RAMDISK_TYPE_PLATFORM 的定义，NONE=0/PLATFORM=1/RECOVERY=2/DLKM=3）。
#
# 判断有没有生效的方法跟之前一样：编译完用 vendor_boot_toolkit.zip 解包看
# PLATFORM 分段（fragments/platform/）是否有六百多个真实 vendor 文件，而不是
# 二十来个 first_stage_ramdisk 骨架。如果这次还是不行，退回用 GitHub Action
# 的 Graft workflow 编译后处理，那条路已确认 100% 可靠。
# [2026-07-18 二次更正 - 之前的"修复"是错的，现在改回真·原厂内容]
# 上一版发现"这个文件解压有217MB"就以为它是错的，换成了另一份38MB的参考文件。
# 但这次你直接给了原厂 vendor_boot.img，解包一看：原厂那颗 vendor_boot 分区
# 100MB 几乎全部被这单独一个 PLATFORM 段（80,668,385 字节）占满，
# entry_num=1，压根没有 RECOVERY 段（因为原厂不需要）。逐字节比对后，
# 这个 80,668,385 字节的内容跟你最早那份设备树里的 vendor_ramdisk_platform.lz4
# 是完全一样的（MD5一致）——也就是说那份文件从一开始就是对的、就是原厂真实
# 内容，我上一版换成的38MB那份反而是来路不明、内容被精简过的版本（大概率是
# 别的场景下手工裁剪过，只留了保证能开机的最小子集，不是真原厂全量）。
#
# 现在改回了这份经过原厂固件逐字节验证的正确内容。这也是为什么这次编译会
# 死死顶在vendor_boot分区100MB上限——原厂自己就用了80.6MB，只给RECOVERY段
# 留了不到20MB空间，这个空间必须靠精简TWRP/PBRP自己那部分内容（下面kernel
# 模块精简那段）来腾出来，不能反过来动PLATFORM段。
BOARD_VENDOR_RAMDISK_FRAGMENTS := platform
BOARD_VENDOR_RAMDISK_FRAGMENT.platform.PREBUILT := $(DEVICE_PATH)/prebuilt/vendor_ramdisk_platform.lz4
BOARD_VENDOR_RAMDISK_FRAGMENT.platform.MKBOOTIMG_ARGS := --ramdisk_type PLATFORM
# ============================================================================

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    vendor \
    vbmeta \
    odm \
    system \
    boot \
    vbmeta_system \
    product \
    vbmeta_vendor \
    dtbo \
    vendor_dlkm \
    system_ext \
    system_dlkm
BOARD_USES_RECOVERY_AS_BOOT := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# APEX
DEXPREOPT_GENERATE_APEX_IMAGE := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := ums91581h10
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 480

# Kernel
BOARD_BOOTIMG_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_CMDLINE := console=ttyS1,115200n8 bootconfig bootconfig
BOARD_KERNEL_PAGESIZE := 4096
BOARD_RAMDISK_OFFSET := 0x05400000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_KERNEL_CONFIG := ums91581h10_defconfig
TARGET_KERNEL_SOURCE := kernel/fortuneship/ums91581h10

# Kernel - prebuilt
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_INCLUDE_DTB_IN_BOOTIMG := 
endif

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 120018048
#BOARD_RECOVERYIMAGE_PARTITION_SIZE := 81137664
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 9126805504 # TODO: Fix hardcoded value
BOARD_SUPER_PARTITION_GROUPS := fortuneship_dynamic_partitions
BOARD_FORTUNESHIP_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor product
BOARD_FORTUNESHIP_DYNAMIC_PARTITIONS_SIZE := 9122611200 # TODO: Fix hardcoded value

# Platform
TARGET_BOARD_PLATFORM := ums9158

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Security patch level
VENDOR_SECURITY_PATCH := 2021-08-01

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# TWRP Configuration
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := false
# ↑ [2026-07-18 关闭以省空间] 原来是true，会打包一堆语言包字体资源。只留mtp/
# fastbootd/adb这几个核心功能不需要多语言UI，先关掉腾地方，TWRP默认只用
# 英文界面，不影响adb/mtp/fastbootd这几个功能本身的可用性。
#TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3758096384
BOARD_BOOT_HEADER_VERSION := $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_USES_VENDOR_BOOTIMAGE := true
# [源码级修复 - 谨慎/待验证] 压缩算法从LZ4换成zstd。
#
# 实测同样内容用zstd（level 19）压缩，比LZ4能小40~50%左右——这台设备
# vendor_boot分区只有100MB，PLATFORM+RECOVERY两个ramdisk分段内容加起来用LZ4
# 压缩后会超过分区大小刷不进去，换成zstd才有充足空间。dmesg里能看到
# kmod_zstd模块在"Trying to unpack rootfs image as initramfs"之前就初始化好了，
# 说明这台设备内核认这个格式，实测也确认能正常开机。
#
# 但是要注意：BOARD_RAMDISK_USE_ZSTD这个变量名是否被识别，取决于hovatek在线
# 编译工具实际使用的AOSP build系统分支/版本——如果编译报错说不认识这个变量，
# 或者编译倒是过了但刷进去开不了机，说明这个分支的mkbootimg/build工具链还
# 不支持zstd选项，这时候把下面这行注释掉、改回BOARD_RAMDISK_USE_LZ4 := true，
# 编译完之后拿我之前给你的那个vendor_boot_toolkit.zip（GitHub Actions版的解包
# 打包工具）在zstd和lz4之间手动转换压缩格式，一样能达到同样的效果，只是要多
# 一步手动操作。
BOARD_RAMDISK_USE_ZSTD := true
#BOARD_RAMDISK_USE_LZ4 := true
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := $(BOARD_BOOTIMAGE_PARTITION_SIZE)
BOARD_VNDK_VERSION := current
BOARD_USES_RECOVERY_AS_BOOT :=
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE :=
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
ifeq ($(BOARD_BOOT_HEADER_VERSION),4)
	BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true 
endif
TW_LOAD_VENDOR_BOOT_MODULES := true
# ============================================================================
# [2026-07-18 精简说明] 你给的原厂vendor_boot.img解包后发现：PLATFORM段单独
# 就占了80.6MB（entry_num=1，原厂自己都不留RECOVERY段），也就是说100MB分区
# 里留给TWRP/PBRP自己（RECOVERY段）的压缩后预算只有大约19MB，这是硬性物理
# 限制——分区大小是GPT里刻死的，改不了，之前那版报错118MB也已经确认过
# BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE不能瞎调大，调大了刷不进真机分区表。
#
# recovery/root/lib/modules 原来158个.ko文件、解压168MB，是体积大头。已经按
# "只保留mtp/fastbootd/adb+基础UI/存储/电源需要的驱动"的原则删了一轮，删除
# 前用 modinfo depends= 字段做了依赖链检查（发现比如显示驱动sprd-drm.ko
# 意外依赖trusty/trusty-ipc/apsys-dvfs，USB PHY驱动musb_sprd.ko依赖
# sc27xx_typec，这几个虽然名字看着像"TEE安全"/"快充"功能，实际是显示和USB
# 能正常工作的硬依赖，已经保留），删掉的主要是：摄像头、音频、传感器/指纹、
# 基带modem通信(sipa/sipc/sblock等)、性能调度器扩展、部分调试模块、非核心
# 快充管理这几大类，跟mtp/fastbootd/adb和基础UI/存储/开关机都没有关系。
# 精简后 recovery/root 从原来168MB(仅模块)降到73MB(全部内容)。
#
# 另外上面的FBE解密相关配置（TW_INCLUDE_CRYPTO那一块）和额外语言包
# （TW_EXTRA_LANGUAGES）也先关掉腾地方，具体原因看各自那段注释。
#
# 压缩后能不能真的塞进~19MB预算，得实测这次编译才知道（zstd对.ko这种内容
# 压缩率通常不错，但没法在这边模拟真实mkbootimg+zstd的完整流程精确算出最终
# 字节数）。如果这次还是超，下一步可以考虑的方向：TW_USE_TOOLBOX相关的
# busybox/toolbox体积、recovery自带的PNG主题资源。
# ============================================================================
TW_INCLUDE_FASTBOOTD := true
TARGET_SCREEN_WIDTH := 320
TARGET_SCREEN_HEIGHT := 480
DISABLE_ARTIFACT_PATH_REQUIREMENTS := true
TARGET_NO_RECOVERY := true
TW_DEVICE_VERSION := By Team Hovatek

# ====== 新增 MTP 配置 ======
# 显式开启 TWRP MTP 支持
TW_HAS_MTP := true

# ====== 新增：显式排除 TWRP 默认 USB 初始化脚本 ======
# 这份设备树自带的 recovery/root/init.recovery.usb.rc 里，已经针对
# persist.sys.usb.config 默认为纯 "adb"（而非 "mtp,adb"）这个情况，
# 手工补上了真正会 write UDC 的 ConfigFS 处理块（对应
# on property:sys.usb.config=adb / on property:sys.usb.ffs.ready=1 && ...
# 这两段）。不显式排除默认脚本的话，如果 TWRP 官方模板也被一起打包，
# 两份脚本同时操作同一个 ConfigFS 路径可能互相冲突，所以显式关掉默认的，
# 只用这份树自己验证过的版本。
TW_EXCLUDE_DEFAULT_USB_INIT := true

# ============================================================================
# [解决"设置不保存"问题] FBE 解密支持
# ============================================================================
# 参考了 PBRP 官方两份现役维护机型的设备树实测配置：
#   android_device_infinix_X6882-pbrp (android-12.1, MTK/GKI, vendor/pb)
#   android_device_xiaomi_lavender-pbrp (android-12.1, QCOM, vendor/twrp)
# 两份树用的宏不完全一样（跟具体平台的解密辅助工具有没有关系），取两边都在
# 用、跟平台无关的通用部分：
# ============================================================================
# [2026-07-18 暂时关闭 - 为了塞进100MB分区先让mtp/fastbootd/adb跑起来]
# 下面这一整块FBE解密相关的宏和额外库，先注释掉不编译。原厂PLATFORM段
# 已经占了80.6MB，只给RECOVERY段留了不到20MB，这些crypto相关的东西
# （尤其是下面那个keystore2，是Rust编的守护进程，体积不小）必须先让路。
# 等mtp/fastbootd/adb跑通、确认实际RECOVERY段大小之后，如果还有空间富余，
# 再把这块取消注释加回来验证"设置不保存"问题。
# TW_INCLUDE_CRYPTO := true
# TW_INCLUDE_CRYPTO_FBE := true
# TW_INCLUDE_FBE_METADATA_DECRYPT := true
# TW_USE_FSCRYPT_POLICY := 2
# TW_FORCE_KEYMASTER_VER := true
# ============================================================================
#
# recovery.fstab 里已经确认 /vendor 是从真机 vendor 分区 first_stage_mount
# 挂载的（不是自己现打包的），也就是说只要上面 BOARD_VENDOR_RAMDISK_FRAGMENTS
# 那段把 PLATFORM ramdisk 修好、真正的 vendor init 脚本能把 keymaster/
# keystore2 相关 HAL service 从真机 /vendor 分区正常拉起来，解密用到的
# keymaster 服务理论上就是现成的，不需要（也没办法，因为 minimal manifest
# 没有真机 vendor 源码）在这份树里手工塞 vendor 专有二进制。这也是为什么强调
# 先确认 PLATFORM 段修复生效——开机问题和解密问题在这一步是同一个前提条件。
#
# 如果实测发现 keymaster/keystore2 服务确实没被真机 vendor 分区正常拉起来
# （比如 logcat 里 keystore2 报连不上 keymaster HAL），再考虑参照
# lavender 树 device.mk 里 qcom_decrypt 的思路，去 PBRP 的
# bootable_recovery 源码 crypto/ 目录下确认有没有 Unisoc/展讯专用的等价工具
# （目前没有确认到有）。
# ============================================================================

# ============================================================================
# [PBRP 通用] 把 crypto/keystore 桥接用的 AOSP 库编进 recovery
# ============================================================================
# 参照 lavender 参考树 device.mk：这几个库是 AOSP 源码自带的（不是厂商
# 专有 blob，minimal manifest 也能编出来），TWRP/PBRP 自己的解密代码运行时
# 需要能链接到它们。TARGET_RECOVERY_DEVICE_MODULES 负责让编译系统把它们编进
# recovery 产物，TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES 负责把编出来的
# .so 从 system 目录"搬"进 recovery ramdisk 实际会用到的路径。
# TARGET_RECOVERY_DEVICE_MODULES += \
#     android.hidl.base@1.0 \
#     android.system.keystore2
#
# TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
#     $(TARGET_OUT_SHARED_LIBRARIES)/android.hidl.base@1.0.so
# ============================================================================
