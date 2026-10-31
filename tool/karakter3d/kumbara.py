# Zıpzıp 3D: model + iskelet + sahneler (tarz B, konturlu çizgi film).
#
# Kullanım:
#   python zz.py poz <cikti.png> [--evre yildiz] [--yuz sevinc] [--boyut 1024]
#   python zz.py sahne <sahne> <klasor> [--katman hepsi|govde|bitki] [--evre filiz|minik>filiz]
#                [--boyut 512] [--kare 0-41] [--ornek 48]
#
# Hareket uygulamadaki 2D karakterle AYNI zaman çizelgesini izler (karakter.dart:
# ziplamaEgrisi, yemeYuzu, evreSahnesi...). Sesler ve zemin gölgesi uygulamada
# kalır; kareler o zamanlamaya göre çakışmalı. 2D birim → 3D: kulak ucu ile
# ayak arası 2D'de ~90 birim, 3D'de 2,15.
import math
import sys

import bpy
import bmesh
from mathutils import Vector

FPS = 30
U = 2.15 / 90.0
MUREKKEP = '#2A1B14'

# ── Sahne kurulumu ─────────────────────────────────────────────────────────
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def renk(h):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), 1)


def karis(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def malzeme(ad, h, puruz=0.9, emisyon=0.0):
    m = bpy.data.materials.new(ad)
    m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = renk(h)
    p.inputs['Roughness'].default_value = puruz
    if emisyon:
        p.inputs['Emission Color'].default_value = renk(h)
        p.inputs['Emission Strength'].default_value = emisyon
    return m


def taban_rengi(m, c):
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = c


def hasir(ad, taban, cizgi):
    """Hasır örgü: nesne koordinatında iki yönlü çizgiler (gövdeyle birlikte döner, ezilir)."""
    m = malzeme(ad, taban)
    nt = m.node_tree
    n, l = nt.nodes, nt.links
    p = n['Principled BSDF']
    tc = n.new('ShaderNodeTexCoord')
    ayir = n.new('ShaderNodeSeparateXYZ')
    l.new(tc.outputs['Object'], ayir.inputs[0])
    maskeler = []
    for eks in ('X', 'Z'):
        olc = n.new('ShaderNodeMath'); olc.operation = 'MULTIPLY'; olc.inputs[1].default_value = 9.0
        l.new(ayir.outputs[eks], olc.inputs[0])
        fr = n.new('ShaderNodeMath'); fr.operation = 'FRACT'
        l.new(olc.outputs[0], fr.inputs[0])
        cik = n.new('ShaderNodeMath'); cik.operation = 'SUBTRACT'; cik.inputs[1].default_value = 0.5
        l.new(fr.outputs[0], cik.inputs[0])
        ab = n.new('ShaderNodeMath'); ab.operation = 'ABSOLUTE'
        l.new(cik.outputs[0], ab.inputs[0])
        ss = n.new('ShaderNodeMapRange'); ss.interpolation_type = 'SMOOTHSTEP'
        ss.inputs['From Min'].default_value = 0.36; ss.inputs['From Max'].default_value = 0.46
        l.new(ab.outputs[0], ss.inputs['Value'])
        maskeler.append(ss)
    mx = n.new('ShaderNodeMath'); mx.operation = 'MAXIMUM'
    l.new(maskeler[0].outputs[0], mx.inputs[0]); l.new(maskeler[1].outputs[0], mx.inputs[1])
    k = n.new('ShaderNodeMix'); k.data_type = 'RGBA'
    k.inputs['A'].default_value = renk(taban); k.inputs['B'].default_value = renk(cizgi)
    carp = n.new('ShaderNodeMath'); carp.operation = 'MULTIPLY'; carp.inputs[1].default_value = 0.75
    l.new(mx.outputs[0], carp.inputs[0])
    l.new(carp.outputs[0], k.inputs['Factor'])
    l.new(k.outputs['Result'], p.inputs['Base Color'])
    return m


# Mürekkep kabuğu (ters kabuk): yalnız kameraya görünür; ışık ışınları için
# şeffaf, yoksa gövdeyi kendi gölgesinde bırakır.
ink = bpy.data.materials.new('murekkep')
ink.use_nodes = True
nt = ink.node_tree
nt.nodes.clear()
_out = nt.nodes.new('ShaderNodeOutputMaterial')
_geo = nt.nodes.new('ShaderNodeNewGeometry')
_em = nt.nodes.new('ShaderNodeEmission'); _em.inputs['Color'].default_value = renk(MUREKKEP)
_tr = nt.nodes.new('ShaderNodeBsdfTransparent')
_mix = nt.nodes.new('ShaderNodeMixShader')
nt.links.new(_geo.outputs['Backfacing'], _mix.inputs['Fac'])
nt.links.new(_em.outputs[0], _mix.inputs[1])
nt.links.new(_tr.outputs[0], _mix.inputs[2])
_lp = nt.nodes.new('ShaderNodeLightPath')
_mix2 = nt.nodes.new('ShaderNodeMixShader')
_tr2 = nt.nodes.new('ShaderNodeBsdfTransparent')
nt.links.new(_lp.outputs['Is Camera Ray'], _mix2.inputs['Fac'])
nt.links.new(_tr2.outputs[0], _mix2.inputs[1])
nt.links.new(_mix.outputs[0], _mix2.inputs[2])
nt.links.new(_mix2.outputs[0], _out.inputs['Surface'])


def bos(ad, konum, ebeveyn=None):
    o = bpy.data.objects.new(ad, None)
    sc.collection.objects.link(o)
    o.location = konum
    if ebeveyn:
        bagla(o, ebeveyn)
    return o


def bagla(c, p):
    bpy.context.view_layer.update()
    mw = c.matrix_world.copy()
    c.parent = p
    c.matrix_parent_inverse = p.matrix_world.inverted()
    bpy.context.view_layer.update()
    assert (c.matrix_world.translation - mw.translation).length < 1e-4


def kontur_ekle(o, kalinlik):
    o.data.materials.append(ink)
    s = o.modifiers.new('kontur', 'SOLIDIFY')
    s.thickness = kalinlik
    s.offset = 1
    s.use_flip_normals = True
    s.material_offset = 1


def kure(ad, konum, olcek, m, ebeveyn, dondur=(0, 0, 0), dilim=48, cizgi=0.012):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=dilim, ring_count=dilim // 2, location=konum)
    o = bpy.context.active_object
    o.name = ad
    o.scale = olcek
    o.rotation_euler = [math.radians(a) for a in dondur]
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    if cizgi > 0:
        kontur_ekle(o, cizgi / max(min(olcek), 0.05))
    if ebeveyn is not None:
        bagla(o, ebeveyn)
    return o


def egri(ad, noktalar, kalinlik, m, ebeveyn):
    cv = bpy.data.curves.new(ad, 'CURVE')
    cv.dimensions = '3D'
    cv.bevel_depth = kalinlik
    cv.bevel_resolution = 4
    cv.use_fill_caps = True
    sp = cv.splines.new('POLY')
    sp.points.add(len(noktalar) - 1)
    for p, c in zip(sp.points, noktalar):
        p.co = (*c, 1)
    o = bpy.data.objects.new(ad, cv)
    sc.collection.objects.link(o)
    cv.materials.append(m)
    bagla(o, ebeveyn)
    return o


def egri_guncelle(o, noktalar):
    for p, c in zip(o.data.splines[0].points, noktalar):
        p.co = (*c, 1)


# ── Karakter seçimi ───────────────────────────────────────────────────────
KARAKTER = sys.argv[sys.argv.index('--karakter') + 1] if '--karakter' in sys.argv else 'zipzip'
S = 0.0205  # 2D birim → 3D (karakter.dart 110×110 kutu; zemin y=100)


def X(x2):
    return (x2 - 55) * S


def Z(y2):
    return (100 - y2) * S


def bul(u):
    return [i / (u - 1) * 2 - 1 for i in range(u)]


# Yüz yüzeyi: yüz parçaları bu elipsoidin önüne yapışır (karaktere göre).
YUZ_M = Vector((0.0, 0.0, 0.62))
YUZ_R = Vector((0.70, 0.62, 0.62))


def yuzey_y(x, z, disari=0.0):
    t = 1 - ((x - YUZ_M.x) / YUZ_R.x) ** 2 - ((z - YUZ_M.z) / YUZ_R.z) ** 2
    return YUZ_M.y - YUZ_R.y * math.sqrt(max(t, 0.0)) - disari


def yuzeye_otur(o, x, z):
    """Yassı nesneyi yüzey normaline çevirir (yanak gibi)."""
    y = yuzey_y(x, z)
    n = Vector(((x - YUZ_M.x) / YUZ_R.x ** 2, (y - YUZ_M.y) / YUZ_R.y ** 2, (z - YUZ_M.z) / YUZ_R.z ** 2)).normalized()
    o.rotation_euler = (-n).to_track_quat('Y', 'Z').to_euler()


def desen(ad, taban, fn):
    """Prosedürel desenli malzeme: fn(nodes, links, koord, principled) rengi bağlar."""
    m = malzeme(ad, taban)
    nt = m.node_tree
    tc = nt.nodes.new('ShaderNodeTexCoord')
    ayir = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(tc.outputs['Object'], ayir.inputs[0])
    fn(nt.nodes, nt.links, ayir, nt.nodes['Principled BSDF'])
    return m


def _m(n, l, op, a, b=None, v=None):
    x = n.new('ShaderNodeMath'); x.operation = op
    for i, s in enumerate((a, b)):
        if s is None:
            continue
        if isinstance(s, (int, float)):
            x.inputs[i].default_value = s
        else:
            l.new(s, x.inputs[i])
    return x.outputs[0]


def _karis(n, l, fac, a, b):
    k = n.new('ShaderNodeMix'); k.data_type = 'RGBA'
    for s, girdi in ((a, 'A'), (b, 'B')):
        if isinstance(s, tuple):
            k.inputs[girdi].default_value = s
        else:
            l.new(s, k.inputs[girdi])
    if isinstance(fac, (int, float)):
        k.inputs['Factor'].default_value = fac
    else:
        l.new(fac, k.inputs['Factor'])
    return k.outputs['Result']


def _adim(n, l, deger, a, b):
    """smoothstep(a, b, deger)"""
    r = n.new('ShaderNodeMapRange'); r.interpolation_type = 'SMOOTHSTEP'
    r.inputs['From Min'].default_value = a; r.inputs['From Max'].default_value = b
    l.new(deger, r.inputs['Value'])
    return r.outputs[0]


def cini_desen(n, l, a, p, kenar_z=0.1):
    """Tortu kabuğu: mavi zemin, krem dört köşe yıldız, turuncu nokta; altta altın kenar."""
    u = _m(n, l, 'MULTIPLY', _m(n, l, 'ARCTAN2', a.outputs['X'], _m(n, l, 'MULTIPLY', a.outputs['Y'], -1.0)), 2.6)
    v = _m(n, l, 'MULTIPLY', a.outputs['Z'], 4.2)
    dx = _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'FRACT', u), 0.5))
    dz = _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'FRACT', v), 0.5))
    yil = _m(n, l, 'ADD', _m(n, l, 'SQRT', dx), _m(n, l, 'SQRT', dz))
    yildiz = _adim(n, l, yil, 0.62, 0.56)
    nokta = _adim(n, l, _m(n, l, 'ADD', _m(n, l, 'MULTIPLY', dx, dx), _m(n, l, 'MULTIPLY', dz, dz)), 0.010, 0.006)
    c = _karis(n, l, yildiz, renk('#2B6FD6'), renk('#FFFAF0'))
    c = _karis(n, l, nokta, c, renk('#E8540E'))
    kenar = _adim(n, l, a.outputs['Z'], kenar_z + 0.02, kenar_z - 0.02)
    c = _karis(n, l, kenar, c, renk('#E0A800'))
    l.new(c, p.inputs['Base Color'])


