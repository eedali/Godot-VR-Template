# VRStudio XR Game — Godot VR Template (Quest 3 + Steam hazır)

> Upstream: [godotVR/godot-xr-template](https://github.com/godotVR/godot-xr-template) (`main` kolu)
> baz alınarak, **Meta Quest 3 öncelikli** ve **Steam PCVR** hedefli hazırlanmış çalışan
> şablondur. Splash + start menüsü + 3 demo sahnesi ile gelir, tak-çalıştır test edilebilir.

| Hedef | Durum |
|---|---|
| Quest 3 (APK, debug) | ✅ Derleniyor, cihaz testi seni bekliyor |
| PC Windows (SteamVR uyumlu OpenXR) | ✅ Derleniyor |
| Meta Store yayını (AAB, release imza) | ⬜ TODO (aşağıda) |
| Steam yayını | ⬜ TODO (aşağıda) |

Test edilen sürümler: **Godot 4.6 stable**, **XR Tools 4.5.1**,
**OpenXR Vendors 4.3.0-stable**, **JDK 17**, **Android SDK 34 / min 32**.

---

## 1. Gereksinimler

- **Godot 4.6 stable** (editör). `Editor → Manage Export Templates` ile 4.6 export
  şablonlarının kurulu olması gerekir.
- **OpenXR Vendors 4.3.0-stable** — repoda YOKTUR (bilerek `.gitignore`'da).
  CI ve aşağıdaki kurulum adımı indirir. Sürüm: `.github/workflows/publish-demo-on-push.yaml`
  içindeki `OPENXR_VENDORS_VERSION` ile aynı olmalı.
- Android export için: **JDK 17** + **Android SDK** (platform 34, build-tools 34,
  NDK, cmake) + `ANDROID_HOME` tanımlı olmalı.
- Quest 3 cihaz testi için: `adb` (SDK platform-tools) + Quest'te geliştirici modu.

## 2. Kurulum

```powershell
git clone https://github.com/eedali/Godot-VR-Template.git
```

1. Vendors eklentisini kur (repo kökünde çalıştır):
   ```powershell
   # 4.3.0-stable zip'ini indir:
   # https://github.com/GodotVR/godot_openxr_vendors/releases/download/4.3.0-stable/godotopenxrvendorsaddon.zip
   # içindeki asset/addons/godotopenxrvendors klasörünü addons/ altına kopyala
   ```
2. Projeyi Godot 4.6 ile aç → otomatik import başlar.
3. Android build template'i kur (bir kez):
   `Project → Install Android Build Template...`
   (veya headless: `godot --headless --path . --install-android-build-template --quit`)
4. `Project → Export` penceresinde **Android Quest** ve **Windows** presetlerini gör.

## 3. Hızlı test

### PC'de (headsetsiz)

Template'de `godot-xr-tools` **desktop-support** vardır; HMD yoksa oyun normal
modda açılır (WASD + fare). OpenXR hatası
(`Failed to create XR instance`) bu durumda **normaldir**.

```powershell
# Windows debug derleme
godot --headless --path . --export-debug "Windows"
# çıktı: build/windows/Game.exe
```

### Quest 3'te

```powershell
adb devices
adb install -r build/android-quest/Game.apk
```

Başlıkta **VRStudio XR Game**'i aç: splash → start menüsü → 3 zone
(`house_interior`, `house_back_yard`, `outside`). Teleport, crate/rock grab,
el takibi ve passthrough'u dene.

Log: `adb logcat | Select-String "godot|openxr|vrstudio"`

## 4. Proje ayarları (neden böyle?)

- `project.godot` → `rendering_method = gl_compatibility` (hem desktop hem mobile).
  **Quest'te zorunlu.** Steam için görsellik istersen sonra desktop tarafını
  `Forward+` yapabilirsin, ama Quest (`*.mobile`) `gl_compatibility` kalmalı.
- `xr/openxr`: `enabled=true`, foveation level 3 + dynamic (Quest performansı),
  Meta color space başlangıcı.
- `export_presets.cfg` → **Android Quest**: `com.vrstudio.xrgame`, v1.0.0,
  `minSdk 32 / targetSdk 34`, `arm64-v8a` tek mimari, Meta plugini açık,
  Quest 2/3/Pro desteği açık, Quest 1 kapalı, hand tracking + passthrough açık,
  eye tracking kapalı (Quest 3'te göz takibi yok).
- **Windows**: `VRStudio / VRStudio XR Game 1.0.0`, SteamVR OpenXR runtime ile
  çalışır, ek plugin gerekmez.
- Not: upstream'deki `build/android-hronos` yazım hatası `build/android-khronos`
  olarak düzeltildi (CI artifact klasörüyle tutarlılık için).

## 5. Klasör yapısı

```
game/            # main.tscn, game_state (singleton), start_scene, zones, items
components/      # persistent staging/world/zone sistemi
addons/godot-xr-tools/   # XR Tools 4.5.1 (repoda)
addons/godotopenxrvendors/ # CI/kurulumda iner, repoda YOK
export_presets.cfg  # Windows, Linux, Android Quest/Pico/Lynx/Khronos, WebXR
openxr_action_map.tres
build/           # export çıktıları (git'e girmez, .gitignore)
android/         # build template (git'e girmez, .gitignore)
```

## 6. TODO — yapılması gerekenler

### Oyun kimliği (şart)
- [ ] `icon.png` → kendi oyun ikonunla değiştir (şu an Godot ikonu)
- [ ] `assets/splash/splash.png` → kendi splash'in
- [ ] `project.godot` → `config/name` gerçek oyun adı
- [ ] `export_presets.cfg` → `package/unique_name` gerçek yayıncı paketin
  (şu an placeholder `com.vrstudio.xrgame`) ve `package/name`
- [ ] Demo zone'ları kendi sahnelerinle değiştir (`game/zones/`), başlangıç
  zone'u `game_state.tscn` üzerinde seç

### Meta Store yayını
- [ ] Release keystore üret (debug keystore ile store'a çıkılmaz) ve güvenli sakla
- [ ] Release derleme: `gradle_build/export_format` → AAB, `--export-release`
- [ ] Meta Quest Developer hesabı + uygulama kaydı, VRC testlerinden geç
- [ ] İkon, kapak, yaş/privacy beyanları, `targetSdk` güncelliğini koru

### Steam yayını
- [ ] Steamworks hesabı + app kaydı; Godot Steam plugin'i gerekiyorsa ekle
  (şu an template'de yok — sadece OpenXR PCVR hazır)
- [ ] Windows **release** export al, SteamVR kurulu PC'de test et
- [ ] İstersen PC tarafı için `Forward+` + yüksek kalite materyal/ışık geçişi yap
  (ayrı branch önerilir, Quest `gl_compatibility` kalır)

### Kalite / performans
- [ ] Quest 3'te 72/90/120 Hz + el takibi + passthrough açıkken kare hızı ölç
- [ ] Doku sıkıştırma: mobil için ETC2/ASTC (`textures/vram_compression` açık),
  gereksiz 4K dokuları küçült
- [ ] Işık/gölge sayısını mobil bütçeye indir, `gl_compatibility` limitlerine dikkat

## 7. Bilinen durumlar

- Headless Android export sonrası Godot işlemi bazen hemen kapanmaz (gradle
  daemon) — APK oluşmuşsa (`build/android-quest/Game.apk` ~97 MB) sorun yok,
  işlemi kapatabilirsin.
- PC'de HMD'siz çalıştırmada OpenXR uyarısı normaldir (desktop fallback).
- `main` kolu upstream'i takip eder; çektiğin commit: `654622d`
  (Godot 4.6.1 / XR Tools 4.5.1 yükseltmesi). Upstream `upstream` remote'unda
  durur, kendi çalışman `origin` (`eedali/Godot-VR-Template`) üzerindendir.

## 8. Kredi / lisans

- Şablon: [Godot XR Template](https://github.com/GodotVR/godot-xr-template) — MIT
  (`LICENSE` dosyasına bak). XR Tools ve OpenXR Vendors kendi lisanslarına sahiptir.
- Bu repo: upstream MIT lisansını korur. Kendi oyununun kod/sanat içeriği için
  lisansını netleştirmeden store'a çıkma.
