#!/system/bin/sh
# gamecube_z9(CN)_v1.1 - Pure Game Space Module for iQOO Z9 CN (V2361A / PD2361)
# - Zero background daemon (0% CPU / 0% RAM after apply)
# - Zero conflict with thermal_killer_z9(CN)_v1.0

MODDIR="${0%/*}"

if [ "$1" != "--now" ]; then
    _i=0
    while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$_i" -lt 60 ]; do
        sleep 2
        _i=$((_i + 1))
    done
    sleep 3
fi

sh "$MODDIR/gc_ctl.sh" apply >/dev/null 2>&1
exit 0
