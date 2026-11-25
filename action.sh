#!/system/bin/sh
# gamecube_z9(CN)_v1.1 - Action: Áp dụng lại cấu hình + đồng bộ Game Space

MODDIR="${0%/*}"

echo "=== gamecube_z9(CN)_v1.1 ==="
echo "Đang áp dụng cấu hình & đồng bộ game từ Game Space..."

sh "$MODDIR/gc_ctl.sh" apply >/dev/null 2>&1
[ -f /data/adb/gamecube_z9.conf ] && . /data/adb/gamecube_z9.conf 2>/dev/null

echo ""
echo "[Trạng thái trên máy]"
echo "  Monster+ / FPS : prop=$(getprop ro.vivo.support_monster_plus) fps=$(getprop persist.vivo.gamecube.support_fps) | APK=$(pm path com.z9cn.gamecube.monsterplus >/dev/null 2>&1 && echo 'Đã cài' || echo 'Chưa cài')"
echo "  Skin KPL       : $(ls /system/etc/gamecube/res/skin/kpl 2>/dev/null | wc -l) files"
echo "  Sạc nhánh      : ${ENABLE_BYPASS_CHARGE:-1}"
echo "  Audio Spatial  : ${ENABLE_AUDIO:-1}"
echo "  VAA / VSR      : vaa=${ENABLE_VAA:-1} vsr=${ENABLE_VSR:-1} | AutoVRS=$(settings get secure autovrs_support 2>/dev/null)"
echo "  Touch Opt      : $(getprop sys.game.touch.opt.enable)"
echo "  WALT Latency   : $(cat /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null)"
echo "  GPU Driver     : tuner=$(settings get global GPUTUNER_SWITCH 2>/dev/null) apps=$(settings get global updatable_driver_prerelease_opt_in_apps 2>/dev/null)"
echo "  VAA list       : $(settings get global vaa_whitelist_apps 2>/dev/null)"
echo "  VSR list       : $(settings get global vsr_whitelist_apps 2>/dev/null)"
echo ""
echo "Mẹo: Bấm nút [Mở / WebUI] trong KernelSU Manager để bật/tắt từng tính năng trực quan."
exit 0