def kilim_renk(n, l, a, sik=6.0):
    """Kırmızı kilim: sarı ve lacivert zikzak şeritler (nesne çevresinde döner)."""
    u = _m(n, l, 'MULTIPLY', _m(n, l, 'ARCTAN2', a.outputs['X'], _m(n, l, 'MULTIPLY', a.outputs['Y'], -1.0)), sik)
    v = _m(n, l, 'MULTIPLY', a.outputs['Z'], sik * 1.6)
    tri = _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'FRACT', u), 0.5))
    fv = _m(n, l, 'FRACT', v)
    sari = _adim(n, l, _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'SUBTRACT', fv, _m(n, l, 'MULTIPLY', tri, 0.5)), 0.2)), 0.09, 0.05)
    lac = _adim(n, l, _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'ADD', fv, _m(n, l, 'MULTIPLY', tri, 0.5)), 0.82)), 0.06, 0.03)
    c = _karis(n, l, sari, renk('#B3261E'), renk('#F7D774'))
    return _karis(n, l, lac, c, renk('#1F3B73'))


def kilim_desen(n, l, a, p):
    l.new(kilim_renk(n, l, a, 3.0), p.inputs['Base Color'])


def kusak_desen(n, l, a, p):
    """Baykuş gövdesi: lacivert, göğüste mercek biçimli kilim kuşak."""
    x2 = _m(n, l, 'MULTIPLY', a.outputs['X'], a.outputs['X'])
    ust = _m(n, l, 'ADD', _m(n, l, 'MULTIPLY', x2, 0.3), -0.47)
    alt = _m(n, l, 'ADD', _m(n, l, 'MULTIPLY', x2, 0.3), -0.8)
    z = a.outputs['Z']
    ic = _m(n, l, 'MULTIPLY', _adim(n, l, _m(n, l, 'SUBTRACT', ust, z), -0.015, 0.015),
            _adim(n, l, _m(n, l, 'SUBTRACT', z, alt), -0.015, 0.015))
    c = _karis(n, l, ic, renk('#1F3B73'), kilim_renk(n, l, a, 5.0))
    l.new(c, p.inputs['Base Color'])


# Ortak malzemeler
goz_ak = malzeme('goz_ak', '#FFFAF0', puruz=0.4)
bebek_m = malzeme('bebek', MUREKKEP, puruz=0.3)
isik_m = malzeme('isik', '#FFFFFF', emisyon=3.0)
yanak_m = malzeme('yanak', '#F28C8C', puruz=0.8)
agiz_m = malzeme('agiz', MUREKKEP, puruz=0.6)
ic_agiz = malzeme('ic_agiz', '#7A2E2A', puruz=0.7)
dil_m = malzeme('dil', '#F28C8C', puruz=0.6)
sap_m = malzeme('sap', '#3E8E4A')
yaprak_m = malzeme('yaprak', '#6CC56B')
gobek_m = malzeme('gobek', '#F7D774')
yildiz_m = malzeme('yildiz', '#FFF3B0', emisyon=0.25)
para_m = malzeme('para', '#F7C948', puruz=0.35)
para_ic = malzeme('para_ic', '#E0A800', puruz=0.35)
YANAK_A, YANAK_B = renk('#F28C8C'), renk('#FF6F8F')
TAC = {'tortu': '#F28C8C', 'zipzip': '#FFB3C7', 'baykus': '#FFFAF0', 'sincap': '#B9A7FF'}
tac_m = malzeme('tac', TAC[KARAKTER])
TAC_A, TAC_B = renk(TAC[KARAKTER]), renk('#F7C948')

# İskelet: kök (zemin, yana eğilme) → ezme (zeminden ezilip uzama) → baş (dönme).
kok = bos('kok', (0, 0, 0))
ezme = bos('ezme', (0, 0, 0), kok)
kulak_kok, goz_kok, bebek_kok, sevinc_goz, kapali_goz, yanaklar = [], [], [], [], [], []
KULAK_K = 1.0
kuyruk_kok = None
el_parasi = None


def taban_bas(v_alt=-0.7, ezik=0.4):
    def f(o):
        for v in o.data.vertices:
            if v.co.z < v_alt:
                v.co.z = v_alt + (v.co.z - v_alt) * ezik
    return f


def goz_kur(i, x, z, k, ebeveyn, nazar=False):
    """Göz: açık göz (ak + bebek + parıltı) basılarak kapanır; ^ ve ‿ çizgileri ayrı."""
    yf = yuzey_y(x, z)
    if nazar:
        kure(f'nazar_halka{i}', (x, yf + 0.01, z), (0.246, 0.03, 0.246), malzeme(f'nazar{i}', '#7FC8FF', puruz=0.5), ebeveyn, cizgi=0.01)
        ye = yf - 0.02
        gk = bos(f'goz_kok{i}', (x, ye, z), ebeveyn)
        kure(f'goz{i}', (x, ye, z), (0.205, 0.07, 0.205), goz_ak, gk, cizgi=0.01)
        bk = bos(f'bebek_kok{i}', (x, ye, z), gk)
        kure(f'iris{i}', (x + 0.015, ye - 0.06, z - 0.01), (0.127, 0.025, 0.127), malzeme(f'iris{i}', '#2B6FD6', puruz=0.4), bk, cizgi=0)
        kure(f'bebek{i}', (x + 0.015, ye - 0.08, z - 0.01), (0.07, 0.015, 0.07), bebek_m, bk, cizgi=0)
        kure(f'isik{i}', (x + 0.065, ye - 0.095, z + 0.06), (0.035, 0.01, 0.035), isik_m, bk, cizgi=0)
        kure(f'isik2{i}', (x - 0.03, ye - 0.095, z - 0.06), (0.016, 0.008, 0.016), isik_m, bk, cizgi=0)
        k = 1.37
    else:
        ye = yf + 0.037 * k
        gk = bos(f'goz_kok{i}', (x, ye, z), ebeveyn)
        kure(f'goz{i}', (x, ye, z), (0.15 * k, 0.09 * k, 0.16 * k), goz_ak, gk, cizgi=0.012)
        bk = bos(f'bebek_kok{i}', (x, ye, z), gk)
        kure(f'bebek{i}', (x + 0.012 * k, ye - 0.085 * k, z - 0.01 * k), (0.085 * k, 0.03 * k, 0.095 * k), bebek_m, bk, cizgi=0)
        kure(f'isik{i}', (x + 0.045 * k, ye - 0.112 * k, z + 0.04 * k), (0.03 * k, 0.01 * k, 0.03 * k), isik_m, bk, cizgi=0)
        kure(f'isik2{i}', (x - 0.025 * k, ye - 0.112 * k, z - 0.06 * k), (0.014 * k, 0.008 * k, 0.014 * k), isik_m, bk, cizgi=0)
    goz_kok.append(gk)
    bebek_kok.append(bk)
    w = 0.11 * k
    sk = bos(f'sevinc_kok{i}', (x, yf - 0.05, z), ebeveyn)
    egri(f'sevinc_goz{i}', [(x + u * w, yuzey_y(x + u * w, z) - 0.05 * max(k, 1), z - 0.02 * k + 0.06 * k * (1 - u * u)) for u in bul(11)],
         0.024, agiz_m, sk)
    kp = bos(f'kapali_kok{i}', (x, yf - 0.05, z), ebeveyn)
    egri(f'kapali_goz{i}', [(x + u * w, yuzey_y(x + u * w, z) - 0.05 * max(k, 1), z + 0.01 * k - 0.05 * k * (1 - u * u)) for u in bul(11)],
         0.022, agiz_m, kp)
    sevinc_goz.append(sk)
    kapali_goz.append(kp)


