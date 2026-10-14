# Sandık: Harçlıklarım

Çocuklar (7–15) için birikim ve para bilinci uygulaması. Birikim dört sevimli
karakterde yaşar (**Kumbara Takımı**: Tortu · altın, Zıpzıp · dolar, Baykuş · euro,
Sincap · nakit); toplam kamp ateşidir, kâr/zarar yüz ifadesidir. Analiz yok,
grafik yok, reklam yok, e-posta yok.

Sandık (portföy takibi) ailesinin ikinci uygulaması; aynı TestFlight hattını
(fastlane + match) kullanır, **ayrı repo, ayrı bundle id, ayrı Supabase**.

## Çalıştırma

```bash
flutter pub get
flutter gen-l10n          # lib/l10n/generated commit'lidir; değişince yeniden üret
flutter analyze && flutter test
flutter run
```

## Yapı

```
lib/theme/dunya.dart        6 dünya (tema) token seti, Devinim (hareket), Bosluk/Kose
lib/models/                 VarlikTuru (karakter = varlık), ParaBirimi, Hareket, Cocuk, Ders, Cikartma
lib/services/               fiyat_servisi (truncgil v4, önbellek), depo (shared_preferences, PIN özeti)
lib/providers/              Riverpod: cocuk, fiyat, hareketler, karakterler, toplam, çıkartmalar, ders
lib/widgets/karakter.dart   Kumbara Takımı CustomPainter (çini/kilim/hasır deseni, ruh hâli, göz kırpma, zıplama)
lib/widgets/kamp_atesi.dart Toplamla büyüyen alev
lib/screens/                karşılama, kamp, besle (alt sayfa), varlık detayı, öğren, çıkartmalar, ayarlar (+ veli PIN)
lib/l10n/                   app_tr.arb (şablon) + app_en.arb → generated/
assets/dersler.json         10 ders (iki yaş modu metni, soru, 3 seçenek)
ios/fastlane/               beta (TestFlight), setup_match_certificates
.github/workflows/          ci.yml, ios-testflight.yml (main), setup-match.yml (tek seferlik)
docs/APP_CREATOR_PIPELINE.md  Yeni uygulama üretim hattı (6 kapı)
```

## Kurallar (sandık'tan devralındı)

- Renk/boşluk/köşe/hareket yalnız `context.r`, `Bosluk`, `Kose`, `Devinim`'den. Ham `Color(0x…)` ekranda yok (karakter çizimleri hariç: sanat yönü sabittir, tema değişse de karakter aynı kalır).
- Para `fmtPara`, fark `fmtFark`, girdi `parseSayi`. `toStringAsFixed` yok.
- **Uydurma sayı yasak**: fiyat yoksa değer gösterilmez, sabit kur yazılmaz.
- Konfeti yok; kutlama karakterin kendi ışığı/zıplaması.
- Çıkartma davranışa verilir (ilk besleme, düzenlilik, eşik), piyasa şansına değil.
- Hareketi azalt açıksa salınım/kırpma durur, süreler sıfırlanır.
- Yeni metin iki .arb'a girer, ham literal yok. Türkçe `toUpperCase` yapılmaz (İ/I).
- İş dalda ve PR'da; `main`'e birleşme TestFlight'ı tetikler.
