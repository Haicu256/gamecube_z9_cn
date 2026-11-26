#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
OUT="gamecube_z9(CN)_v1.3.zip"
rm -f "$OUT"

chmod 0755 customize.sh gc_ctl.sh service.sh action.sh uninstall.sh META-INF/com/google/android/update-binary
chmod 0644 module.prop system.prop apk/GameCubeZ9MonsterPlus.apk bin/gc_touch_db.dex webroot/index.html META-INF/com/google/android/updater-script

zip -r9 "$OUT" \
    META-INF \
    module.prop \
    system.prop \
    customize.sh \
    gc_ctl.sh \
    service.sh \
    action.sh \
    uninstall.sh \
    webroot \
    apk \
    bin \
    system \
    -x "*.DS_Store"

ls -lh "$OUT"
sha256sum "$OUT"