AGIZ_X, AGIZ_Z = 0.0, 0.665


def gulus_noktalari(g):
    w, d = 0.09 + 0.025 * g, 0.012 + 0.04 * g
    return [(AGIZ_X + u * w, yuzey_y(AGIZ_X + u * w, AGIZ_Z - d * (1 - u * u)) - 0.012, AGIZ_Z - d * (1 - u * u)) for u in bul(15)]


def agiz_ag(ad, w, ust, alt, m, ebeveyn, disari, nu=14, nv=5):
    """Yüzeye yapışık ağız içi: üst kenar ust(u), alt kenar alt(u) (u: -1..1)."""
    me = bpy.data.meshes.new(ad)
    bm = bmesh.new()
    vs = []
    for j in range(nv):
        v = j / (nv - 1)
        row = []
        for u in bul(nu):
            x = AGIZ_X + u * w
            z = ust(u) + (alt(u) - ust(u)) * v
            row.append(bm.verts.new((x, yuzey_y(x, z, disari), z)))
        vs.append(row)
    for j in range(nv - 1):
        for i in range(nu - 1):
            bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(ad, me)
    sc.collection.objects.link(o)
    me.materials.append(m)
    for p in me.polygons:
        p.use_smooth = True
    bagla(o, ebeveyn)
    return o


def agiz_kur(ebeveyn):
    global agiz, agiz_d, agiz_o
    agiz = egri('agiz', gulus_noktalari(1), 0.018, agiz_m, ebeveyn)
    W1, D1 = 0.115, 0.052
    agiz_d = bos('agiz_d', (AGIZ_X, yuzey_y(AGIZ_X, AGIZ_Z - D1), AGIZ_Z - D1), ebeveyn)
    agiz_ag('ic_agiz', W1, lambda u: AGIZ_Z - D1 * (1 - u * u), lambda u: AGIZ_Z - D1 * (1 - u * u) - 0.12 * math.sqrt(max(1 - u * u, 0)),
            ic_agiz, agiz_d, 0.01)
    agiz_ag('dil', W1 * 0.6, lambda u: AGIZ_Z - D1 - 0.07 + 0.02 * u * u,
            lambda u: AGIZ_Z - D1 - 0.12 * math.sqrt(max(1 - (u * .6) ** 2, 0)) + 0.012, dil_m, agiz_d, 0.014, nu=10, nv=4)
    oz = AGIZ_Z - 0.045
    agiz_o = bos('agiz_o', (AGIZ_X, yuzey_y(AGIZ_X, oz), oz), ebeveyn)
    agiz_ag('o_agiz', 0.07, lambda u: oz + 0.08 * math.sqrt(max(1 - u * u, 0)), lambda u: oz - 0.08 * math.sqrt(max(1 - u * u, 0)),
            ic_agiz, agiz_o, 0.01)


def yanak_kur(i, x, z, ebeveyn, k=1.0):
    o = kure(f'yanak{i}', (x, yuzey_y(x, z) + 0.01, z), (0.14 * k, 0.03, 0.09 * k), yanak_m, None, cizgi=0)
    yuzeye_otur(o, x, z)
    bagla(o, ebeveyn)
    yanaklar.append(o)


# ── Karakterler ────────────────────────────────────────────────────────────
if KARAKTER == 'zipzip':
    YUZ_M, YUZ_R = Vector((0.0, 0.0, 0.62)), Vector((0.70, 0.62, 0.62))
    bas = bos('bas', YUZ_M, ezme)
    govde_m = hasir('govde', '#3DBB6C', '#23874A')
    kulak_m = malzeme('kulak', '#3DBB6C')
    govde = kure('govde', YUZ_M, YUZ_R, govde_m, bas, dilim=96, cizgi=0.018)
    taban_bas()(govde)
    for i, x in enumerate((-0.22, 0.22)):
        yon = -1 if x < 0 else 1
        kk = bos(f'kulak_kok{i}', (x + yon * 0.03, 0.05, 1.12), bas)
        kure(f'kulak{i}', (x + yon * 0.06, 0.04, 1.62), (0.15, 0.09, 0.52), kulak_m, kk, dondur=(-8, yon * 10, 0), cizgi=0.016)
        kure(f'ickulak{i}', (x + yon * 0.06, -0.035, 1.64), (0.085, 0.03, 0.40), malzeme('ic_kulak', '#F28C8C'), kk,
             dondur=(-8, yon * 10, 0), cizgi=0)
        kulak_kok.append(kk)
    kure('karin', (0, -0.5, 0.33), (0.33, 0.16, 0.21), malzeme('karin', '#F4F1D8'), bas, dilim=64, cizgi=0.014)
    for i, x in enumerate((-0.22, 0.22)):
        goz_kur(i, x, 0.86, 1.0, bas)
    for i, x in enumerate((-0.35, 0.35)):
        yanak_kur(i, x, 0.66, bas)
    kure('burun', (0, -0.6, 0.72), (0.05, 0.035, 0.035), malzeme('burun', '#F28C8C', puruz=0.5), bas, cizgi=0.008)
    AGIZ_X, AGIZ_Z = 0.0, 0.665
    agiz_kur(bas)
    ayak_m = malzeme('ayak', '#34A862')
    for i, x in enumerate((-0.26, 0.26)):
        kure(f'ayak{i}', (x, -0.3, 0.07), (0.17, 0.2, 0.08), ayak_m, kok, cizgi=0.012)
    BITKI, BITKI_EGIM, BITKI_EBEVEYN = (0.0, -0.06, 1.2), 0.0, bas

elif KARAKTER == 'tortu':
    # Kabuk gövdedir (ezilir), baş boynun üstünde ayrı döner.
    kabuk_m = desen('kabuk', '#2B6FD6', cini_desen)
    ten = malzeme('ten', '#F5C76A')
    kabuk = kure('kabuk', (0, 0.12, Z(86)), (0.9, 0.72, 1.06), kabuk_m, ezme, dilim=96, cizgi=0.02)
    for v in kabuk.data.vertices:
        if v.co.z < 0:
            v.co.z *= 0.12
    for i, x in enumerate((-0.56, 0.56)):
        kure(f'ayak{i}', (x, -0.3, 0.13), (0.19, 0.22, 0.14), malzeme('ayak', '#C98A00'), ezme, cizgi=0.014)
    kure('boyun', (0, -0.42, 0.86), (0.2, 0.24, 0.26), ten, ezme, cizgi=0.014)
    YUZ_M, YUZ_R = Vector((0.0, -0.66, 1.22)), Vector((0.38, 0.34, 0.36))
    bas = bos('bas', (0, -0.5, 0.85), ezme)
    kure('kafa', YUZ_M, YUZ_R, ten, bas, dilim=64, cizgi=0.018)
    for i, x in enumerate((X(47), X(63))):
        goz_kur(i, x * 0.85, 1.27, 0.8, bas)
    for i, x in enumerate((-0.24, 0.24)):
        yanak_kur(i, x, 1.1, bas, 0.75)
    AGIZ_X, AGIZ_Z = 0.0, 1.1
    agiz_kur(bas)
    # Kafa üstündeki kavis çizgisi (2D'deki "M44 16q11-8 22 0").
    egri('kas', [(u * 0.2, yuzey_y(u * 0.2, YUZ_M.z + 0.3) - 0.004, YUZ_M.z + 0.3 + 0.04 * (1 - u * u)) for u in bul(11)], 0.016, agiz_m, bas)
    KULAK_K = 0.0
    # Bitki kabuğun sağ omzunda, dışa eğik (2D: (85,55), 0,75 rad).
    BITKI, BITKI_EGIM, BITKI_EBEVEYN = (X(85) - 0.02, 0.12, 1.0), 0.75, ezme

