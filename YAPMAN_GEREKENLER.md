# YAPMAN GEREKENLER — Harçlıklarım

Yalnız yasin'in yapabileceği adımlar. Sıra önemlidir.

## TestFlight'a ilk build için (hepsi gerekli)

1. **GitHub deposu**: `yasincirali/harcliklarim` (private) oluştur; Claude Projects ›
   Project settings › Resources'a ekle. Bu klasörün ilk commit'i hazır; depo
   açılınca push edilir (push saatleri dışında).
2. **Apple Developer › Identifiers**: `com.sandik.harcliklarim` App ID (capability yok).
3. **App Store Connect › Apps › +**: ad "Sandık: Harçlıklarım", bundle id yukarıdaki,
   SKU `harcliklarim`, birincil dil Türkçe. Kategori **Kids › 9–11** (ikincil Education).
   TestFlight › Test Information'ı doldur (harici grup için gerekir).
4. **GitHub secrets** (yeni depoya, sandık'takilerle AYNI değerler): `APPLE_ID`,
   `APPLE_TEAM_ID`, `ITC_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`,
   `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTH`, `MATCH_PASSWORD`.
5. **Actions › "iOS — Setup Match (one-time)"** çalıştır: yeni bundle id'nin profilini
   sandık'ın match deposuna yazar (sertifika ortak, yalnız profil eklenir).
6. `main`'e ilk birleşme → "iOS — TestFlight" build'i yükler. TestFlight'ta dahili
   gruba kendini ekle.

## Android (Play kapalı test)

İş akışı hazır (`android-release.yml`): secret'lar girilene kadar main'de
atlanır ve yeşil biter. Sıra:

1. **Play Console › Uygulama oluştur**: ad "Harçlıklarım" (TR) / "Pocket Money"
   (EN), uygulama, ücretsiz. Paket adı ilk yüklemede `com.sandik.harcliklarim`
   olarak sabitlenir.
2. **Mağaza girişi ve formlar**: her şey hazır, kopyala-yapıştır:
   `/mnt/project-files/harcliklarim/magaza-metinleri/google-play-6-dil.md` (ad, 80 karakterlik kısa
   açıklama, 6 dil; hedef kitle 5–8 + 9–12 → Aileler politikası; veri güvenliği "veri toplanmıyor";
   reklam yok; içerik derecelendirmesi). Görseller `magaza-goruntuleri/play/` (özellik görseli
   1024×500 + dil başına 4 ekran, 2:1). Gizlilik politikası URL'si App Store'dakiyle aynı.
3. **Yükleme anahtarı** (bir kez, kendi bilgisayarında; değeri kimseyle paylaşma):
   `keytool -genkeypair -v -keystore harcliklarim-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
   Dosyayı ve şifreleri parola yöneticine koy. Play App Signing açık kalsın
   (anahtar kaybolursa Play'den sıfırlanabilir).
4. **GitHub secrets** (bu depoya): `ANDROID_KEYSTORE_BASE64` (`base64 -w0 harcliklarim-upload.jks`),
   `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`.
5. **İlk AAB elle**: Actions › "Android — Play kapalı test" › Run workflow →
   artefakttan `app-release.aab`'yi indir → Play Console › Test › Kapalı test
   (alpha) › yeni sürüm › yükle. Play API yeni uygulamanın ilk yüklemesini
   kabul etmiyor.
6. **Otomatik yükleme**: sandık'taki servis hesabına bu uygulamada da yetki ver
   (Play Console › Kullanıcılar ve izinler › uygulama: "Sürümleri test
   kanallarına yayınla"), JSON'u bu depoya `PLAY_SERVICE_ACCOUNT_JSON` olarak
   ekle. Sonra her main birleşmesi kapalı teste gider; yönetilen yayınlamada
   "Yayınla"ya sen basarsın.
7. Kapalı test listesine testçileri ekle (sandık'taki Google grubu olabilir).

## Sonra (2. kapı öncesi karar)

- Supabase: **ayrı ücretsiz proje** (öneri; sandık Tokyo 351/500 MB). Yalnız anonim
  hesap + yedek için; v1 TF build'i sunucusuz çalışır.
- Uygulama ikonu: Tortu'nun kabuğu (çini) + ateş; illüstratör teslimatıyla.
- Yasal: Kids için gizlilik metni (veri cihazda, üçüncü taraf yok) — `legal/`
  düzeni sandık'taki gibi kurulacak, metin yazılacak.
