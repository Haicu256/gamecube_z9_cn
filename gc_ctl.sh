#!/system/bin/sh
# gamecube_z9(CN)_v1.3 - Config & WebUI backend controller
# Zero background daemon; persists toggles in /data/adb/gamecube_z9.conf
# Live hardware clock scan + seamless bridge to thermal_killer_z9 when active

MODDIR="${0%/*}"
CONF="/data/adb/gamecube_z9.conf"
TK_DIR="/data/adb/modules/vivo_iqoo_thermal_killer"
TK_CTL="$TK_DIR/tk_ctl.sh"
TK_LOCK="$TK_DIR/.daemon.lock"
TK_FLAG="$TK_DIR/toggle_off"
TOUCH_DB="/data/user/0/com.vivo.gamecube/databases/support_dimension_list.db"
TOUCH_DEX="$MODDIR/bin/gc_touch_db.dex"
TOUCH_ADDED="/data/adb/.gamecube_z9_touch_added"

# Default feature toggles (1=ON, 0=OFF)
ENABLE_VAA=0
ENABLE_VSR=0
ENABLE_AUTOVRS=0
ENABLE_TOUCH_OPT=1
ENABLE_TOUCH_PRO=1
ENABLE_PIC_STABILITY=0
ENABLE_WALT_LATENCY=1
ENABLE_GPU_DRIVER=1
ENABLE_PERF_LIST=1
ENABLE_AUDIO=1
ENABLE_BYPASS_CHARGE=1
ENABLE_FPS_MONSTER=1

run_resetprop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$@" 2>/dev/null
    elif [ -x /data/adb/ksu/bin/resetprop ]; then
        /data/adb/ksu/bin/resetprop "$@" 2>/dev/null
    elif [ -x /data/adb/ksu/bin/ksud ]; then
        /data/adb/ksu/bin/ksud resetprop "$@" 2>/dev/null
    fi
}

fix_touch_db_perms() {
    for _dbf in "$TOUCH_DB" "${TOUCH_DB}-wal" "${TOUCH_DB}-shm"; do
        [ -e "$_dbf" ] || continue
        chown system:system "$_dbf" 2>/dev/null
        chmod 0660 "$_dbf" 2>/dev/null
        chcon u:object_r:system_app_data_file:s0 "$_dbf" 2>/dev/null
    done
}

load_conf() {
    [ -f "$CONF" ] && . "$CONF" 2>/dev/null
}

save_conf() {
    cat << EOF > "$CONF"
ENABLE_VAA=$ENABLE_VAA
ENABLE_VSR=$ENABLE_VSR
ENABLE_AUTOVRS=$ENABLE_AUTOVRS
ENABLE_TOUCH_OPT=$ENABLE_TOUCH_OPT
ENABLE_TOUCH_PRO=$ENABLE_TOUCH_PRO
ENABLE_PIC_STABILITY=$ENABLE_PIC_STABILITY
ENABLE_WALT_LATENCY=$ENABLE_WALT_LATENCY
ENABLE_GPU_DRIVER=$ENABLE_GPU_DRIVER
ENABLE_PERF_LIST=$ENABLE_PERF_LIST
ENABLE_AUDIO=$ENABLE_AUDIO
ENABLE_BYPASS_CHARGE=$ENABLE_BYPASS_CHARGE
ENABLE_FPS_MONSTER=$ENABLE_FPS_MONSTER
EOF
    chmod 0644 "$CONF" 2>/dev/null
}