elif KARAKTER == 'baykus':
    lacivert = '#1F3B73'
    govde = kure('govde', (0, 0, Z(62)), (36 * S, 0.62, 38 * S), desen('govde', lacivert, kusak_desen), ezme, dilim=96, cizgi=0.02)
    taban_bas(-0.75, 0.35)(govde)
    bas = bos('bas', (0, 0, Z(62)), ezme)
    # Kulak tüyleri: üst köşelerden dışa ve yukarı.
    tuy_m = malzeme('tuy', lacivert)
    for i, yon in enumerate((-1, 1)):
        kk = bos(f'kulak_kok{i}', (yon * 0.36, 0.05, 1.18), bas)
        kure(f'kulak{i}', (yon * 0.5, 0.05, 1.32), (0.09, 0.09, 0.24), tuy_m, kk, dondur=(0, yon * 52, 0), cizgi=0.02)
        kulak_kok.append(kk)
    YUZ_M, YUZ_R = Vector((0.0, -0.53, Z(60))), Vector((24 * S, 0.16, 19 * S))
    kure('yuz', YUZ_M, YUZ_R, malzeme('yuz', '#DBE7FF'), bas, dilim=64, cizgi=0.012)
    for i, x in enumerate((X(42), X(68))):
        goz_kur(i, x, Z(56) - 0.02, 1.0, bas, nazar=True)
    for i, x in enumerate((X(35) + 0.04, X(75) - 0.04)):
        yanak_kur(i, x, Z(68), bas, 0.8)
    gaga_m = malzeme('gaga', '#F5B82E', puruz=0.5)
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.1, depth=0.17, location=(0, yuzey_y(0, Z(70)) - 0.05, Z(70)),
                                    rotation=(math.radians(180 - 25), 0, 0))
    gaga = bpy.context.active_object
    gaga.name = 'gaga'
    gaga.data.materials.append(gaga_m)
    bpy.ops.object.shade_smooth()
    kontur_ekle(gaga, 0.012)
    bagla(gaga, bas)
    AGIZ_X, AGIZ_Z = 0.0, Z(75)
    agiz_kur(bas)
    ayak_m = malzeme('ayak', '#F5B82E', puruz=0.5)
    for i, x in enumerate((-0.24, 0.24)):
        kure(f'ayak{i}', (x, -0.35, 0.06), (0.15, 0.17, 0.07), ayak_m, kok, cizgi=0.012)
    KULAK_K = 0.35
    BITKI, BITKI_EGIM, BITKI_EBEVEYN = (0.0, -0.05, Z(25) - 0.06), 0.0, bas

elif KARAKTER == 'sincap':
    turuncu = '#E8540E'
    gm = malzeme('govde', turuncu)
    cx = X(46)
    kuyruk_kok = bos('kuyruk_kok', (0.12, 0.2, 0.25), ezme)
    km = desen('kuyruk', '#B3261E', kilim_desen)
    kure('kuyruk', (0.5, 0.3, 0.78), (0.3, 0.27, 0.6), km, kuyruk_kok, dondur=(0, 12, 0), dilim=64, cizgi=0.02)
    kure('kuyruk_uc', (0.66, 0.26, 1.32), (0.28, 0.25, 0.25), km, kuyruk_kok, dondur=(0, -30, 0), dilim=48, cizgi=0.02)
    YUZ_M, YUZ_R = Vector((cx, 0.0, Z(64))), Vector((30 * S, 0.58, 32 * S))
    govde = kure('govde', YUZ_M, YUZ_R, gm, ezme, dilim=96, cizgi=0.018)
    taban_bas()(govde)
    bas = bos('bas', YUZ_M, ezme)
    # Govde bas'a bağlı değil: baş dönerken kuyruk yerinde kalsın; yüz bas'ta.
    for i, (bx_, tip) in enumerate(((X(30), X(27)), (X(62), X(65)))):
        yon = -1 if i == 0 else 1
        kk = bos(f'kulak_kok{i}', (bx_, 0.02, Z(40)), bas)
        bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.15, depth=0.42, location=(bx_ + yon * 0.03, 0.02, Z(40) + 0.17),
                                        rotation=(0, math.radians(yon * 12), 0))
        k_ = bpy.context.active_object
        k_.name = f'kulak{i}'
        k_.data.materials.append(gm)
        bpy.ops.object.shade_smooth()
        kontur_ekle(k_, 0.016)
        bagla(k_, kk)
        bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.08, depth=0.24, location=(bx_ + yon * 0.03, -0.08, Z(40) + 0.15),
                                        rotation=(0, math.radians(yon * 12), 0))
        ic = bpy.context.active_object
        ic.name = f'ickulak{i}'
        ic.data.materials.append(malzeme('ic_kulak', '#F28C8C'))
        bpy.ops.object.shade_smooth()
        bagla(ic, kk)
        kulak_kok.append(kk)
    kure('karin', (cx, -0.48, 0.34), (0.32, 0.15, 0.21), malzeme('karin', '#FFE3C2'), bas, dilim=64, cizgi=0.014)
    for i, x in enumerate((X(36), X(56))):
        goz_kur(i, x, Z(58) + 0.02, 0.88, bas)
    for i, x in enumerate((X(29) + 0.04, X(63) - 0.04)):
        yanak_kur(i, x, 0.66, bas, 0.85)
    kure('burun', (cx, yuzey_y(cx, 0.72) + 0.02, 0.72), (0.05, 0.035, 0.035), malzeme('burun', MUREKKEP, puruz=0.4), bas, cizgi=0)
    AGIZ_X, AGIZ_Z = cx, 0.665
    agiz_kur(bas)
    ayak_m = malzeme('ayak', '#C94A0C')
    for i, x in enumerate((cx - 0.24, cx + 0.24)):
        kure(f'ayak{i}', (x, -0.3, 0.07), (0.16, 0.19, 0.08), ayak_m, kok, cizgi=0.012)
    # Madeni para (simgesiz; simgeyi uygulama yazar) ve onu tutan iki pati.
    el_parasi = bos('el_parasi', (cx, -0.66, 0.26), ezme)
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.2, depth=0.05, location=(cx, -0.66, 0.26), rotation=(math.pi / 2 - 0.15, 0, 0))
    po = bpy.context.active_object
    po.name = 'el_para'
    po.data.materials.append(para_m)
    bpy.ops.object.shade_smooth()
    bev = po.modifiers.new('pah', 'BEVEL'); bev.width = 0.01; bev.segments = 3
    kontur_ekle(po, 0.014)
    bagla(po, el_parasi)
    for i, yon in enumerate((-1, 1)):
        kure(f'pati{i}', (cx + yon * 0.19, -0.66, 0.3), (0.07, 0.07, 0.09), gm, el_parasi, cizgi=0.012)
    KULAK_K = 0.45
    BITKI, BITKI_EGIM, BITKI_EBEVEYN = (X(46) + 0.0, -0.06, Z(33) - 0.08), -0.1, bas

# ── Bitki (evre) ───────────────────────────────────────────────────────────
bitki = bos('bitki', BITKI, BITKI_EBEVEYN)
filiz_kok = bos('filiz_kok', BITKI, bitki)
SAP0 = 8 * U


def sap_noktalari(boy):
    return [(BITKI[0] - 0.035 * math.sin(math.pi * s) * (boy / SAP0) * 0.5, BITKI[1], BITKI[2] + boy * s) for s in [i / 8 for i in range(9)]]


sap = egri('sap', sap_noktalari(SAP0), 0.02, sap_m, filiz_kok)
for i, (x, z, r) in enumerate([(-4.2, 5.5, 35), (4.2, 7.5, -35)]):
    kure(f'yaprak{i}', (BITKI[0] + x * U, BITKI[1] - 0.01, BITKI[2] + z * U), (4 * U, 0.03, 2.3 * U), yaprak_m, filiz_kok,
         dondur=(0, r, 0), cizgi=0.01)
cicek_kok = bos('cicek_kok', (BITKI[0], BITKI[1] - 0.02, BITKI[2] + SAP0 + 3 * U), bitki)
cicek_c = cicek_kok.location.copy()
taclar = []
for i in range(5):
    a = -math.pi / 2 + i * 2 * math.pi / 5
    taclar.append(kure(f'tac{i}', (cicek_c.x + math.cos(a) * 3.6 * U, cicek_c.y, cicek_c.z - math.sin(a) * 3.6 * U),
                       (3 * U, 0.035, 3 * U), tac_m, cicek_kok, cizgi=0.01))
gobek = kure('gobek', (cicek_c.x, cicek_c.y - 0.03, cicek_c.z), (2.4 * U, 0.03, 2.4 * U), gobek_m, cicek_kok, cizgi=0.009)

