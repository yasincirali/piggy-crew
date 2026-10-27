"""Uygulama karelerini (PNG) kırpılmış animasyonlu WebP'ye çevirir ve Dart
yerleşim tablosunu üretir. Kullanım: python3 donustur.py <repo>"""
import glob, os, sys
from PIL import Image

B = os.environ.get("KARE", os.path.dirname(os.path.abspath(__file__)))
REPO = sys.argv[1]
OUT = f'{REPO}/assets/karakter3d'
KIRP_X = 60  # 480 genişliğin ortadaki 360'ı
TUR = {'tortu': 'altin', 'zipzip': 'dolar', 'baykus': 'euro', 'sincap': 'nakit'}
# 2D gövde sınırları (110'luk kutu, evresiz, ölçek 1): KarakterPainter'dan ölçüldü.
IKI_D = {'altin': (10.75, 11.0, 99.25, 98.0), 'dolar': (20.0, 1.0, 90.0, 101.0),
         'euro': (16.5, 23.0, 93.5, 106.5), 'nakit': (15.0, 23.0, 110.0, 109.0)}
ATLAS = ['mutlu', 'duz', 'bulutlu', 'mutlu_sol', 'mutlu_sag', 'mutlu_yukari', 'o', 'o_sol', 'o_sag', 'o_yukari',
         'sevinc', 'kirp', 'esne']
SAHNELER = ['dokunma', 'arti', 'ziplama', 'keyif', 'etrafa_bak', 'dans', 'evre']
# Büyüme sahnesi (evre, 2026-10-26): bitki katmanı geçişin HEDEF evresiyle
# adlanır (evre_filiz = minik>filiz); gövde katmanı ortak.
TABLO = f'{REPO}/lib/widgets/karakter_3d_yerlesim.g.dart'


def ac(f):
    im = Image.open(f).convert('RGBA')
    return im.crop((KIRP_X, 0, KIRP_X + 360, im.height))


def kaydet(kareler, yol):
    kutu = None
    for k in kareler:
        b = k.getchannel('A').point(lambda a: 255 if a > 3 else 0).getbbox()
        if b:
            kutu = b if kutu is None else (min(kutu[0], b[0]), min(kutu[1], b[1]), max(kutu[2], b[2]), max(kutu[3], b[3]))
    kutu = kutu or (0, 0, 1, 1)
    kutu = (max(kutu[0] - 2, 0), max(kutu[1] - 2, 0), min(kutu[2] + 2, 360), min(kutu[3] + 2, 480))
    kk = [k.crop(kutu) for k in kareler]
    # Aynı iki kare (ör. büyümenin başındaki boş bitki kareleri) WebP
    # kodlayıcısında tek kareye birleşir ve süresi uzar; uygulama kareyi
    # sırayla seçtiği için zamanlama kayar. Köşedeki görünmez pikselin
    # alfası tek/çift karede farklı: her kare ayrı kalır.
    for i, k in enumerate(kk):
        p = k.getpixel((0, 0))
        if p[3] <= 3:
            k.putpixel((0, 0), (0, 0, 0, i % 2 + 1))
    # Kalite 65 (Ar-Ge 26 Eki 20:07 #2; 27 Eki ölçüldü): 82'ye göre 21,3 →
    # 17,1 MB, 6× büyütmede kontur ve kenar aynı. Alfa kayıpsız kalır
    # (alpha_quality denendi, animasyonlu kayıtta alfa değişmedi; kenar
    # halkası riski de yok). PNG'den üretilir; WebP'den yeniden kodlamak
    # ikinci nesil kayıp ekler.
    kk[0].save(yol, save_all=True, append_images=kk[1:], duration=33, loop=0, quality=65, method=6,
               lossless=False, minimize_size=False, allow_mixed=False)
    return kutu


