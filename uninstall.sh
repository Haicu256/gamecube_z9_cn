#!/system/bin/sh
# gamecube_z9(CN)_v1.0 - Khôi phục sạch cài đặt khi gỡ module

if command -v resetprop >/dev/null 2>&1; then
    for _p in \
        perist.vivo.gamecube.kpl.support \
        persist.vivo.gamecube.kpl.support \
        persist.vivo.game_bypass_charge_support \
        persist.vivo.all_bypass_charge_support \
        persist.sys.supportvivosync \
        persist.sys.support.g2m \
        persist.vivo.audio.feature.game_custom_sound_effect.enable \
        persist.vivo.audio.feature.game_custom_sound_effect_enhancement.enable \
        persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable; do
        resetprop --delete "$_p" 2>/dev/null
    done
    resetprop -n sys.game.touch.opt.enable 0 2>/dev/null
fi

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

settings delete secure autovrs_support 2>/dev/null
settings put global vaa_whitelist_apps "" 2>/dev/null
settings put global vsr_whitelist_apps "" 2>/dev/null
exit 0