def yildiz_nesne(ad, merkez, r, ebeveyn):
    me = bpy.data.meshes.new(ad)
    bm = bmesh.new()
    cevre = []
    for i in range(8):
        a = -math.pi / 2 + i * math.pi / 4
        rr = r if i % 2 == 0 else r * 0.42
        cevre.append(bm.verts.new((math.cos(a) * rr, 0, -math.sin(a) * rr)))
    on = bm.verts.new((0, -r * 0.35, 0))
    arka = bm.verts.new((0, r * 0.2, 0))
    for i in range(8):
        a, b = cevre[i], cevre[(i + 1) % 8]
        bm.faces.new((on, b, a))
        bm.faces.new((arka, a, b))
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(ad, me)
    sc.collection.objects.link(o)
    o.location = merkez
    me.materials.append(yildiz_m)
    kontur_ekle(o, 0.01)
    bagla(o, ebeveyn)
    return o


yildiz_kok = bos('yildiz_kok', (cicek_c.x, cicek_c.y - 0.05, cicek_c.z), cicek_kok)
yildiz_nesne('yildiz', (cicek_c.x, cicek_c.y - 0.05, cicek_c.z), 3.6 * U, yildiz_kok)
piriltilar = []
for i, (px, py, pr) in enumerate([(-9.0, 4.0, 1.9), (8.5, 7.0, 1.5)]):
    pk = bos(f'pirilti_kok{i}', (cicek_c.x + px * U, cicek_c.y - 0.05, cicek_c.z + py * U), cicek_kok)
    yildiz_nesne(f'pirilti{i}', (cicek_c.x + px * U, cicek_c.y - 0.05, cicek_c.z + py * U), pr * 1.6 * U, pk)
    piriltilar.append(pk)

bitki.rotation_euler = (0, BITKI_EGIM, 0)
BITKI_NESNELERI = {o.name for o in bitki.children_recursive} | {'bitki'}
PARA_NESNELERI = ({o.name for o in el_parasi.children_recursive} | {'el_parasi'}) if el_parasi else set()

# ── Kostüm (çıkartma, 2026-10-31) ──────────────────────────────────────────
# Çıkartma "rozet değil, karakterin KOSTÜMÜ" (cikartma.dart): açılan kostüm
# karakterin üstünde görünür. Ayrı katman olarak render edilir (`--katman
# kostum`): gövde holdout (önündeki gövde örtsün), bitki ve paralar gizli;
# diğer katmanlarda kostüm hiç yok, var olan kareler değişmez. Baş ya da
# gövdeye bağlı: başla döner, zıplamayla ezilir. Evreden bağımsız (tek set).
def simit(ad, konum, r, kalinlik, m, ebeveyn, dondur=(0, 0, 0), olcek=(1, 1, 1), cizgi=0.012):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=kalinlik, major_segments=64, minor_segments=16,
                                     location=konum, rotation=[math.radians(a) for a in dondur])
    o = bpy.context.active_object
    o.name = ad
    o.scale = olcek
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    if cizgi > 0:
        kontur_ekle(o, cizgi / max(kalinlik * 6, 0.05))
    bagla(o, ebeveyn)
    return o


def silindir(ad, konum, r, boy, m, ebeveyn, dondur=(0, 0, 0), olcek=(1, 1, 1), cizgi=0.012, pah=0.02):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=r, depth=boy, location=konum,
                                        rotation=[math.radians(a) for a in dondur])
    o = bpy.context.active_object
    o.name = ad
    o.scale = olcek
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    bev = o.modifiers.new('pah', 'BEVEL'); bev.width = pah; bev.segments = 4
    if cizgi > 0:
        kontur_ekle(o, cizgi)
    bagla(o, ebeveyn)
    return o


kostum = bos('kostum', (0, 0, 0), ezme)
if KARAKTER == 'tortu':
    # Şapka: kafanın üstünde, hafif yana yatık; kırmızı, sarı bant.
    sk = bos('sapka_kok', (0, -0.66, 1.52), bas)
    sm, bm_ = malzeme('sapka', '#D94B3D'), malzeme('sapka_bant', '#F7C948')
    silindir('sapka_kenar', (0, -0.66, 1.52), 0.36, 0.04, sm, sk, olcek=(1, 0.92, 1), pah=0.015)
    silindir('sapka_tepe', (0, -0.66, 1.64), 0.21, 0.22, sm, sk, pah=0.05)
    silindir('sapka_bant', (0, -0.66, 1.575), 0.214, 0.06, bm_, sk, cizgi=0, pah=0.01)
    sk.rotation_euler = (math.radians(-8), math.radians(-12), 0)
elif KARAKTER == 'zipzip':
    # Atkı: gövdenin boyun hizasında dolanır, ucu önden sarkar.
    def atki_desen(n, l, a, p):
        aci = _m(n, l, 'MULTIPLY', _m(n, l, 'ARCTAN2', a.outputs['X'], a.outputs['Y']), 3.5)
        cizgi = _adim(n, l, _m(n, l, 'ABSOLUTE', _m(n, l, 'SUBTRACT', _m(n, l, 'FRACT', aci), 0.5)), 0.2, 0.24)
        l.new(_karis(n, l, cizgi, renk('#FFF4E0'), renk('#E63946')), p.inputs['Base Color'])
    am = desen('atki', '#E63946', atki_desen)
    simit('atki', (0, 0, 0.47), 1.0, 0.1, am, kostum, olcek=(0.70, 0.635, 0.72))
    # Uçlar yanda (önde sarkan tek uç dil gibi okunuyordu).
    kure('atki_uc0', (0.5, -0.42, 0.3), (0.11, 0.05, 0.2), am, kostum, dondur=(0, -24, -40), cizgi=0.014)
    kure('atki_uc1', (0.6, -0.3, 0.33), (0.1, 0.05, 0.18), am, kostum, dondur=(0, -40, -50), cizgi=0.014)
elif KARAKTER == 'baykus':
    # Gözlük: nazar halkalarının çevresinde iki yuvarlak çerçeve ve köprü.
    gm_ = malzeme('gozluk', '#E8A317', puruz=0.4)
    gz = Z(56) - 0.02
    for i, x in enumerate((X(42), X(68))):
        simit(f'gozluk{i}', (x, yuzey_y(x, gz) - 0.03, gz), 0.262, 0.028, gm_, bas, dondur=(90, 0, 0), cizgi=0.01)
    egri('gozluk_kopru', [(u * 0.03, yuzey_y(0, gz + 0.1) - 0.06, gz + 0.1 + 0.03 * (1 - u * u)) for u in bul(7)], 0.022, gm_, bas)
elif KARAKTER == 'sincap':
    # Fular: boyun hizasında bant + önden aşağı üçgen.
    fm = malzeme('fular', '#2A9D8F')
    cx_ = X(46)
    simit('fular', (cx_, 0, 0.52), 1.0, 0.1, fm, kostum, olcek=(0.6, 0.57, 0.7))
    # Düğüm yanda: önü para ve patilerle dolu, önden sarkan üçgen görünmüyordu.
    kure('fular_dugum', (cx_ - 0.42, -0.38, 0.52), (0.09, 0.07, 0.08), fm, kostum, cizgi=0.012)
    kure('fular_uc0', (cx_ - 0.5, -0.36, 0.4), (0.07, 0.04, 0.14), fm, kostum, dondur=(0, 25, 30), cizgi=0.012)
    kure('fular_uc1', (cx_ - 0.36, -0.44, 0.38), (0.07, 0.04, 0.14), fm, kostum, dondur=(0, -10, 20), cizgi=0.012)
KOSTUM_NESNELERI = {o.name for o in sc.objects if o.parent is not None and (
    o.name.startswith(('sapka', 'atki', 'gozluk', 'fular')))}

# ── Paralar (yeme sahnesi) ────────────────────────────────────────────────
paralar = []
for i in range(3):
    pk = bos(f'para_kok{i}', (0, -0.7, 3.4))
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.11, depth=0.035, location=(0, -0.7, 3.4), rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object
    o.name = f'para{i}'
    o.data.materials.append(para_m)
    bpy.ops.object.shade_smooth()
    bev = o.modifiers.new('pah', 'BEVEL'); bev.width = 0.008; bev.segments = 3
    kontur_ekle(o, 0.012)
    bagla(o, pk)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.07, depth=0.045, location=(0, -0.7, 3.4), rotation=(math.pi / 2, 0, 0))
    ic = bpy.context.active_object
    ic.name = f'para_ic{i}'
    ic.data.materials.append(para_ic)
    bpy.ops.object.shade_smooth()
    bagla(ic, pk)
    paralar.append(pk)

# ── Işık, dünya, kamera (tüm sahnelerde aynı) ─────────────────────────────
gunes_d = bpy.data.lights.new('anahtar', 'SUN')
gunes_d.energy = 3.2
gunes_d.angle = 0.35
gunes_d.color = (1, 0.97, 0.92)
gunes = bpy.data.objects.new('anahtar', gunes_d)
sc.collection.objects.link(gunes)
gunes.location = (-1.6, -2.2, 6.0)
gunes.rotation_euler = (Vector((0, 0, 0.7)) - gunes.location).to_track_quat('-Z', 'Y').to_euler()
sc.world = bpy.data.worlds.new('dunya')
sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs['Color'].default_value = (1, 0.97, 0.92, 1)
sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.9

