#!/usr/bin/env bash
# Baloo 2 başlık fontunu Latin alt kümesine indirir (Ar-Ge raporu 2026-10-23 11:07 #2).
#
# Neden: dosyaların ~%85'i Devanagari (Hint yazısı) glifleriydi; uygulamanın
# 6 dilinde hiç kullanılmıyor. Her dosya 422 KB → ~72 KB. Kalan aralıklar:
# Latin + Latin Genişletilmiş A/B (tr, de, es, fr, pt), genel noktalama
# (… – — • ’ “), para simgeleri (₺ € £). Çocuğun adına başka alfabeden harf
# girilirse Flutter sistem fontuna düşer; kırılmaz.
#
# Kilit: test/font_kapsama_test.dart — .arb ve ders metinlerindeki her
# karakter fontta olmalı. Yeni dil (ör. Rusça) eklenirse aralığı genişlet ve
# özgün fontları https://github.com/EkType/Baloo2 'den yeniden indir (alt
# küme yeniden genişletilemez). Lisans OFL 1.1: alt küme serbest, Baloo 2'de
# Reserved Font Name yok. Nunito zaten küçük, dokunulmaz.
#
# Kullanım: pip install fonttools && bash tool/font/altkume.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
ARALIK="U+0000-024F,U+2000-206F,U+20A0-20CF"
for w in 600 700 800; do
  f="assets/fonts/Baloo2-$w.ttf"
  pyftsubset "$f" --unicodes="$ARALIK" --layout-features='*' --name-IDs='*' \
    --name-languages='*' --notdef-outline --output-file="$f.tmp"
  mv "$f.tmp" "$f"
done
ls -la assets/fonts/Baloo2-*.ttf
