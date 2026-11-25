#!/system/bin/sh
# gamecube_z9(CN)_v1.0 - Pure Game Space Module for iQOO Z9 CN (V2361A / PD2361)
# - Zero background daemon (0% CPU / 0% RAM after apply)
# - Zero conflict with thermal_killer_z9(CN)_v1.0 and GameCube Tools (LSPosed)
# - Safe for Temp Root (KernelSU Late-load) & Locked Bootloader

MODDIR="${0%/*}"

# Wait for boot completion when launched at boot
if [ "$1" != "--now" ]; then
    _i=0
    while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$_i" -lt 60 ]; do
        sleep 2
        _i=$((_i + 1))
    done
    sleep 3
fi

apply_props() {
    command -v resetprop >/dev/null 2>&1 || return 0
    resetprop -n ro.vivo.support_monster_plus true
    resetprop -n ro.vivo.support_monster_plus_combine true
    resetprop -n persist.vivo.gamecube.support_fps 1
    resetprop -n perist.vivo.gamecube.kpl.support 1
    resetprop -n persist.vivo.gamecube.kpl.support 1
    resetprop -n persist.vivo.game_bypass_charge_support 1
    resetprop -n persist.vivo.all_bypass_charge_support 1
    resetprop -n persist.sys.supportvivosync 1
    resetprop -n persist.sys.support.g2m 1
    resetprop -n persist.vivo.audio.feature.game_custom_sound_effect.enable true
    resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_enhancement.enable true
    resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable true
    resetprop -n sys.game.vsr.pp.enable 1
    resetprop -n sys.game.vaa.gles.enable 1
    resetprop -n sys.game.vaa.vivo.enable 1
    resetprop -n sys.game.vaa.vulkan.enable 1
    resetprop -n sys.game.touch.opt.enable 1
}

collect_games() {
    _raw=""

    # 1. Native vivo Game Space database via official ContentProvider (zero sqlite3 needed!)
    #    Automatically captures every game added by the user in Game Space.
    _cp_pkgs=$(content query --uri content://com.vivo.gamecube.provider/support_game --projection package_name 2>/dev/null \
        | sed -n 's/.*package_name=\([a-zA-Z0-9_][a-zA-Z0-9_.]*\).*/\1/p')
    _raw="$_raw $_cp_pkgs"

    # 2. Fallback: native vivo GameCube / PEM active game lists
    for _val in \
        "$(settings get system pem_ddc_open_game_list 2>/dev/null)" \
        "$(settings get system vivo_sync_game_switch_status 2>/dev/null)" \
        "$(settings get global picture_stability_opt_whitelist_apps 2>/dev/null)"; do
        [ -z "$_val" ] || [ "$_val" = "null" ] && continue
        _pkgs=$(printf '%s\n' "$_val" | tr ':;,#\\' '\n' | grep -E '^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+){1,}$')
        _raw="$_raw $_pkgs"
    done

    # Deduplicate and keep only actually installed packages
    _out=""
    for _p in $_raw; do
        case " $_out " in
            *" $_p "*) continue ;;
        esac
        if [ -d "/data/data/$_p" ]; then
            _out="$_out $_p"
        fi
    done
    printf '%s\n' "$_out"
}

sync_whitelists() {
    # Disable AutoVRS (prevents blurry edge shading on Adreno 720)
    settings put secure autovrs_support 0 2>/dev/null

    # Clear unused XPQ conflict list if previously touched
    settings put global xpq_conflict_list_apps "" 2>/dev/null

    # Enable Qualcomm/vivo Adreno GPU Tuner switch
    settings put global GPUTUNER_SWITCH true 2>/dev/null

    _games=$(collect_games)
    [ -z "$_games" ] && return 0

    for _key in vaa_whitelist_apps vsr_whitelist_apps; do
        _new=""
        for _pkg in $_games; do
            if [ -n "$_new" ]; then
                _new="${_new};${_pkg}"
            else
                _new="$_pkg"
            fi
        done
        settings put global "$_key" "$_new" 2>/dev/null
    done

    # Sync Game Space games into Qualcomm stock Prerelease Graphics Driver (comma-separated)
    if [ -n "$(getprop ro.gfx.driver.1 2>/dev/null)" ]; then
        if [ ! -f /data/adb/.gamecube_z9_gfx_driver.bak ]; then
            _orig_drv=$(settings get global updatable_driver_prerelease_opt_in_apps 2>/dev/null | tr -d '\r\n')
            [ "$_orig_drv" = "null" ] && _orig_drv=""
            printf '%s\n' "$_orig_drv" > /data/adb/.gamecube_z9_gfx_driver.bak 2>/dev/null
        fi
        _drv_new=""
        for _pkg in $_games; do
            if [ -n "$_drv_new" ]; then
                _drv_new="${_drv_new},${_pkg}"
            else
                _drv_new="$_pkg"
            fi
        done
        settings put global updatable_driver_prerelease_opt_in_apps "$_drv_new" 2>/dev/null
    fi

    # Sync all Game Space games into vivo perf_game_list (preserving stock CN list cleanly)
    _perf_cur=$(settings get system perf_game_list 2>/dev/null | tr -d '\r\n')
    if [ -n "$_perf_cur" ] && [ "$_perf_cur" != "null" ]; then
        if [ ! -f /data/adb/.gamecube_z9_perf_game_list.bak ]; then
            printf '%s\n' "$_perf_cur" > /data/adb/.gamecube_z9_perf_game_list.bak 2>/dev/null
        fi
        _perf_base=$(cat /data/adb/.gamecube_z9_perf_game_list.bak 2>/dev/null | tr -d '\r\n')
        [ -z "$_perf_base" ] && _perf_base="$_perf_cur"
        _perf_new="$_perf_base"
        for _pkg in $_games; do
            case ":$_perf_new:" in
                *":$_pkg:"*) ;;
                *)
                    case "$_perf_new" in
                        *:) _perf_new="${_perf_new}${_pkg}:" ;;
                        *)  _perf_new="${_perf_new}:${_pkg}:" ;;
                    esac
                    ;;
            esac
        done
        if [ "$_perf_new" != "$_perf_cur" ]; then
            settings put system perf_game_list "$_perf_new" 2>/dev/null
        fi
    fi
}

apply_scheduler() {
    # Prioritize foreground app wake-up latency on WALT scheduler (improves 1% low FPS without locking idle clocks)
    if [ -w /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive ]; then
        echo 1 > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null
    fi
}

ensure_monsterplus_apk() {
    _apk="$MODDIR/apk/GameCubeZ9MonsterPlus.apk"
    [ -f "$_apk" ] || return 0
    if ! pm path com.z9cn.gamecube.monsterplus >/dev/null 2>&1; then
        pm install -r "$_apk" >/dev/null 2>&1
    fi
}

apply_props
sync_whitelists
apply_scheduler
ensure_monsterplus_apk
exit 0