# Kenar ışığı (2026-10-17, "göz alıcı"): arkadan sıcak ışık, siluet koyu kamp
# zemininden ayrılsın; dolgu biraz düşük, hacim okunsun.
kenar_d = bpy.data.lights.new('kenar', 'AREA')
kenar_d.energy = 420
kenar_d.size = 1.6
kenar_d.color = (1, 0.86, 0.62)
kenar = bpy.data.objects.new('kenar', kenar_d)
sc.collection.objects.link(kenar)
kenar.location = (2.0, 3.2, 3.4)
kenar.rotation_euler = (Vector((0, 0, 1.2)) - kenar.location).to_track_quat('-Z', 'Y').to_euler()
kenar2 = bpy.data.objects.new('kenar2', kenar_d)
sc.collection.objects.link(kenar2)
kenar2.location = (-2.2, 3.0, 2.6)
kenar2.rotation_euler = (Vector((0, 0, 1.2)) - kenar2.location).to_track_quat('-Z', 'Y').to_euler()
sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.75

cam_d = bpy.data.cameras.new('kamera')
cam = bpy.data.objects.new('kamera', cam_d)
sc.collection.objects.link(cam)
sc.camera = cam


UYG_OLCEK = 3.3
UYG_HEDEF = 1.39


def kamera(cerceve):
    """cerceve: 'poz' (yakın, durgun) ya da 'sahne' (zıplama + düşen para payı)."""
    a = math.radians(18)
    r = 9.0
    if cerceve == 'uygulama':
        # Uygulama kareleri: dik izdüşüm, dört karakter aynı kadraj; ayak
        # tabanı sabit bir satırda kalır, Flutter 110'luk kutuya oturtur.
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = UYG_OLCEK
        cam.location = (r * math.sin(a), -r * math.cos(a), 2.2 + UYG_HEDEF - 1.36)
        cam.rotation_euler = (Vector((0, 0, UYG_HEDEF)) - Vector((cam.location.x, cam.location.y, 2.2))).to_track_quat('-Z', 'Y').to_euler()
        return
    if cerceve == 'poz':
        cam_d.lens = 118
        hedef = Vector((0, 0, 1.08))
    else:
        cam_d.lens = 98
        hedef = Vector((0, 0, 1.36))
    cam.location = (r * math.sin(a), -r * math.cos(a), 2.2)
    cam.rotation_euler = (hedef - cam.location).to_track_quat('-Z', 'Y').to_euler()


# ── Poz uygulama ───────────────────────────────────────────────────────────
DINLENME = {o.name: (o.location.copy(), o.scale.copy(), o.rotation_euler.copy()) for o in sc.objects}


def olc(o, sx, sy=None, sz=None):
    loc, s, r = DINLENME[o.name]
    sy = sx if sy is None else sy
    sz = sx if sz is None else sz
    o.scale = (s.x * sx, s.y * sy, s.z * sz)
    gizli = min(sx, sy, sz) < 0.02
    o.hide_render = gizli
    for c in o.children_recursive:
        c.hide_render = gizli


