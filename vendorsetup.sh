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
# FOX_USE_DATA_RECOVERY_FOR_SETTINGS：[2026-07-19 关闭，原因见下]
# 之前理解有误——查了OrangeFox官方flag文档(orangefox_build_vars.txt)才发现，
# 这条其实标的是[EXPERIMENTAL]，作用是把设置存到/data/recovery/Fox/(注意不是
# /data/media/0，是/data分区自己DE区域一个专门目录，官方文档原话是"因为
# /data/recovery/一直可用，所以解密失败时设置依然能存取"——这条本身理论上不
# 需要解密，跟原来注释里理解的正好相反)。但官方文档明确标了HIGHLY
# EXPERIMENTAL，而且有个副作用：用户在TWRP里格式化/wipe data时这个目录会被
# 一起清掉。
# 现在settingsstorage这条路(见 system/etc/twrp.flags 里 /cache 那两行)是TWRP
# 从很早期版本就有的成熟机制，非experimental，跟FBE解密、/data怎么wipe完全
# 没关系，只有用户主动清Cache才会丢设置。两条机制大概率是编译期二选一
# (具体看recovery源码data.cpp里SaveValues()的条件编译分支，没有确认是哪个
# 优先)，为了避免两边打架、增加不确定性，这次先只留settingsstorage这条更
# 稳的路，这条注释掉。如果之后想复测FOX_USE_DATA_RECOVERY_FOR_SETTINGS，
# 记得先看清楚它和settingsstorage谁会覆盖谁。
#export FOX_USE_DATA_RECOVERY_FOR_SETTINGS=1
#
# 以下几条是通用構建体验相关，跟"设置不保存"无直接关系，一并抄过来跟官方
# 树保持一致：
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
export OF_SUPPORT_VBMETA_AVB2_PATCHING=1
export OF_ENABLE_LPTOOLS=1
export USE_CCACHE=1
export LC_ALL="C"
# ============================================================================
