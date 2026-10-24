# BAŞLANGIÇ — Claude Code paketini kullanma (Türkçe)

Bu paket, `Godot-VR-Template` projesini Claude Code'un **tek başına, soru sormadan**
inceleyip düzeltmesi ve kapsamlı bir VR şablonuna dönüştürmesi için hazırlandı.
Paketteki dosyaların hiçbiri mevcut proje dosyalarının üzerine yazmaz; hepsi yeni dosya.

## 1. Kurulum (2 dakika)

1. Zip'i aç, içindekileri **`D:\Work\Code\Godot_VR_Template`** klasörüne at
   (`CLAUDE.md`, `.claude\`, `docs\claude\`, `tools\`, `.editorconfig`, bu dosya).
2. Bir terminal aç (Git Bash veya PowerShell) ve proje klasörüne gir:
   ```
   cd D:\Work\Code\Godot_VR_Template
   ```
3. Claude Code'u başlat:
   ```
   claude
   ```
   - Yeni sürümlerde (v2.1.283+) oturum zaten **Auto** modda açılır ve hiçbir şey sormaz.
   - Eski sürümde ya da yine de soru sorarsa: `Shift+Tab` ile **auto mode**'a geç,
     veya şöyle başlat: `claude --dangerously-skip-permissions`
   - `.claude/settings.json` zaten Bash / dosya düzenleme / web izinlerini açık
     tanımlıyor; `git push --force`, `git reset --hard`, `git rebase` gibi tehlikeli
     komutlar **yasaklı**.
4. Şunu yaz ve bekle:
   ```
   planları uygula
   ```
   (`/apply-plan` de aynı işi yapar.)

Claude Code `docs/claude/PLAN.md`'deki 9 fazı sırayla uygular, her fazdan sonra
`tools/check.sh` ile doğrular, commit atar, push'lar ve en sonda **`BİTTİ`** ile
başlayan Türkçe bir rapor yazar.

## 2. GitHub şifre sorunu

Claude Code ilk fazda `tools/git_setup.sh`'yi çalıştırır. Bu script Git Credential
Manager'ı ayarlar: **ilk push'ta bir kez** ekranda GitHub giriş penceresi
(tarayıcı) açılır, bir kez giriş yaparsın, token Windows Credential Manager'a
kaydedilir ve bir daha **hiç sormaz**.

İstersen bunu Claude'u başlatmadan önce sen de halledebilirsin (tek seferlik):

```
gh auth login            # GitHub CLI kuruluysa
```
veya
```
git config --global credential.helper manager
git push                 # bir kez giriş yap
```

Push başarısız olursa Claude çalışmaya devam eder, en sonda tekrar dener ve
raporda belirtir; kodun tamamı yerel branch'te güvende olur.

## 3. Çalışırken

- Bütün iş **`claude/template-overhaul`** branch'inde olur; `main`'e dokunulmaz.
- Durumu görmek için: `/status`
- Sadece doğrulamayı çalıştırmak için: `/verify` (veya `/verify --export`)
- Ara dosyalar: `docs/claude/PROGRESS.md` (ne yapıldı), `docs/claude/DECISIONS.md`
  (sana sormak yerine aldığı kararlar), loglar `build/claude-logs/`.
- Oturum yarıda kesilirse (bağlam dolarsa, bilgisayar kapanırsa): yeni oturumda
  tekrar `planları uygula` yaz — `PROGRESS.md`'den kaldığı yerden devam eder.

## 4. Bittiğinde

1. Raporu oku. "Needs headset test" listesindeki şeyleri Quest 3'te dene
   (Claude Code gözlükte test yapamaz; el takibi, passthrough, teleport görselleri
   gibi şeyler bu listede olacak).
2. Farkı incele: `https://github.com/eedali/Godot-VR-Template/compare/main...claude/template-overhaul`
   (gh kuruluysa Claude PR de açmış olabilir, link raporda).
3. Beğendiysen `main`'e merge et; beğenmediğin bir kısım varsa aynı oturumda
   Claude'a söylemen yeter, branch üstünde düzeltir.

## 5. Sorun giderme

| Belirti | Çözüm |
|---|---|
| `Godot binary not found` | Konsol exe'si `C:\Open\Godot_v4.6-stable_win64_console.exe` değilse `.claude/settings.json` içindeki `GODOT_BIN` yolunu düzelt. |
| Claude her komutta izin soruyor | `Shift+Tab` → auto, ya da `claude --dangerously-skip-permissions` ile başlat. |
| `bash: command not found` | Git for Windows kurulu olmalı (Claude Code Windows'ta Git Bash kullanır). |
| Push'ta tarayıcı açıldı | Normal; bir kez GitHub'a giriş yap. |
| Android/Quest export çalışmıyor | `bash tools/setup_vendors.sh` ile OpenXR Vendors eklentisini kurar; Android build template için editörden *Project → Install Android Build Template*. |
| gdlint yok uyarısı | İsteğe bağlı. Python varsa `pip install "gdtoolkit==4.*"`. |

## 6. Paketin içindekiler

```
CLAUDE.md                      Claude Code'un proje kuralları (otonom, sessiz, branch, doğrulama)
BASLANGIC.md                   bu dosya
.editorconfig                  tab/LF kuralları
.claude/settings.json          izinler (prompt yok), Godot yolu, git ayarları
.claude/commands/apply-plan.md /apply-plan komutu
.claude/commands/verify.md     /verify komutu
.claude/commands/status.md     /status komutu
.claude/agents/godot-reviewer.md  kod inceleme alt-ajanı (sadece okur)
docs/claude/PLAN.md            9 fazlık uygulama planı (kutucuklu)
docs/claude/AUDIT.md           şu anki kodda bulunan hatalar/eksikler
docs/claude/FEATURES.md        hedef özellik matrisi (~45 anahtar)
docs/claude/ARCHITECTURE.md    VRFeatureConfig + PlayerRig tasarımı
docs/claude/VERIFICATION.md    gözlüksüz doğrulama yöntemi
docs/claude/GODOT_NOTES.md     Godot 4.6 / XR Tools tuzakları
docs/claude/PROGRESS.md        ilerleme günlüğü (Claude doldurur)
docs/claude/DECISIONS.md       karar günlüğü (Claude doldurur)
tools/godot.sh                 doğru Godot exe'sini bulur
tools/check.sh                 import + script kontrolü + smoke test + lint + export
tools/smoke_test.gd            bütün sahne/kaynakları yükleyen headless test
tools/setup_vendors.sh         OpenXR Vendors eklentisini indirir
tools/git_setup.sh             branch + credential helper kurulumu
```
