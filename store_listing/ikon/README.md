# Uygulama ikonu: Şeker Kavanozu

yasin 2026-10-15'te beş turluk seçimden sonra **Şeker Kavanozu**'nu seçti
(seçenekler ve gerekçeler: proje artifact'i "Harçlıklarım Logo").

Logo revizyonu (yasin 2026-10-15, "başarılı bir logo dizaynı olsun"):
illüstrasyon dili bırakıldı, işaret logo diline indirildi. Kontur, yıldız ve
zemin gölgesi yok; düz renk, dört şekil: kavanoz, kapak, yarığa giren para,
içte üç para. Yarığa yarısı girmiş para "kumbara"yı tek başına anlatır;
içteki paraların halkası onları şekerden ayırır. Topuz kaldırıldı (iksir
şişesi gibi okunuyordu). 29 px'te kavanoz + altın + pembe kapak kalır.

Neden bu biçim:
- Yüz yok (yasin: "yüz olmak zorunda mı"); sevimlilik yuvarlak silüetten,
  pembe kapaktan ve parlak altınlardan gelir.
- Kavanoz "kumbara" olarak ilk bakışta okunur; kapaktaki yarık + düşen para
  biriktirmeyi anlatır. Domuz figürü bilerek yok (global pazar).
- Lila zemin finans uygulamaları arasında yok, App Store ızgarasında ayrışır.

Dosyalar (tek kaynak SVG, PNG'ler bunlardan üretilir):
- `ikon.svg` → iOS AppIcon (tümü) + Android eski ikon + `ikon_1024.png`, `play_512.png`
- `on_plan.svg` / `arka_plan.svg` / `tek_renk.svg` → Android adaptive ikon katmanları
  (ön plan güvenli bölge %66 içinde; tek renk Android 13 temalı ikon)

Yeniden üretmek: `node render.js` (Playwright) ile 1024 PNG'ler, sonra ImageMagick
`convert -resize` ile boyutlar. iOS ikonunda saydamlık olmamalı (`-alpha off`).
