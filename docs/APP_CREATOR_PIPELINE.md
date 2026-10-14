# App Creator Pipeline — yeni uygulama üretim hattı

yasin'in isteği (2026-10-14): "yeni bir app creator pipeline'ı üret, initial
üretimi bu şekilde sağlayacaksın." İlk uygulama: Sandık: Harçlıklarım. Hat
altı kapıdan geçer; her kapının çıktısı bir artifact/dosyadır ve yasin'in
onayı olmadan sonraki kapıya geçilmez.

| Kapı | Çıktı | Harçlıklarım'da |
|---|---|---|
| 0 Fikir kartı | 1 sayfa: kim, hangi acı, neden biz, ücretsiz bütçe sınırı | thread ilk mesajı |
| 1 Konsept | Tez, tema/hedef kitle, 4–5 mockup, HIG kontrolü, mimari, bütçe tablosu, açık sorular | konsept_v1.html |
| 2 Tasarım yönleri | 3 yön, canvas üzerinde ana + detay ekranı, öneri | tasarim-yonleri-canvas |
| 3 Prototip | Tıklanabilir HTML, tema/yaş sistemi, karakter/metafor kararı | prototip_v1.html |
| 4 MVP | Flutter projesi, l10n, tema tokenları, testler, TF hattı | bu repo |
| 5 Aile testi | TestFlight dahili grup, 5 aile, 2 hafta; geri bildirim listesi | — |
| 6 Mağaza | Kids kategorisi, gizlilik, ekran görüntüleri, sürüm notu | — |

## Sabitler (her yeni uygulama için)

- **Ayrı repo, ayrı bundle id, ayrı Supabase projesi**; sandık'ın yayın hattına
  (main → TF/Play) girmez. Secrets sandık'takilerle aynı değerler (Apple hesabı tek).
- **Match deposu ortak**, bundle id başına profil (`setup-match.yml` tek seferlik).
- Flutter 3.47.2 sabit, Riverpod, `shared_preferences`; tema token seti
  (`ThemeExtension`), hareket sabitleri, biçim tek dosya — sandık kurallarının
  kopyası değil, aynı kararların yeni koda uyarlanması.
- l10n baştan (tr şablon + en); para birimi ve yerel bağımsız sayı girişi baştan
  (global uygulama kararı 2026-10-14).
- Yerel-önce: ilk TF build'i sunucusuz çalışır; hesap/yedek bayrakla gelir.
- Konfeti yok, karanlık desen yok, çocuk ürünlerinde bildirim/reklam/satın alma yok.

## Yeni uygulama başlatma (kapı 4 kalıbı)

```bash
flutter create --org com.sandik --project-name <ad> --platforms ios,android --empty <ad>
# kopyala: lib/theme/dunya.dart (token iskeleti), lib/utils/bicim.dart, lib/widgets/ortak.dart,
#          l10n.yaml + lib/l10n/l10n.dart, ios/fastlane/*, .github/workflows/*, CLAUDE.md kalıbı
# değiştir: BUNDLE_ID (Fastfile, Matchfile), CFBundleDisplayName, android:label
```
