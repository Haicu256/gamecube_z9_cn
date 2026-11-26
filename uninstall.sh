#!/system/bin/sh
# gamecube_z9(CN)_v1.3 - Khôi phục sạch cài đặt khi gỡ module

MODDIR="${0%/*}"
TOUCH_DB="/data/user/0/com.vivo.gamecube/databases/support_dimension_list.db"
TOUCH_DEX="$MODDIR/bin/gc_touch_db.dex"
TOUCH_ADDED="/data/adb/.gamecube_z9_touch_added"

if command -v resetprop >/dev/null 2>&1; then
    for _p in \
        perist.vivo.gamecube.kpl.support \
        persist.vivo.gamecube.kpl.support \
        persist.vivo.game_bypass_charge_support \
        persist.vivo.all_bypass_charge_support \
        persist.sys.supportvivosync \
        persist.sys.support.g2m \
        persist.vivo.support.picture_stability_opt \
        persist.vivo.audio.feature.game_custom_sound_effect.enable \
        persist.vivo.audio.feature.game_custom_sound_effect_enhancement.enable \
        persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable; do
        resetprop --delete "$_p" 2>/dev/null
    done
    resetprop -n sys.game.touch.opt.enable 0 2>/dev/null
    resetprop -n ro.vivo.touch.game_para_adjust 0 2>/dev/null
fi

if [ -f "$TOUCH_DB" ] && [ -f "$TOUCH_DEX" ] && [ -f "$TOUCH_ADDED" ]; then
    _tracked=$(tr '\n' ' ' < "$TOUCH_ADDED" 2>/dev/null)
    if [ -n "$_tracked" ]; then
        # shellcheck disable=SC2086
        CLASSPATH="$TOUCH_DEX" app_process64 /system/bin GcTouchDb clear "$TOUCH_DB" $_tracked >/dev/null 2>&1
        for _dbf in "$TOUCH_DB" "${TOUCH_DB}-wal" "${TOUCH_DB}-shm"; do
            [ -e "$_dbf" ] || continue
            chown system:system "$_dbf" 2>/dev/null
            chmod 0660 "$_dbf" 2>/dev/null
            chcon u:object_r:system_app_data_file:s0 "$_dbf" 2>/dev/null
        done
    fi
fi
rm -f "$TOUCH_ADDED"

if [ -f /data/adb/.gamecube_z9_perf_game_list.bak ]; then
    _orig_perf=$(cat /data/adb/.gamecube_z9_perf_game_list.bak 2>/dev/null)
    [ -n "$_orig_perf" ] && settings put system perf_game_list "$_orig_perf" 2>/dev/null
    rm -f /data/adb/.gamecube_z9_perf_game_list.bak
fi

if [ -f /data/adb/.gamecube_z9_gfx_driver.bak ]; then
    _orig_drv=$(cat /data/adb/.gamecube_z9_gfx_driver.bak 2>/dev/null)
    settings put global updatable_driver_prerelease_opt_in_apps "$_orig_drv" 2>/dev/null
    rm -f /data/adb/.gamecube_z9_gfx_driver.bak
fi

[ -w /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive ] && echo 0 > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null

pm uninstall com.z9cn.gamecube.monsterplus >/dev/null 2>&1
rm -f /data/adb/gamecube_z9.conf

# Restore stock GPU/CPU floors if thermal_killer_z9 is not managing them
if [ ! -f /data/adb/modules/vivo_iqoo_thermal_killer/.daemon.lock ] || [ -f /data/adb/modules/vivo_iqoo_thermal_killer/toggle_off ]; then
    [ -e /sys/class/kgsl/kgsl-3d0/min_pwrlevel ] && echo 7 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel 2>/dev/null
    [ -e /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq ] && echo 614400 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
    [ -e /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq ] && echo 652800 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
    [ -e /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq ] && echo 652800 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
fi

settings delete secure autovrs_support 2>/dev/null
settings put global vaa_whitelist_apps "" 2>/dev/null
settings put global vsr_whitelist_apps "" 2>/dev/null
settings put global picture_stability_opt_whitelist_apps "" 2>/dev/null
settings put system enabled_picture_stability_optimize "" 2>/dev/null
exit 0
