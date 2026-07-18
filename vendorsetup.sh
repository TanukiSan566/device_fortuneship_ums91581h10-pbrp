add_lunch_combo pb_ums91581h10-user
add_lunch_combo pb_ums91581h10-userdebug
add_lunch_combo pb_ums91581h10-eng

# ============================================================================
# [来自 PBRP 官方参考树 android_device_infinix_X6882-pbrp 的构建期环境变量]
# ============================================================================
# 这些变量是 PBRP/TWRP 血缘上共享自 OrangeFox 的构建期开关（前缀 OF_/FOX_），
# 官方现役维护机型的 vendorsetup.sh 里还在用，所以照抄了一部分：
#
# OF_DEFAULT_KEYMASTER_VERSION：告诉 recovery 优先按这个版本号去找/适配
# keymaster HAL，X6882 那份树填的是 4.1，这里先按同样的值试，如果编译或者
# 实机解密报 keymaster 版本不匹配，去 logcat/recovery.log 里看真机报的是
# 哪个版本号再改。
export OF_DEFAULT_KEYMASTER_VERSION=4.1
#
# FOX_USE_DATA_RECOVERY_FOR_SETTINGS：这一条是本次要解决的"设置不保存"问题
# 里最直接相关的一条——显式让 recovery 把设置文件存到 /data 而不是某个每次
# 开机就清空的临时目录。前提仍然是 /data 必须能被上面那段 crypto 配置成功
# 解密，这条本身不能替代解密，只是告诉 recovery"存 /data 这条路"。
export FOX_USE_DATA_RECOVERY_FOR_SETTINGS=1
#
# 以下几条是通用構建体验相关，跟"设置不保存"无直接关系，一并抄过来跟官方
# 树保持一致：
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
export OF_SUPPORT_VBMETA_AVB2_PATCHING=1
export OF_ENABLE_LPTOOLS=1
export USE_CCACHE=1
export LC_ALL="C"
# ============================================================================
