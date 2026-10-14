# Claude Development Guidelines — Harçlıklarım

Sandık ailesinin çocuk uygulaması. Çalışma biçimi, onay eşikleri ve genel kurallar
sandık `CLAUDE.md` ile aynıdır; burada yalnız farklar ve bu repoya özgü kararlar.

- **Ürün tezi:** dopamin karakterden gelir, sayıdan değil. Grafik, yüzde listesi,
  teknik/temel analiz EKLENMEZ. Ekranda en fazla iki sayı: toplam ve fark.
- **Kumbara Takımı sabittir:** 4 karakter, tema değişse de aynı kalır (çocuğun bağ
  kurduğu şey). Yeni varlık = yeni karakter; önce tasarım, sonra kod.
- **Global:** metin iki .arb'a; para `ParaBirimi` üzerinden; TR'ye özgü varsayım
  (₺ konumu, "gram altın" = 24 ayar) yalnız `bicim.dart`/`varlik.dart`'ta.
- **Yerel-önce:** v1'de sunucu yok. Anonim hesap/yedek 2. kapıda, bayrakla.
- **Kids kategorisi:** reklam, takip, üçüncü taraf analytics, bildirim yok. Veri
  cihazda. Veli köşesi PIN ardında.
- **Fiyat kaynağı** sandık ile aynı (truncgil v4). Kaynak değişirse yalnız
  `fiyat_servisi.dart`; "uydurma sayı yasak" kuralı korunur.
- TestFlight: `main`'e birleşme → `ios-testflight.yml`. Push saatleri kuralı
  (hafta içi 09:00–18:30 TR push/PR/merge yok) bu repoda da geçerli.
- Doğrulama: `flutter gen-l10n && flutter analyze && flutter test`.

## Skill ve MCP (sandık ile aynı set, yasin 2026-10-14)

`.claude/skills/` sandikapp'ten kopyadır (yönlendirme tablosu sandık `CLAUDE.md`'de;
Supabase/SQL satırları bu uygulamada v1'de kullanılmaz). `.mcp.json` yerel Windows
yollarını taşır; bulutta `bash tool/bulut_kurulum.sh || true` (Project settings ›
Cloud environment › Setup script) üç sunucuyu Linux yollarıyla kurar; Perplexity
yalnız ortamda `PERPLEXITY_API_KEY` varsa. Repoya hiçbir secret yazılmaz.
