#!/system/bin/sh
# gamecube_z9(CN)_v1.0 - Action: Áp dụng lại prop + đồng bộ danh sách game (hữu ích cho Temp Root Late-load)

MODDIR="${0%/*}"

echo "=== gamecube_z9(CN)_v1.0 ==="
echo "Đang áp dụng prop Game Space & đồng bộ VAA/VSR..."

sh "$MODDIR/service.sh" --now

echo ""
echo "[Trạng thái trên máy]"
echo "  Monster+     : prop=$(getprop ro.vivo.support_monster_plus) | APK=$(pm path com.z9cn.gamecube.monsterplus >/dev/null 2>&1 && echo 'Đã cài (bật trong LSPosed)' || echo 'Chưa cài')"
echo "  Sạc nhánh    : game=$(getprop persist.vivo.game_bypass_charge_support) all=$(getprop persist.vivo.all_bypass_charge_support)"
echo "  Hiện FPS     : $(getprop persist.vivo.gamecube.support_fps)"
echo "  Đấu giải/KPL : perist=$(getprop perist.vivo.gamecube.kpl.support) persist=$(getprop persist.vivo.gamecube.kpl.support) files=$(ls /system/etc/gamecube/res/skin/kpl 2>/dev/null | wc -l)"
echo "  VivoSync/G2M : sync=$(getprop persist.sys.supportvivosync) g2m=$(getprop persist.sys.support.g2m)"
echo "  Audio Spatial: $(getprop persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable)"
echo "  VAA / VSR    : vaa=$(getprop sys.game.vaa.gles.enable) vsr=$(getprop sys.game.vsr.pp.enable)"
echo "  AutoVRS      : $(settings get secure autovrs_support 2>/dev/null) (0 = đã tắt mờ viền)"
echo "  Touch Opt    : $(getprop sys.game.touch.opt.enable)"
echo "  WALT Latency : $(cat /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null)"
echo "  GPU Tuner    : $(settings get global GPUTUNER_SWITCH 2>/dev/null)"
echo "  GPU Driver   : $(settings get global updatable_driver_prerelease_opt_in_apps 2>/dev/null)"
_gs=$(content query --uri content://com.vivo.gamecube.provider/support_game --projection package_name 2>/dev/null \
    | sed -n 's/.*package_name=\([a-zA-Z0-9_][a-zA-Z0-9_.]*\).*/\1/p' | tr '\n' ' ')
echo "  Game Space   : ${_gs:-trống}"
echo "  VAA list     : $(settings get global vaa_whitelist_apps 2>/dev/null)"
echo "  VSR list     : $(settings get global vsr_whitelist_apps 2>/dev/null)"
echo ""
echo "Hoàn tất! (0 tiến trình chạy ngầm, không xung đột thermal_killer_z9)"
exit 0