# Kısmi üretim: KARE'de karesi olmayan atlas/sahne için tablodaki eski satır
# korunur (ör. yalnız evre sahnesi yeniden render edildiğinde).
eski = {}
if os.path.exists(TABLO):
    for satir in open(TABLO, encoding='utf-8'):
        if satir.startswith(('  VarlikTuru.', "  '")):
            eski[satir.split(':')[0]] = satir.rstrip('\n')
satirlar = []
for k, tur in TUR.items():
    os.makedirs(f'{OUT}/{tur}', exist_ok=True)
    if not os.path.exists(f'{B}/uyg/{k}/atlas/minik/mutlu.png'):
        satirlar.append(eski[f'  VarlikTuru.{tur}'])
        for e in ['minik', 'filiz', 'cicek', 'yildiz']:
            satirlar.append(eski[f"  '{tur}/atlas_{e}'"])
        for s in SAHNELER:
            for kat in ['beden', 'filiz', 'cicek', 'yildiz']:
                fs = sorted(glob.glob(f'{B}/uyg/{k}/{s}/{kat}/*.png'))
                if fs:
                    kutu = kaydet([ac(f) for f in fs], f'{OUT}/{tur}/{s}_{kat}.webp')
                    satirlar.append(f"  '{tur}/{s}_{kat}': {kutu},")
                else:
                    satirlar.append(eski[f"  '{tur}/{s}_{kat}'"])
        print('tamam (kısmi)', k)
        continue
    # Kalibrasyon: minik "mutlu" (bitkisiz) gövdesi 2D gövdesine oturur.
    ref = ac(f'{B}/uyg/{k}/atlas/minik/mutlu.png').getchannel('A').point(lambda a: 255 if a > 20 else 0).getbbox()
    x0, y0, x1, y1 = IKI_D[tur]
    # Yükseklik ve genişlik oranlarının geometrik ortası: kulak/kabuk oranı
    # 2D ile 3D'de farklı; yalnız boya göre Zıpzıp küçük, Tortu iri kalıyordu.
    olc = ((y1 - y0) / (ref[3] - ref[1]) * (x1 - x0) / (ref[2] - ref[0])) ** .5
    ox = (x0 + x1) / 2 - (ref[0] + ref[2]) / 2 * olc
    oy = y1 - ref[3] * olc
    satirlar.append(f"  VarlikTuru.{tur}: ({ox:.3f}, {oy:.3f}, {olc:.5f}),")
    for e in ['minik', 'filiz', 'cicek', 'yildiz']:
        kutu = kaydet([ac(f'{B}/uyg/{k}/atlas/{e}/{a}.png') for a in ATLAS], f'{OUT}/{tur}/atlas_{e}.webp')
        satirlar.append(f"  '{tur}/atlas_{e}': {kutu},")
    for s in SAHNELER:
        for kat in ['beden', 'filiz', 'cicek', 'yildiz']:
            fs = sorted(glob.glob(f'{B}/uyg/{k}/{s}/{kat}/*.png'))
            kutu = kaydet([ac(f) for f in fs], f'{OUT}/{tur}/{s}_{kat}.webp')
            satirlar.append(f"  '{tur}/{s}_{kat}': {kutu},")
    print('tamam', k)

yerlesim = [s for s in satirlar if s.startswith('  VarlikTuru')]
kirpim = [s.replace('(', '(').replace(')', ')') for s in satirlar if s.startswith("  '")]
with open(TABLO, 'w') as f:
    f.write("// ÜRETİLDİ: tool/karakter3d/donustur.py. Elle düzenleme.\n"
            "part of 'karakter.dart';\n\n"
            "/// 3D kaynak pikselinden (360×480 kadraj) 110'luk kutuya: (x kayması, y kayması, ölçek).\n"
            "const _yerlesim3d = <VarlikTuru, (double, double, double)>{\n" + '\n'.join(yerlesim) + "\n};\n\n"
            "/// Her WebP'nin kadrajdaki kırpım kutusu (sol, üst, sağ, alt).\n"
            "const _kirpim3d = <String, (int, int, int, int)>{\n" + '\n'.join(kirpim) + "\n};\n")
print('yazildi')