collect_games() {
    _raw=""

    _cp_pkgs=$(content query --uri content://com.vivo.gamecube.provider/support_game --projection package_name 2>/dev/null \
        | sed -n 's/.*package_name=\([a-zA-Z0-9_][a-zA-Z0-9_.]*\).*/\1/p')
    _raw="$_raw $_cp_pkgs"

    for _val in \
        "$(settings get system pem_ddc_open_game_list 2>/dev/null)" \
        "$(settings get system vivo_sync_game_switch_status 2>/dev/null)"; do
        [ -z "$_val" ] || [ "$_val" = "null" ] && continue
        _pkgs=$(printf '%s\n' "$_val" | tr ':;,#\\' '\n' | grep -E '^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+){1,}$')
        _raw="$_raw $_pkgs"
    done

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

sync_touch_pro_db() {
    _games_arg="$1"
    [ -f "$TOUCH_DB" ] && [ -f "$TOUCH_DEX" ] || return 0

    if [ "$ENABLE_TOUCH_PRO" = "1" ]; then
        [ -n "$_games_arg" ] || return 0
        # shellcheck disable=SC2086
        _res=$(CLASSPATH="$TOUCH_DEX" app_process64 /system/bin GcTouchDb sync "$TOUCH_DB" $_games_arg 2>/dev/null)
        _added_any=0
        for _line in $_res; do
            case "$_line" in
                ADDED:*)
                    _apkg=${_line#ADDED:}
                    _added_any=1
                    if [ ! -f "$TOUCH_ADDED" ] || ! grep -qx "$_apkg" "$TOUCH_ADDED" 2>/dev/null; then
                        printf '%s\n' "$_apkg" >> "$TOUCH_ADDED"
                    fi
                    ;;
            esac
        done
        [ "$_added_any" = "1" ] && fix_touch_db_perms
    else
        if [ -f "$TOUCH_ADDED" ]; then
            _tracked=$(tr '\n' ' ' < "$TOUCH_ADDED" 2>/dev/null)
            if [ -n "$_tracked" ]; then
                # shellcheck disable=SC2086
                CLASSPATH="$TOUCH_DEX" app_process64 /system/bin GcTouchDb clear "$TOUCH_DB" $_tracked >/dev/null 2>&1
                fix_touch_db_perms
            fi
            rm -f "$TOUCH_ADDED"
        fi
    fi
}

apply_all() {
    load_conf
    [ -f "$CONF" ] || save_conf

    # KPL skin + VivoSync/G2M + Monster+/FPS
    if [ "$ENABLE_FPS_MONSTER" = "1" ]; then
        run_resetprop -n ro.vivo.support_monster_plus true
        run_resetprop -n ro.vivo.support_monster_plus_combine true
        run_resetprop -n persist.vivo.gamecube.support_fps 1
        run_resetprop -n perist.vivo.gamecube.kpl.support 1
        run_resetprop -n persist.vivo.gamecube.kpl.support 1
        run_resetprop -n persist.sys.supportvivosync 1
        run_resetprop -n persist.sys.support.g2m 1
    else
        run_resetprop -n persist.vivo.gamecube.support_fps 0
    fi

    # Bypass Charging
    if [ "$ENABLE_BYPASS_CHARGE" = "1" ]; then
        run_resetprop -n persist.vivo.game_bypass_charge_support 1
        run_resetprop -n persist.vivo.all_bypass_charge_support 1
    else
        run_resetprop -n persist.vivo.game_bypass_charge_support 0
        run_resetprop -n persist.vivo.all_bypass_charge_support 0
    fi

    # Game Audio & Spatializer
    if [ "$ENABLE_AUDIO" = "1" ]; then
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect.enable true
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_enhancement.enable true
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable true
    else
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect.enable false
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_enhancement.enable false
        run_resetprop -n persist.vivo.audio.feature.game_custom_sound_effect_spatializer.enable false
    fi

    # VAA (vivo Anti-Aliasing)
    if [ "$ENABLE_VAA" = "1" ]; then
        run_resetprop -n sys.game.vaa.gles.enable 1
        run_resetprop -n sys.game.vaa.vivo.enable 1
        run_resetprop -n sys.game.vaa.vulkan.enable 1
    else
        run_resetprop -n sys.game.vaa.gles.enable 0
        run_resetprop -n sys.game.vaa.vivo.enable 0
        run_resetprop -n sys.game.vaa.vulkan.enable 0
    fi

    # VSR (Software Super Resolution post-processing)
    if [ "$ENABLE_VSR" = "1" ]; then
        run_resetprop -n sys.game.vsr.pp.enable 1
    else
        run_resetprop -n sys.game.vsr.pp.enable 0
    fi

    # Game Touch Optimization
    if [ "$ENABLE_TOUCH_OPT" = "1" ]; then
        run_resetprop -n sys.game.touch.opt.enable 1
    else
        run_resetprop -n sys.game.touch.opt.enable 0
    fi

    # Pro Touch Parameter Adjustment (default ON)
    if [ "$ENABLE_TOUCH_PRO" = "1" ]; then
        run_resetprop -n ro.vivo.touch.game_para_adjust 1
    else
        run_resetprop -n ro.vivo.touch.game_para_adjust 0
    fi

    # AutoVRS (Variable Rate Shading)
    if [ "$ENABLE_AUTOVRS" = "1" ]; then
        settings put secure autovrs_support 1 2>/dev/null
    else
        settings put secure autovrs_support 0 2>/dev/null
    fi

    # Clear unused XPQ conflict list
    settings put global xpq_conflict_list_apps "" 2>/dev/null

    # WALT top-app latency_sensitive
    if [ -w /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive ]; then
        if [ "$ENABLE_WALT_LATENCY" = "1" ]; then
            echo 1 > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null
        else
            echo 0 > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null
        fi
    fi

    _games=$(collect_games)

    # Sync Game Space games into GameCube touch DB (game_manipulation_touch)
    sync_touch_pro_db "$_games"

    # Picture Stability (default OFF: adds Game Space games when ON, clears when OFF)
    if [ "$ENABLE_PIC_STABILITY" = "1" ]; then
        setprop persist.vivo.support.picture_stability_opt true 2>/dev/null || run_resetprop -n persist.vivo.support.picture_stability_opt true
        _ps_new=""
        for _pkg in $_games; do
            if [ -n "$_ps_new" ]; then _ps_new="${_ps_new};${_pkg}:1"; else _ps_new="${_pkg}:1"; fi
        done
        settings put global picture_stability_opt_whitelist_apps "$_ps_new" 2>/dev/null
        settings put system enabled_picture_stability_optimize "$_ps_new" 2>/dev/null
    else
        setprop persist.vivo.support.picture_stability_opt "" 2>/dev/null || run_resetprop -n persist.vivo.support.picture_stability_opt ""
        settings put global picture_stability_opt_whitelist_apps "" 2>/dev/null
        settings put system enabled_picture_stability_optimize "" 2>/dev/null
    fi

    # VAA whitelist
    if [ "$ENABLE_VAA" = "1" ] && [ -n "$_games" ]; then
        _new=""
        for _pkg in $_games; do
            if [ -n "$_new" ]; then _new="${_new};${_pkg}"; else _new="$_pkg"; fi
        done
        settings put global vaa_whitelist_apps "$_new" 2>/dev/null
    else
        settings put global vaa_whitelist_apps "" 2>/dev/null
    fi

    # VSR whitelist
    if [ "$ENABLE_VSR" = "1" ] && [ -n "$_games" ]; then
        _new=""
        for _pkg in $_games; do
            if [ -n "$_new" ]; then _new="${_new};${_pkg}"; else _new="$_pkg"; fi
        done
        settings put global vsr_whitelist_apps "$_new" 2>/dev/null
    else
        settings put global vsr_whitelist_apps "" 2>/dev/null
    fi

    # GPU Tuner + Stock Qualcomm Prerelease GPU Driver
    if [ "$ENABLE_GPU_DRIVER" = "1" ]; then
        settings put global GPUTUNER_SWITCH true 2>/dev/null
        if [ -n "$(getprop ro.gfx.driver.1 2>/dev/null)" ] && [ -n "$_games" ]; then
            if [ ! -f /data/adb/.gamecube_z9_gfx_driver.bak ]; then
                _orig_drv=$(settings get global updatable_driver_prerelease_opt_in_apps 2>/dev/null | tr -d '\r\n')
                [ "$_orig_drv" = "null" ] && _orig_drv=""
                printf '%s\n' "$_orig_drv" > /data/adb/.gamecube_z9_gfx_driver.bak 2>/dev/null
            fi
            _drv_new=""
            for _pkg in $_games; do
                if [ -n "$_drv_new" ]; then _drv_new="${_drv_new},${_pkg}"; else _drv_new="$_pkg"; fi
            done
            settings put global updatable_driver_prerelease_opt_in_apps "$_drv_new" 2>/dev/null
        fi
    else
        settings put global GPUTUNER_SWITCH false 2>/dev/null
        if [ -f /data/adb/.gamecube_z9_gfx_driver.bak ]; then
            _orig_drv=$(cat /data/adb/.gamecube_z9_gfx_driver.bak 2>/dev/null | tr -d '\r\n')
            settings put global updatable_driver_prerelease_opt_in_apps "$_orig_drv" 2>/dev/null
        else
            settings put global updatable_driver_prerelease_opt_in_apps "" 2>/dev/null
        fi
    fi

    # vivo perf_game_list sync
    _perf_cur=$(settings get system perf_game_list 2>/dev/null | tr -d '\r\n')
    if [ -n "$_perf_cur" ] && [ "$_perf_cur" != "null" ]; then
        if [ ! -f /data/adb/.gamecube_z9_perf_game_list.bak ]; then
            printf '%s\n' "$_perf_cur" > /data/adb/.gamecube_z9_perf_game_list.bak 2>/dev/null
        fi
        _perf_base=$(cat /data/adb/.gamecube_z9_perf_game_list.bak 2>/dev/null | tr -d '\r\n')
        [ -z "$_perf_base" ] && _perf_base="$_perf_cur"
        if [ "$ENABLE_PERF_LIST" = "1" ] && [ -n "$_games" ]; then
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
            [ "$_perf_new" != "$_perf_cur" ] && settings put system perf_game_list "$_perf_new" 2>/dev/null
        else
            [ "$_perf_base" != "$_perf_cur" ] && settings put system perf_game_list "$_perf_base" 2>/dev/null
        fi
    fi

    # Ensure bundled Monster+/Esports LSPosed APK is installed
    _apk="$MODDIR/apk/GameCubeZ9MonsterPlus.apk"
    if [ -f "$_apk" ] && ! pm path com.z9cn.gamecube.monsterplus >/dev/null 2>&1; then
        pm install -r "$_apk" >/dev/null 2>&1
    fi
}

tk_running() {
    [ -x "$TK_CTL" ] || [ -f "$TK_CTL" ] || return 1
    [ -f "$TK_FLAG" ] && return 1
    [ -f "$TK_LOCK" ] || return 1
    _tkp=$(cat "$TK_LOCK" 2>/dev/null)
    [ -n "$_tkp" ] || return 1
    kill -0 "$_tkp" 2>/dev/null || return 1
    tr '\0' ' ' < "/proc/$_tkp/cmdline" 2>/dev/null | grep -q vivo_iqoo_thermal_killer
}

set_gpu_lock() {
    _val="$1"
    if tk_running; then
        if [ "$_val" = "1" ]; then
            sh "$TK_CTL" set gpu_lock_max on >/dev/null 2>&1
        else
            sh "$TK_CTL" set gpu_lock_max off >/dev/null 2>&1
        fi
        return 0
    fi
    _node="/sys/class/kgsl/kgsl-3d0/min_pwrlevel"
    [ -e "$_node" ] || return 0
    chmod 0644 "$_node" 2>/dev/null
    if [ "$_val" = "1" ]; then
        printf '0\n' > "$_node" 2>/dev/null
    else
        _np=$(cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels 2>/dev/null | tr -dc '0-9')
        _stk=7
        if [ -n "$_np" ] && [ "$_np" -gt 1 ]; then _stk=$((_np - 1)); fi
        printf '%s\n' "$_stk" > "$_node" 2>/dev/null
        [ -f "$TK_DIR/gpu_lock_max" ] && printf 'off\n' > "$TK_DIR/gpu_lock_max" 2>/dev/null
    fi
}

set_cpu_lock() {
    _val="$1"
    if tk_running; then
        if [ "$_val" = "1" ]; then
            sh "$TK_CTL" set cpu_lock_max on >/dev/null 2>&1
        else
            sh "$TK_CTL" set cpu_lock_max off >/dev/null 2>&1
        fi
        return 0
    fi
    if [ "$_val" = "1" ]; then
        for _idx in 0 4 7; do
            _mx=$(cat "/sys/devices/system/cpu/cpufreq/policy$_idx/cpuinfo_max_freq" 2>/dev/null | tr -dc '0-9')
            _sn="/sys/devices/system/cpu/cpufreq/policy$_idx/scaling_min_freq"
            [ -n "$_mx" ] && [ -e "$_sn" ] && { chmod 0644 "$_sn" 2>/dev/null; printf '%s\n' "$_mx" > "$_sn" 2>/dev/null; }
        done
    else
        for _pair in "0:614400" "4:652800" "7:652800"; do
            _idx=${_pair%:*}
            _mn=${_pair#*:}
            _sn="/sys/devices/system/cpu/cpufreq/policy$_idx/scaling_min_freq"
            [ -e "$_sn" ] && { chmod 0644 "$_sn" 2>/dev/null; printf '%s\n' "$_mn" > "$_sn" 2>/dev/null; }
        done
        [ -f "$TK_DIR/cpu_lock_max" ] && printf 'off\n' > "$TK_DIR/cpu_lock_max" 2>/dev/null
    fi
}

emit_json() {
    load_conf
    _model=$(getprop ro.product.model 2>/dev/null | tr -d '\r\n"')
    _apk_ok=0
    pm path com.z9cn.gamecube.monsterplus >/dev/null 2>&1 && _apk_ok=1
    _kpl_cnt=$(ls /system/etc/gamecube/res/skin/kpl 2>/dev/null | wc -l | tr -d ' ')
    _games=$(collect_games | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
    _walt=$(cat /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 2>/dev/null | tr -d '\r\n')
    [ -z "$_walt" ] && _walt=0
    _autovrs=$(settings get secure autovrs_support 2>/dev/null | tr -d '\r\n')
    [ -z "$_autovrs" ] || [ "$_autovrs" = "null" ] && _autovrs=0
    _vaa_wl=$(settings get global vaa_whitelist_apps 2>/dev/null | tr -d '\r\n"')
    [ "$_vaa_wl" = "null" ] && _vaa_wl=""
    _vsr_wl=$(settings get global vsr_whitelist_apps 2>/dev/null | tr -d '\r\n"')
    [ "$_vsr_wl" = "null" ] && _vsr_wl=""
    _drv_wl=$(settings get global updatable_driver_prerelease_opt_in_apps 2>/dev/null | tr -d '\r\n"')
    [ "$_drv_wl" = "null" ] && _drv_wl=""
    _ps_wl=$(settings get global picture_stability_opt_whitelist_apps 2>/dev/null | tr -d '\r\n"')
    [ "$_ps_wl" = "null" ] && _ps_wl=""

    # Live hardware scan for GPU / CPU ceiling locks
    _tk_linked=0
    tk_running && _tk_linked=1
    _gmin=$(cat /sys/class/kgsl/kgsl-3d0/min_pwrlevel 2>/dev/null | tr -dc '0-9')
    _gcur=$(cat /sys/class/kgsl/kgsl-3d0/clock_mhz 2>/dev/null | tr -dc '0-9')
    _gmax=$(cat /sys/class/kgsl/kgsl-3d0/max_clock_mhz 2>/dev/null | tr -dc '0-9')
    _gpu_locked=0
    [ "$_gmin" = "0" ] && _gpu_locked=1

    _p0c=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq 2>/dev/null | tr -dc '0-9')
    _p4c=$(cat /sys/devices/system/cpu/cpufreq/policy4/scaling_cur_freq 2>/dev/null | tr -dc '0-9')
    _p7c=$(cat /sys/devices/system/cpu/cpufreq/policy7/scaling_cur_freq 2>/dev/null | tr -dc '0-9')
    _p0n=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null | tr -dc '0-9')
    _p4n=$(cat /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null | tr -dc '0-9')
    _p7n=$(cat /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null | tr -dc '0-9')
    _p0x=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq 2>/dev/null | tr -dc '0-9')
    _p4x=$(cat /sys/devices/system/cpu/cpufreq/policy4/cpuinfo_max_freq 2>/dev/null | tr -dc '0-9')
    _p7x=$(cat /sys/devices/system/cpu/cpufreq/policy7/cpuinfo_max_freq 2>/dev/null | tr -dc '0-9')
    _cpu_locked=0
    if [ -n "$_p0x" ] && [ "$_p0n" = "$_p0x" ] && [ "$_p4n" = "$_p4x" ] && [ "$_p7n" = "$_p7x" ]; then
        _cpu_locked=1
    fi

    printf '{"version":"v1.3","model":"%s","apkInstalled":%s,"kplFiles":%s,"games":"%s","waltLive":%s,"autovrsLive":%s,"vaaList":"%s","vsrList":"%s","drvList":"%s","picStabList":"%s","tkLinked":%s,"hw":{"gpuLocked":%s,"cpuLocked":%s,"gpuCur":%s,"gpuMax":%s,"p0":%s,"p4":%s,"p7":%s},"cfg":{"ENABLE_VAA":%s,"ENABLE_VSR":%s,"ENABLE_AUTOVRS":%s,"ENABLE_TOUCH_OPT":%s,"ENABLE_TOUCH_PRO":%s,"ENABLE_PIC_STABILITY":%s,"ENABLE_WALT_LATENCY":%s,"ENABLE_GPU_DRIVER":%s,"ENABLE_PERF_LIST":%s,"ENABLE_AUDIO":%s,"ENABLE_BYPASS_CHARGE":%s,"ENABLE_FPS_MONSTER":%s,"LOCK_GPU_MAX":%s,"LOCK_CPU_MAX":%s}}\n' \
        "$_model" "$_apk_ok" "${_kpl_cnt:-0}" "$_games" "$_walt" "$_autovrs" "$_vaa_wl" "$_vsr_wl" "$_drv_wl" "$_ps_wl" \
        "$_tk_linked" "$_gpu_locked" "$_cpu_locked" "${_gcur:-0}" "${_gmax:-975}" "${_p0c:-0}" "${_p4c:-0}" "${_p7c:-0}" \
        "$ENABLE_VAA" "$ENABLE_VSR" "$ENABLE_AUTOVRS" "$ENABLE_TOUCH_OPT" "$ENABLE_TOUCH_PRO" "$ENABLE_PIC_STABILITY" "$ENABLE_WALT_LATENCY" \
        "$ENABLE_GPU_DRIVER" "$ENABLE_PERF_LIST" "$ENABLE_AUDIO" "$ENABLE_BYPASS_CHARGE" "$ENABLE_FPS_MONSTER" \
        "$_gpu_locked" "$_cpu_locked"
}

