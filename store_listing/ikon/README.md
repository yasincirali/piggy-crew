# Uygulama ikonu: Şeker Kavanozu

yasin 2026-10-15'te beş turluk seçimden sonra **Şeker Kavanozu**'nu seçti
(seçenekler ve gerekçeler: proje artifact'i "Harçlıklarım Logo").

Neden bu biçim:
- Yüz yok (yasin: "yüz olmak zorunda mı"); sevimlilik yuvarlak silüetten,
  pembe topuzdan ve çikolata para gibi altınlardan gelir.
- Kavanoz "kumbara" olarak ilk bakışta okunur; kapaktaki yarık + düşen para
  biriktirmeyi anlatır. Domuz figürü bilerek yok (global pazar).
- Mürekkep kontur (#2A1B14) Kumbara Takımı karakterleriyle aynı çizgi dili.
- Lila zemin finans uygulamaları arasında yok, App Store ızgarasında ayrışır.

Dosyalar (tek kaynak SVG, PNG'ler bunlardan üretilir):
- `ikon.svg` → iOS AppIcon (tümü) + Android eski ikon + `ikon_1024.png`, `play_512.png`
- `on_plan.svg` / `arka_plan.svg` / `tek_renk.svg` → Android adaptive ikon katmanları
  (ön plan güvenli bölge %66 içinde; tek renk Android 13 temalı ikon)

Yeniden üretmek: `node render.js` (Playwright) ile 1024 PNG'ler, sonra ImageMagick
`convert -resize` ile boyutlar. iOS ikonunda saydamlık olmamalı (`-alpha off`).
