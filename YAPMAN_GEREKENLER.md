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

## Sonra (2. kapı öncesi karar)

- Supabase: **ayrı ücretsiz proje** (öneri; sandık Tokyo 351/500 MB). Yalnız anonim
  hesap + yedek için; v1 TF build'i sunucusuz çalışır.
- Uygulama ikonu: Tortu'nun kabuğu (çini) + ateş; illüstratör teslimatıyla.
- Yasal: Kids için gizlilik metni (veri cihazda, üçüncü taraf yok) — `legal/`
  düzeni sandık'taki gibi kurulacak, metin yazılacak.
