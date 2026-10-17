# 3D karakterler (deneme)

Kumbara Takımı'nın 3D hâli Blender'da modellenir ve **önceden render** edilir;
uygulama kareleri animasyonlu WebP olarak `assets/karakter3d/<tur>/` altında.

- `kumbara.py`: dört karakterin modeli, iskeleti ve sahneleri. Hareket
  `lib/widgets/karakter.dart` ile aynı zaman çizelgesini izler.
- `uret.sh`: kareleri üretir (ifade atlası 13 × 4 evre; pişmiş sahneler
  dokunma, arti, ziplama, keyif, etrafa_bak, dans: gövde + evre bitkisi).
- `donustur.py`: PNG → kırpılmış WebP, `lib/widgets/karakter_3d_yerlesim.g.dart`
  (2D kutuya kalibrasyon + kırpım tablosu).

Kalibrasyon: 3D "minik/mutlu" gövdesinin sınırları 2D gövdesinin (evresiz
KarakterPainter) yüksekliğine, ayak tabanına ve ortasına oturtulur. 2D
çizim değişirse `donustur.py`'deki `IKI_D` yeniden ölçülmeli.