def ss(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def poz_uygula(p, katman='hepsi'):
    """p: tek karenin pozu (sözlük). Birimler 2D karakterle aynı (y yukarı +)."""
    kok.location = (0, 0, p.get('y', 0) * U)
    kok.rotation_euler = (0, p.get('aci', 0), p.get('donus', 0))
    ezme.scale = (p.get('sx', 1), p.get('sx', 1), p.get('sy', 1))
    bx, by = p.get('bx', 0), p.get('by', 0)
    bas.rotation_euler = (math.radians(-6 * by) + p.get('bas_nod', 0), p.get('bas_egim', 0), math.radians(-22 * bx))
    for bk in bebek_kok:
        bk.location = DINLENME[bk.name][0] + Vector((0.03 * bx, -0.004, -0.035 * by))
    y = p.get('yuz', {})
    g, sev, kah = y.get('gulus', 0), y.get('sevinc', 0), y.get('kahkaha', 0)
    kap, ao, kiz = y.get('kapak', 0), y.get('agizO', 0), y.get('kizarma', 0)
    acik = 1 - max(kap, sev)
    for gk in goz_kok:
        olc(gk, 1 + 0.08 * (1 - acik), 1, max(acik, 0.0) * (1 - 0.0))
    for sk in sevinc_goz:
        olc(sk, 0.6 + 0.4 * sev, 1, sev)
        if sev < 0.05:
            olc(sk, 0)
    kapali = kap * (1 - sev)
    for kp in kapali_goz:
        olc(kp, 0.6 + 0.4 * kapali, 1, kapali)
        if kapali < 0.05:
            olc(kp, 0)
    for yk in yanaklar:
        olc(yk, 1 + 0.3 * kiz, 1, 1 + 0.35 * kiz)
    taban_rengi(yanak_m, karis(YANAK_A, YANAK_B, kiz))
    egri_guncelle(agiz, gulus_noktalari(g))
    agiz.data.bevel_depth = 0.018 * (1 - ss(ao * 1.6))
    agiz.hide_render = ao > 0.6
    olc(agiz_d, 0.7 + 0.3 * kah, 1, kah)
    olc(agiz_o, 0.75 + 0.25 * ao, 1, ao)
    # Kulaklar: yayılma (fiziksel ikincil hareket) ve hafif ileri-geri.
    ky, kx = p.get('kulak', 0.0), p.get('kulakX', 0.0)
    for i, kk in enumerate(kulak_kok):
        yon = -1 if i == 0 else 1
        kk.rotation_euler = (kx, KULAK_K * (yon * ky + p.get('aci_kulak', 0)), 0)
    if kuyruk_kok is not None:
        kuyruk_kok.rotation_euler = (0, -0.5 * ky + 1.5 * p.get('aci_kulak', 0), 0)
    bitki.rotation_euler = (p.get('bitki_nod', 0), BITKI_EGIM + p.get('bitki_salinim', 0), 0)
    # Bitki: f (filiz), c (çiçek), yl (yıldız) 0..1,15.
    f, c, yl = p.get('bitki', (0, 0, 0))
    olc(filiz_kok, f)
    sap_boy = SAP0 + 4 * U * min(c, 1.1)
    egri_guncelle(sap, sap_noktalari(sap_boy))
    cicek_kok.location = DINLENME['cicek_kok'][0] + Vector((0, 0, sap_boy - SAP0))
    olc(cicek_kok, c * (f > 0.02))
    yy = min(max(yl, 0), 1)
    taban_rengi(tac_m, karis(TAC_A, TAC_B, yy))
    olc(gobek, 1 if yy < 0.5 else 0)
    olc(yildiz_kok, 0.6 + 0.4 * yy if yy >= 0.5 else 0)
    for pk in piriltilar:
        olc(pk, yy)
    # Paralar.
    for i, pk in enumerate(paralar):
        pp = (p.get('paralar') or [None] * 3)[i]
        if pp is None:
            olc(pk, 0)
            continue
        bpy.context.view_layer.update()
        hedef = agiz_o.matrix_world.translation + Vector((0, -0.04, 0))
        bas_ = Vector((hedef.x + 0.05 * (i - 1), hedef.y, 3.5))
        pk.location = bas_ + (hedef - bas_) * (pp ** 2)
        pk.rotation_euler = (0, 0, pp * math.radians(540))
        olc(pk, 1 - ss((pp - 0.82) / 0.18) * 0.85)
    # Katman: bitki ayrı render (gövde onu örterse görünmez olsun diye holdout).
    for o in sc.objects:
        if o.type not in {'MESH', 'CURVE'}:
            continue
        bitkide = o.name in BITKI_NESNELERI
        parada = o.name in PARA_NESNELERI
        if katman == 'govde' and (bitkide or parada):
            o.hide_render = True
        if katman == 'beden' and bitkide:
            o.hide_render = True
        kostumde = o.name in KOSTUM_NESNELERI
        if kostumde and katman != 'kostum':
            o.hide_render = True
        if katman == 'kostum' and (bitkide or parada):
            o.hide_render = True
        o.is_holdout = (katman == 'bitki' and not bitkide) or (katman == 'para' and not parada) or (
            katman == 'kostum' and not kostumde)


# ── Zaman çizelgeleri (karakter.dart ile aynı) ────────────────────────────
def zarf(t, gir=.15, cik=.2):
    if t <= 0 or t >= 1:
        return 0.0
    return min(ss(t / gir), ss((1 - t) / cik))


def zipla(t, h):
    hz, inis = .18, .74
    if t <= 0 or t >= 1:
        return 0.0, 1.0, 1.0
    if t < hz:
        c = math.sin(t / hz * math.pi)
        return 0.0, 1 + .16 * c, 1 - .2 * c
    if t < inis:
        u = (t - hz) / (inis - hz)
        uz = .16 * math.sin(u * math.pi) * (1 - u) * 1.6
        return h * 4 * u * (1 - u), 1 - uz * .7, 1 + uz
    v = (t - inis) / (1 - inis)
    yay = math.sin(v * math.pi * 2.5) * (1 - v) ** 2
    return 0.0, 1 + .18 * yay, 1 - .2 * yay


def sevinc_yuzu(e, kahkaha=1.0):
    return dict(gulus=e, sevinc=e, kahkaha=e * kahkaha, kizarma=e)


def ust(a, b):
    k = set(a) | set(b)
    return {x: max(a.get(x, 0), b.get(x, 0)) for x in k}


def easeInOut(x):
    # Flutter Curves.easeInOut = Cubic(0.42, 0, 0.58, 1)
    return kubik(0.42, 0.0, 0.58, 1.0, x)


def easeOut(x):
    return kubik(0.0, 0.0, 0.58, 1.0, x)


def kubik(a, b, c, d, x):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    lo, hi = 0.0, 1.0
    for _ in range(40):
        m = (lo + hi) / 2
        bx = 3 * a * m * (1 - m) ** 2 + 3 * c * m * m * (1 - m) + m ** 3
        lo, hi = (m, hi) if bx < x else (lo, m)
    m = (lo + hi) / 2
    return 3 * b * m * (1 - m) ** 2 + 3 * d * m * m * (1 - m) + m ** 3


YEME_PARA = [0.0, 0.16, 0.32]
YEME_DUSUS = 0.24
YEME_SEVINC = 0.66


def yeme_yuzu(t):
    o = 0.0
    for b in YEME_PARA:
        p = (t - b) / YEME_DUSUS
        o = max(o, ss((p - .35) / .25) * (1 - ss((p - 1) / .2)))
    u = min(max((t - YEME_SEVINC) / (1 - YEME_SEVINC), 0), 1)
    return ust(dict(agizO=o), sevinc_yuzu(zarf(u, gir=.12, cik=.3)))


def yeme_bakis(t):
    y = -ss(t / .06)
    for b in YEME_PARA:
        x = (t - (b + YEME_DUSUS)) / .06
        if -1 < x < 1:
            y += 1.3 * (math.cos(x * math.pi) + 1) / 2
    return y * (1 - ss((t - .58) / .08))


def yeni_parca(gecis):
    t = min(max(gecis, 0), 1)
    return easeOut(t / .7) * 1.15 if t < .7 else 1.15 - .15 * easeInOut(min(max((t - .7) / .3, 0), 1))


EVRELER = ['minik', 'filiz', 'cicek', 'yildiz']


def bitki_degerleri(evre, gecis=1.0):
    """evre: 'filiz' ya da geçiş 'filiz>cicek'. gecis: evreSahnesi.gecis."""
    if '>' in evre:
        once, sonra = (EVRELER.index(e) for e in evre.split('>'))
    else:
        once = sonra = EVRELER.index(evre)
    v = []
    for parca in (1, 2, 3):
        if sonra < parca:
            v.append(0.0)
        elif once < parca:
            v.append(yeni_parca(gecis))
        else:
            v.append(1.0)
    return tuple(v)


def evre_sahnesi(t):
    comel = math.sin(math.pi * t / .28) if t < .28 else 0.0
    u = min(max((t - .22) / (.5 - .22), 0), 1)
    asma = .07 * math.sin(math.pi * ((t - .22) / (.78 - .22))) * (1 - u * .5) if .22 < t < .78 else 0.0
    sx = 1 + .08 * comel + asma * .8
    sy = 1 - .1 * comel + asma
    merak = zarf(t / .32, gir=.3, cik=.3)
    sev = zarf((t - .3) / .7, gir=.15, cik=.25)
    bakis_y = -ss(t / .12) * (1 - ss((t - .55) / .1))
    return ss(u), sx, sy, bakis_y, ust(dict(agizO=merak * .6), sevinc_yuzu(sev, kahkaha=.9))


RUH_GULUS = {'mutlu': 1.0, 'duz': 0.4, 'bulutlu': 0.1}


def sahne_pozlari(ad, evre, ruh='mutlu'):
    """Sahnenin kare pozları. Döner: (kare sayısı, poz listesi, döngü mü)."""
    sureler = {'nefes': 3.4, 'nefes_kirp': 3.4, 'bulutlu': 3.4, 'bulutlu_kirp': 3.4, 'dokunma': .72, 'yeme': 1.4, 'arti': 1.5,
               'evre': 2.4, 'teselli': 2.6, 'kipir': 1.3, 'ziplama': 1.3, 'gerinme': 1.3, 'keyif': 1.3, 'etrafa_bak': 1.3,
               'dans': 1.3}
    sure = sureler[ad]
    n = round(sure * FPS)
    dongu = ad.startswith(('nefes', 'bulutlu'))
    taban = RUH_GULUS['bulutlu' if ad.startswith('bulutlu') else ruh]
    pozlar = []
    for k in range(n):
        t = k / n if dongu else k / (n - 1)
        y, sx, sy, aci, bx, by = 0.0, 1.0, 1.0, 0.0, 0.0, 0.0
        donus = 0.0
        yuz = {}
        bitki_ = bitki_degerleri(evre.split('>')[-1] if '>' in evre and ad != 'evre' else evre)
        paralar_ = [None] * 3

        def zp(tt, h):
            nonlocal y, sx, sy
            a, b, c = zipla(tt, h)
            y += a
            sx *= b
            sy *= c

        if dongu:
            # Nefes: tam döngü (yüksel–in), uygulamadaki easeInOut salınım.
            nf = (1 - math.cos(2 * math.pi * t)) / 2
            y += 4 * nf * 0.6
            sx -= .012 * nf
            sy += .02 * nf
            if ad.endswith('_kirp'):
                kt = (t - .42) * sure / .18
                if 0 < kt < 1:
                    yuz = ust(yuz, dict(kapak=math.sin(kt * math.pi)))
        elif ad == 'dokunma':
            zp(t, 16)
            kt = min(t * .72 / .7, 1)
            aci += .09 * math.sin(kt * math.pi * 4) * (1 - kt)
            yuz = ust(yuz, sevinc_yuzu(zarf(kt, gir=.12, cik=.35), kahkaha=.7))
        elif ad == 'kipir':
            aci += .06 * math.sin(t * math.pi * 4) * (1 - t)
        elif ad == 'ziplama':
            zp(t, 9)
            yuz = ust(yuz, dict(kapak=.8 * kirp(t, .8, .14)))
        elif ad == 'gerinme':
            g = math.sin(math.pi * easeInOut(t))
            sy += .09 * g
            sx -= .05 * g
            e = zarf(t, gir=.3, cik=.3)
            yuz = ust(yuz, dict(kapak=e, agizO=e * .9))
        elif ad == 'keyif':
            e = zarf(t, gir=.2, cik=.25)
            yuz = ust(yuz, dict(gulus=e, sevinc=e, kizarma=.5 * e))
            aci += .07 * math.sin(t * math.pi) * math.sin(t * math.pi * 3)
        elif ad == 'etrafa_bak':
            d = -math.sin(t * 2 * math.pi) if t < .5 else math.sin((t - .5) * 2 * math.pi)
            bx, by = d, -.2 * abs(d)
            aci += .05 * d
            # Baş yön değiştirirken kırpar (canlılık; animatörlerin klasik hilesi).
            yuz = ust(yuz, dict(kapak=kirp(t, .5, .12)))
        elif ad == 'dans':
            yarim = t * 2 if t < .5 else (t - .5) * 2
            zp(yarim, 6)
            aci += (-.08 if t < .5 else .08) * math.sin(yarim * math.pi)
            yuz = ust(yuz, dict(gulus=zarf(t)))
        elif ad == 'yeme':
            c = 0.0
            for b in YEME_PARA:
                x = (t - (b + YEME_DUSUS)) / .07
                if 0 < x < 1:
                    c = max(c, math.sin(x * math.pi))
            sx += .07 * c
            sy -= .07 * c
            by = yeme_bakis(t)
            yuz = ust(yuz, yeme_yuzu(t))
            u = min(max((t - YEME_SEVINC) / (1 - YEME_SEVINC), 0), 1)
            if u > 0:
                zp(u, 22)
            for i, b in enumerate(YEME_PARA):
                pp = (t - b) / YEME_DUSUS
                paralar_[i] = pp if 0 < pp < 1 else None
        elif ad == 'arti':
            zp(t / .55, 20) if t < .55 else zp((t - .55) / .45, 10)
            # Önce kısa bir şaşkınlık ("o"), sonra sevinç; ikinci sıçrayışta
            # kendi etrafında bir tur (3D'nin 2D'ye kattığı an).
            sasma = zarf(t / .2, gir=.3, cik=.4)
            yuz = ust(yuz, ust(dict(agizO=sasma), sevinc_yuzu(zarf((t - .1) / .9, gir=.1, cik=.25))))
            if t > .55:
                u = (t - .55) / .45
                d_ = min(max((u - .12) / .62, 0), 1)
                donus = 2 * math.pi * easeInOut(d_)
        elif ad == 'evre':
            gecis, esx, esy, eby, eyuz = evre_sahnesi(t)
            sx *= esx
            sy *= esy
            by = min(by, eby)
            yuz = ust(yuz, eyuz)
            u = (t - .52) / (.92 - .52)
            if 0 < u < 1:
                zp(u, 14)
            bitki_ = bitki_degerleri(evre, gecis)
        elif ad == 'teselli':
            taban = RUH_GULUS['bulutlu']
            gunes = easeOut(min(t / .15, 1)) * (1 - kubik(0.42, 0, 1, 1, min(max((t - .75) / .25, 0), 1)))
            taban = taban + (1 - taban) * gunes
        yuz = ust(dict(gulus=taban), yuz)
        pozlar.append(dict(y=y, sx=sx, sy=sy, aci=aci, bx=bx, by=by, yuz=yuz, bitki=bitki_, paralar=paralar_, donus=donus))
    kulak_fizigi(pozlar, dongu)
    ikincil_hareket(pozlar, dongu)
    return pozlar, dongu


def kulak_fizigi(pozlar, dongu):
    """Kulaklar gövdenin dikey ivmesine ve eğilmesine gecikmeyle uyar (yaylı sönüm)."""
    n = len(pozlar)
    dt = 1 / FPS
    h = [(p['y'] * U + 1.12 * p['sy']) for p in pozlar]
    aci = [p['aci'] for p in pozlar]
    tekrar = 3 if dongu else 1
    w, z, G = 2 * math.pi * 3.2, .32, .05
    phi = v = 0.0
    th = vt = 0.0
    sonuc = [None] * n
    for tur in range(tekrar):
        for k in range(n):
            if dongu:
                a = (h[(k + 1) % n] - 2 * h[k] + h[k - 1]) / dt ** 2
                da = (aci[(k + 1) % n] - aci[k - 1]) / (2 * dt)
            else:
                a = (h[min(k + 1, n - 1)] - 2 * h[k] + h[max(k - 1, 0)]) / dt ** 2
                da = (aci[min(k + 1, n - 1)] - aci[max(k - 1, 0)]) / (2 * dt)
            for _ in range(4):
                s = dt / 4
                acc = -w * w * phi - 2 * z * w * v + G * a
                v += acc * s
                phi += v * s
                acct = -w * w * th - 2 * z * w * vt - .25 * da * w
                vt += acct * s
                th += vt * s
            sonuc[k] = (max(min(phi, math.radians(32)), math.radians(-14)), max(min(th, .3), -.3))
    for p, (ph, t) in zip(pozlar, sonuc):
        p['kulak'] = ph
        p['aci_kulak'] = t
        p['kulakX'] = 0.0


def yay(girdi, w, z, dongu):
    """Sönümlü yay: girdi (kuvvet dizisi) → sapma dizisi. Döngüde üç tur ısınır."""
    n, dt = len(girdi), 1 / FPS
    x = v = 0.0
    out = [0.0] * n
    for _ in range(3 if dongu else 1):
        for k in range(n):
            for _ in range(4):
                s = dt / 4
                v += (-w * w * x - 2 * z * w * v + girdi[k]) * s
                x += v * s
            out[k] = x
    return out


def ikincil_hareket(pozlar, dongu):
    """Takip eden hareket (2026-10-17, "göz alıcı"): baş gövdenin eğilmesini ve
    iniş-kalkışını bir adım geriden izler, tepedeki bitki daha da geriden ve
    yumuşak salınır. Böylece gövde durduğunda hareket bir an daha yaşar."""
    n, dt = len(pozlar), 1 / FPS
    def tur(dizi, k):
        a, b = (k - 1) % n if dongu else max(k - 1, 0), (k + 1) % n if dongu else min(k + 1, n - 1)
        return (dizi[b] - dizi[a]) / (2 * dt)
    h = [p['y'] * U + 1.12 * p['sy'] for p in pozlar]
    aci = [p['aci'] for p in pozlar]
    hiz = [tur(h, k) for k in range(n)]
    ivme = [tur(hiz, k) for k in range(n)]
    ah = [tur(aci, k) for k in range(n)]
    w1, w2 = 2 * math.pi * 4.0, 2 * math.pi * 2.6
    egim = yay([-1.6 * a * w1 for a in ah], w1, .35, dongu)
    nod = yay([.035 * a for a in ivme], w1, .4, dongu)
    sal = yay([-2.2 * a * w2 for a in ah], w2, .22, dongu)
    snod = yay([.05 * a for a in ivme], w2, .25, dongu)
    for k, p in enumerate(pozlar):
        p['bas_egim'] = max(min(egim[k], .18), -.18)
        p['bas_nod'] = max(min(nod[k], .12), -.12)
        p['bitki_salinim'] = max(min(sal[k], .45), -.45)
        p['bitki_nod'] = max(min(snod[k], .3), -.3)


def kirp(t, merkez, sure):
    """Göz kırpma (yerel t ile): merkezde tam kapalı, [sure] boyunca."""
    x = (t - merkez) / sure + .5
    return math.sin(x * math.pi) if 0 < x < 1 else 0.0


def render_ayar(boyut, ornek):
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = ornek
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 4
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = boyut
    sc.render.use_persistent_data = True
    sc.view_settings.view_transform = 'Khronos PBR Neutral'
    sc.view_settings.look = 'None'
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'


# Atlas ifadeleri: (ad, yüz, bakış x, bakış y). Uygulamadaki Yuz alanlarıyla
# aynı adlar; Flutter taban gülüşe göre mutlu/duz/bulutlu arasında, üstüne
# o/sevinc/kirp/esne opaklıkla karıştırır, bakışı orta↔sol/sag/yukari ile.
ATLAS = [
    ('mutlu', dict(gulus=1), 0, 0),
    ('duz', dict(gulus=.4), 0, 0),
    ('bulutlu', dict(gulus=.1), 0, 0),
    ('mutlu_sol', dict(gulus=1), -1, 0),
    ('mutlu_sag', dict(gulus=1), 1, 0),
    ('mutlu_yukari', dict(gulus=1), 0, -1),
    ('o', dict(gulus=.5, agizO=1), 0, 0),
    ('o_sol', dict(gulus=.5, agizO=1), -1, 0),
    ('o_sag', dict(gulus=.5, agizO=1), 1, 0),
    ('o_yukari', dict(gulus=.5, agizO=1), 0, -1),
    ('sevinc', dict(gulus=1, sevinc=1, kahkaha=.8, kizarma=1), 0, 0),
    ('kirp', dict(gulus=1, kapak=1), 0, 0),
    ('esne', dict(kapak=1, agizO=.9), 0, 0),
]


def arg(ad, vars_):
    if ad in sys.argv:
        return sys.argv[sys.argv.index(ad) + 1]
    return vars_


if __name__ == '__main__':
    kip = sys.argv[1]
    evre = arg('--evre', 'yildiz')
    katman = arg('--katman', 'hepsi')
    if kip == 'atlas':
        # Uygulama atlası: durağan ifadeler (Flutter karıştırarak oynatır).
        klasor = sys.argv[2]
        kamera('uygulama')
        render_ayar(int(arg('--boyut', '360')), int(arg('--ornek', '16')))
        for ad, yuz, bx, by in ATLAS:
            poz_uygula(dict(yuz=yuz, bitki=bitki_degerleri(evre), bx=bx, by=by), katman)
            sc.render.filepath = f'{klasor}/{ad}.png'
            bpy.ops.render.render(write_still=True)
        sys.exit(0)
    if kip == 'poz':
        cikti = sys.argv[2]
        kamera('poz')
        render_ayar(int(arg('--boyut', '1024')), int(arg('--ornek', '64')))
        yuzler = {'sevinc': sevinc_yuzu(1, .8), 'mutlu': dict(gulus=1), 'kirp': dict(gulus=1, kapak=1),
                  'o': dict(gulus=1, agizO=1), 'bulutlu': dict(gulus=.1)}
        poz = dict(yuz=yuzler[arg('--yuz', 'mutlu')], bitki=bitki_degerleri(evre), bx=float(arg('--bx', '0')))
        poz_uygula(poz, katman)
        sc.render.filepath = cikti
        bpy.ops.render.render(write_still=True)
    else:
        ad, klasor = sys.argv[2], sys.argv[3]
        kamera(arg('--kamera', 'sahne'))
        render_ayar(int(arg('--boyut', '512')), int(arg('--ornek', '40')))
        pozlar, _ = sahne_pozlari(ad, evre, arg('--ruh', 'mutlu'))
        a, b = (int(x) for x in arg('--kare', f'0-{len(pozlar) - 1}').split('-'))
        evre_ad = evre.replace('>', '-')
        for k in range(a, b + 1):
            p = pozlar[k]
            p['aci'] = p['aci']
            poz_uygula(p, katman)
            sc.render.filepath = f'{klasor}/{KARAKTER}_{evre_ad}_{ad}_{katman}_{k + 1:04d}.png'
            bpy.ops.render.render(write_still=True)
