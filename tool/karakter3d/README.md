# 3D karakterler (deneme)

Kumbara Takımı'nın 3D hâli Blender'da modellenir ve **önceden render** edilir;
uygulama kareleri animasyonlu WebP olarak `assets/karakter3d/<tur>/` altında.

- `kumbara.py`: dört karakterin modeli, iskeleti ve sahneleri. Hareket
  `lib/widgets/karakter.dart` ile aynı zaman çizelgesini izler.
- `uret.sh`: kareleri üretir (ifade atlası 13 × 4 evre; pişmiş sahneler
  dokunma, arti, ziplama, keyif, etrafa_bak, dans: gövde + evre bitkisi;
  büyüme `evre`: gövde + geçişin hedef evresi adıyla bitki, ör. `evre_cicek` = filiz>cicek).
- `donustur.py`: PNG → kırpılmış WebP, `lib/widgets/karakter_3d_yerlesim.g.dart`
  (2D kutuya kalibrasyon + kırpım tablosu). Kısmi çalışır: `KARE`'de karesi
  olmayan atlas/sahnenin eski WebP'si ve tablo satırı korunur.

Kostüm (2026-10-31): çıkartmayla açılan şapka/atkı/gözlük/fular ayrı
`kostum` katmanıdır (`--katman kostum`: gövde holdout, bitki ve paralar
gizli; diğer katmanlarda kostüm hiç render edilmez, var olan kareler
değişmez). Atlas 13 ifadenin baş pozlarıyla tek set (`atlas_kostum`),
her sahnede `<sahne>_kostum`; evreden bağımsız. Uygulama gövdeyle aynı
kareyi, bitkinin altında çizer. 2D karşılığı `KarakterPainter._sapka/_atki/
_gozluk/_fular`.

Kalibrasyon: 3D "minik/mutlu" gövdesinin sınırları 2D gövdesinin (evresiz
KarakterPainter) yüksekliğine, ayak tabanına ve ortasına oturtulur. 2D
çizim değişirse `donustur.py`'deki `IKI_D` yeniden ölçülmeli.

## Açılış sahnesi (hazine sandığı)

- `sandik.py` (2026-10-19): sandığın modeli (tarz B) ve kapak açıklığı
  süpürmesi 0 → 1,1 (36 adım), iki katman: `arka` (iç, kapak, paralar) ve
  `on` (ön duvar; diğerleri holdout). `python sandik.py <klasor> --adim 36
  --boyut 720 --ornek 16` (bulutta ≈ 6 dk).
- Dönüştürme: her katmanın 36 karesi tüm karelerin ortak kırpım kutusuyla
  kesilip `assets/karakter3d/acilis/sandik_{arka,on}.webp` (animasyonlu)
  olur; kutular `lib/widgets/acilis_sahnesi.dart` → `_sandikArka/_sandikOn`.
