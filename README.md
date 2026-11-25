# gamecube_z9(CN)_v1.2

Pure, zero-bloat **KernelSU (with built-in WebUI) + LSPosed** Game Space module built specifically for **vivo iQOO Z9 CN (`V2361A` / `PD2361` / Snapdragon 7 Gen 3 `SM7550` / OriginOS 5)**.

Module mở khóa toàn diện **Game Space (Siêu trò chơi)** kèm **WebUI bật/tắt từng tính năng trực quan** tối ưu riêng cho **iQOO Z9 CN (`V2361A` / `PD2361` / OriginOS 5)** — giữ 100% tính năng hoạt động thật, xóa sạch tính năng Q2 ảo và không xung đột với [`thermal_killer_z9_cn`](https://github.com/Haicu256/thermal_killer_z9_cn).

---

## 🇻🇳 Tiếng Việt

### 1. Thiết bị hỗ trợ & xác minh thực tế
| Thông số | Giá trị đã kiểm chứng |
|---|---|
| **Thiết bị** | vivo iQOO Z9 CN (`V2361A` / `PD2361`) |
| **Vi xử lý / GPU** | Qualcomm Snapdragon 7 Gen 3 (`SM7550` / Adreno 720) |
| **Hệ điều hành** | OriginOS 5 (Android 15 / API 35) |
| **Môi trường Root** | KernelSU (hỗ trợ cả **Temp Root Late-load** + Bootloader khóa) & LSPosed |
| **Mức tiêu thụ nền** | **0 tiến trình chạy ngầm (`0% CPU / 0% RAM`)** — không cần tắt khi không chơi game |

---

### 2. Tính năng đầy đủ (đã xác minh trực tiếp trên `GameCube.apk` của Z9 CN)

#### A. Phần KernelSU (`system.prop` + `service.sh` + `action.sh`)
- **Skin KPL đầy đủ (`393` file):** Mount an toàn vào `/system/etc/gamecube/res/skin/kpl` kèm cả 2 prop `perist.vivo.gamecube.kpl.support=1` (đúng tên prop vivo viết trong `GameCube.apk`) và `persist.vivo.gamecube.kpl.support=1`.
- **Sạc nhánh (Bypass Charging):** `persist.vivo.game_bypass_charge_support=1` & `persist.vivo.all_bypass_charge_support=1`.
- **Hiển thị FPS & Monster+ nền:** `persist.vivo.gamecube.support_fps=1`, `ro.vivo.support_monster_plus=true`, `ro.vivo.support_monster_plus_combine=true`.
- **VivoSync, G2M & Âm thanh game Spatializer:** Bật đủ bộ prop hỗ trợ thực tế trên ROM Z9 CN.
- **Khóa trần xung GPU / CPU (Quét trực tiếp phần cứng + Đồng bộ `thermal_killer_z9`):**
  - Mỗi lần mở WebUI, `gc_ctl.sh` quét trực tiếp `/sys` (`min_pwrlevel`, `policy0/4/7 scaling_min_freq`) để hiển thị chính xác trạng thái bật/tắt & xung thực tế.
  - Nếu máy có cài [`thermal_killer_z9_cn`](https://github.com/Haicu256/thermal_killer_z9_cn) đang chạy, công tắc sẽ đồng bộ trực tiếp qua `tk_ctl.sh` (0 xung đột, 0 tiến trình nền thêm, vẫn được `temp_guard` bảo vệ); nếu dùng độc lập thì ghi/khôi phục trực tiếp `/sys`.
- **VAA / VSR mềm & AutoVRS (tích hợp công tắc WebUI):** Mặc định **TẮT** cả VAA, VSR và AutoVRS để GPU nhẹ tải và hình sắc nét tự nhiên nhất; có thể bật/tắt tức thì bất cứ lúc nào trong **WebUI của KernelSU**.
- **Tối ưu cảm ứng game:** Bật `sys.game.touch.opt.enable=1` (tận dụng `ro.vivo.touch.game_para_adjust=1` có sẵn trên máy).
- **Scheduler WALT ưu tiên độ trễ:** Bật `/dev/cpuctl/top-app/cpu.uclamp.latency_sensitive = 1` (tăng độ mượt 1% low FPS mà không khóa xung khi nghỉ).
- **Adreno GPU Tuner:** Bật `GPUTUNER_SWITCH=true`.
- **Tự động đồng bộ mọi game bạn thêm vào Game Space** (đọc trực tiếp qua ContentProvider chính chủ `content://com.vivo.gamecube.provider/support_game`, không cần `sqlite3`):
  - Tự thêm vào **`perf_game_list`** (khắc phục việc ROM nội địa TQ bỏ sót Liên Quân VN `com.garena.game.kgvn` và các game quốc tế).
  - Tự thêm vào **Trình điều khiển đồ họa Prerelease** chính hãng Qualcomm (`/vendor/app/com.qualcomm.qti.gpudrivers.kalama.api33`).
  - Tự đồng bộ vào **`vaa_whitelist_apps`** & **`vsr_whitelist_apps`**.

#### B. APK LSPosed tích hợp sẵn (`GameCube Z9 Monster+` v1.1 — `12.7 KB`)
- Tự động cài đặt khi flash ZIP (`customize.sh` / `service.sh`) và **tự động gỡ sạch** khi gỡ module (`uninstall.sh`).
- Chỉ hook duy nhất tiến trình **`com.vivo.gamecube`** (không động vào game online, không động vào hệ thống nhiệt):
  - **Mở khóa nút & hiệu ứng `Monster+`** không cần gắn quạt Bluetooth iQOO chính hãng (`i9.a` / `ModeShiftBar` / `com.vivo.common.a`).
  - **Mở khóa `Chế độ Đấu giải (Esports Mode)`**, **Thông số thao tác giải đấu**, **Siêu âm thanh & Âm thanh tùy chỉnh** cho **mọi game trong Game Space** (`com.vivo.gameassistant.utils.z0`).

#### C. Những gì đã loại bỏ hoàn toàn
- Đã xóa sạch toàn bộ phần không chạy trên Z9 CN (không có chip Q2): `Q2 144FPS MEMC`, `1.5K SR phần cứng`, `Ray Tracing XPQ`, `Game Camera`, XML vá không tồn tại.
- Đã xóa bỏ hoàn toàn **`smartthermal_daemon.sh`** → **0% xung đột** khi dùng song song với [`thermal_killer_z9(CN)_v1.1`](https://github.com/Haicu256/thermal_killer_z9_cn).
- Không ghi đè hay mount vào phân vùng `/vendor` (an toàn cho máy khóa Bootloader + Temp Root Late-load).

---

### 3. Hướng dẫn cài đặt & sử dụng
1. Gỡ các module/APK Game Space cũ nếu có (tránh trùng hook vào `com.vivo.gamecube`).
2. Tải **`gamecube_z9(CN)_v1.2.zip`** trong mục [Releases](https://github.com/Haicu256/gamecube_z9_cn/releases/latest) và flash trong **KernelSU Manager** → **Soft Reboot**.
3. Mở **LSPosed Manager → Mô-đun → bật `GameCube Z9 Monster+`** (scope: **`com.vivo.gamecube`**) → buộc dừng `GameCube` (hoặc Soft Reboot thêm 1 lần).
4. **Tùy chỉnh & đồng bộ Game Space:** Mở **KernelSU Manager → `gamecube_z9(CN)_v1.2` → Mở (WebUI)** để bật/tắt từng tính năng, đồng bộ game mới hoặc bật/tắt khóa trần GPU/CPU đồng bộ trực tiếp với `thermal_killer_z9`.
5. **Gỡ bỏ:** Gỡ module trong KernelSU Manager → `uninstall.sh` tự gỡ APK `GameCube Z9 Monster+`, trả lại `perf_game_list`, `updatable_driver_prerelease_opt_in_apps`, `autovrs_support`, `WALT latency_sensitive` và xóa sạch các prop đã thêm.

---

## 🇬🇧 English

### 1. Verified Target Device
- **Device:** vivo iQOO Z9 CN (`V2361A` / `PD2361`) — Snapdragon 7 Gen 3 (`SM7550` / Adreno 720) — OriginOS 5 (Android 15 / API 35).
- **Root Environment:** KernelSU (including **Temp Root Late-load** + Locked Bootloader) & LSPosed.
- **Idle Overhead:** **0 background daemons (`0% CPU / 0% RAM`)** — safe to leave permanently enabled.

### 2. What's Included (100% Hardware-Verified on `V2361A`)
- **KernelSU System Layer (`system.prop` + `service.sh` + `action.sh`):**
  - Full **KPL Skin** (`393` assets mounted safely under `/system/etc/gamecube/res/skin/kpl`) + both `perist.vivo.gamecube.kpl.support=1` (matching vivo's literal prop spelling in `GameCube.apk`) and `persist.vivo.gamecube.kpl.support=1`.
  - **Bypass Charging** (`game_bypass_charge_support=1`, `all_bypass_charge_support=1`), **FPS Overlay** (`support_fps=1`), **Monster+** flags, **VivoSync / G2M**, and **Game Audio Spatializer**.
  - **Built-in KernelSU WebUI (`webroot/index.html`):** Toggle every feature live (persisted in `/data/adb/gamecube_z9.conf`) with one-tap Game Space sync, GameCube restart, reset to defaults, and **live hardware-scanned GPU/CPU Ceiling Lock** (automatically bridges to `thermal_killer_z9` via `tk_ctl.sh` when active, or operates directly on `/sys` standalone with 0 background daemons).
  - **Software VAA / VSR & AutoVRS:** All **OFF by default** for maximum GPU headroom and crisp native rendering; toggleable anytime from KernelSU WebUI.
  - **Game Touch Optimization** (`sys.game.touch.opt.enable=1`), **Adreno GPU Tuner** (`GPUTUNER_SWITCH=true`), and **WALT foreground latency priority** (`/dev/cpuctl/top-app/cpu.uclamp.latency_sensitive=1`).
  - **Dynamic Game Space Auto-Sync** via native `content://com.vivo.gamecube.provider/support_game` (zero `sqlite3` dependency): automatically syncs every game you add in Game Space into `perf_game_list` (fixing missing international/VN games on CN ROM), Qualcomm's stock `/vendor` Prerelease GPU Driver (`updatable_driver_prerelease_opt_in_apps`), `vaa_whitelist_apps`, and `vsr_whitelist_apps`.
- **Bundled Micro LSPosed APK (`GameCube Z9 Monster+` v1.1 — `12.7 KB`):**
  - Auto-installed by `customize.sh` / `service.sh` and cleanly auto-removed by `uninstall.sh`.
  - Scoped **strictly to `com.vivo.gamecube`** (never hooks game processes): unlocks **Monster+** without an official Bluetooth iQOO Back Clip, plus **Esports / Competition Mode (`COMPETITION_MODE`)**, tournament touch parameters, and **Super Audio / Custom Sound** for all Game Space games.
- **Zero Bloat & Zero Thermal Conflict:**
  - All non-existent Q2 display-chip features (MEMC, hardware 1.5K SR, XPQ Ray Tracing, Game Camera) and conflicting `smartthermal_daemon.sh` have been completely removed. Designed to pair seamlessly with [`thermal_killer_z9_cn`](https://github.com/Haicu256/thermal_killer_z9_cn).

### 3. Build from Source
```bash
bash build.sh
```
*(Signing keystore `lsp_src/release.jks` is excluded via `.gitignore`; `apk/GameCubeZ9MonsterPlus.apk` is prebuilt from `lsp_src/`.)*
