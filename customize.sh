#!/system/bin/sh
# gamecube_z9(CN)_v1.0 - KernelSU installer hook

ui_print "========================================="
ui_print "   gamecube_z9(CN)_v1.0 (iQOO Z9 CN)     "
ui_print "========================================="

APK="$MODPATH/apk/GameCubeZ9MonsterPlus.apk"
if [ -f "$APK" ]; then
    ui_print "- Đang cài APK LSPosed: GameCube Z9 Monster+..."
    if pm install -r -g "$APK" >/dev/null 2>&1 || pm install -r "$APK" >/dev/null 2>&1; then
        ui_print "  [OK] Đã cài xong GameCube Z9 Monster+!"
        ui_print "  -> Sau khi Soft Reboot, vào LSPosed bật 'GameCube Z9 Monster+'"
        ui_print "     (scope: com.vivo.gamecube) để hiện nút Monster+."
    else
        ui_print "  [!] Sẽ tự cài lại APK sau khi khởi động xong (service.sh)."
    fi
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