case "$1" in
    status)
        emit_json
        ;;
    apply|sync)
        apply_all
        emit_json
        ;;
    set)
        load_conf
        _k="$2"
        _v="$3"
        case "$_v" in
            0|1) ;;
            *) echo '{"error":"invalid_value"}'; exit 1 ;;
        esac
        case "$_k" in
            LOCK_GPU_MAX)
                set_gpu_lock "$_v"
                emit_json
                ;;
            LOCK_CPU_MAX)
                set_cpu_lock "$_v"
                emit_json
                ;;
            ENABLE_VAA|ENABLE_VSR|ENABLE_AUTOVRS|ENABLE_TOUCH_OPT|ENABLE_TOUCH_PRO|ENABLE_PIC_STABILITY|ENABLE_WALT_LATENCY|ENABLE_GPU_DRIVER|ENABLE_PERF_LIST|ENABLE_AUDIO|ENABLE_BYPASS_CHARGE|ENABLE_FPS_MONSTER)
                eval "$_k=$_v"
                save_conf
                apply_all
                emit_json
                ;;
            *)
                echo '{"error":"unknown_key"}'
                exit 1
                ;;
        esac
        ;;
    restart_gc)
        am force-stop com.vivo.gamecube 2>/dev/null
        echo '{"ok":true}'
        ;;
    reset)
        rm -f "$CONF"
        ENABLE_VAA=0
        ENABLE_VSR=0
        ENABLE_AUTOVRS=0
        ENABLE_TOUCH_OPT=1
        ENABLE_TOUCH_PRO=1
        ENABLE_PIC_STABILITY=0
        ENABLE_WALT_LATENCY=1
        ENABLE_GPU_DRIVER=1
        ENABLE_PERF_LIST=1
        ENABLE_AUDIO=1
        ENABLE_BYPASS_CHARGE=1
        ENABLE_FPS_MONSTER=1
        save_conf
        apply_all
        set_gpu_lock 0
        set_cpu_lock 0
        emit_json
        ;;
    *)
        echo "Usage: $0 {status|apply|sync|set <KEY> <0|1>|restart_gc|reset}"
        exit 1
        ;;
esac
exit 0
