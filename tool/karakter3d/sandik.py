# Açılış (splash) denemesi: hazine sandığı, tarz B (konturlu çizgi film).
#
# Kullanım: python sandik.py <klasor> [--adim 36] [--boyut 720] [--ornek 16]
# Çıktı: açıklık 0→1.1 süpürmesi, iki katman:
#   arka_NNNN.png  (her şey; iç, kapak, paralar)
#   on_NNNN.png    (yalnız ön duvar + ön kuşaklar + kilit; diğerleri holdout)
# Karakterler uygulamada/sayfada bu iki katmanın arasına çizilir: sandığa
# girerken ön duvarın arkasında kalırlar. Hareket (zıplama, kamera dalışı)
# kompozisyonda; burada yalnız kapak açıklığı ve içteki ışık.
import math
import random
import sys

import bpy
import bmesh
from mathutils import Vector

MUREKKEP = '#2A1B14'
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def renk(h):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), 1)


def malzeme(ad, h, puruz=0.8, emisyon=0.0, metal=0.0):
    m = bpy.data.materials.new(ad)
    m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = renk(h)
    p.inputs['Roughness'].default_value = puruz
    p.inputs['Metallic'].default_value = metal
    if emisyon:
        p.inputs['Emission Color'].default_value = renk(h)
        p.inputs['Emission Strength'].default_value = emisyon
    return m


def tahta(ad, taban, cizgi, sik):
    """Yatay tahta çizgileri (nesne koordinatı Z)."""
    m = malzeme(ad, taban)
    n, l = m.node_tree.nodes, m.node_tree.links
    p = n['Principled BSDF']
    tc = n.new('ShaderNodeTexCoord')
    ay = n.new('ShaderNodeSeparateXYZ')
    l.new(tc.outputs['Object'], ay.inputs[0])
    c = n.new('ShaderNodeMath'); c.operation = 'MULTIPLY'; c.inputs[1].default_value = sik
    l.new(ay.outputs['Z'], c.inputs[0])
    fr = n.new('ShaderNodeMath'); fr.operation = 'FRACT'
    l.new(c.outputs[0], fr.inputs[0])
    s = n.new('ShaderNodeMapRange'); s.interpolation_type = 'SMOOTHSTEP'
    s.inputs['From Min'].default_value = .86; s.inputs['From Max'].default_value = .93
    l.new(fr.outputs[0], s.inputs['Value'])
    k = n.new('ShaderNodeMix'); k.data_type = 'RGBA'
    k.inputs['A'].default_value = renk(taban); k.inputs['B'].default_value = renk(cizgi)
    l.new(s.outputs[0], k.inputs['Factor'])
    l.new(k.outputs['Result'], p.inputs['Base Color'])
    return m


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


def kontur(o, k=0.035):
    o.data.materials.append(ink)
    s = o.modifiers.new('kontur', 'SOLIDIFY')
    s.thickness = k
    s.offset = 1
    s.use_flip_normals = True
    s.material_offset = 1


def kutu(ad, merkez, boyut, m, pah=0.05, cizgi=0.035):
    bpy.ops.mesh.primitive_cube_add(location=merkez)
    o = bpy.context.object
    o.name = ad
    o.scale = [b / 2 for b in boyut]
    bpy.ops.object.transform_apply(scale=True)
    b = o.modifiers.new('pah', 'BEVEL'); b.width = pah; b.segments = 4
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    if cizgi:
        kontur(o, cizgi)
    return o


def yarim_silindir(ad, r, uzunluk, x, m, zolc=0.62, ic=None, cizgi=0.035):
    """Kapak: X ekseninde yarım silindir, menteşe tabanı z=0 düzleminde."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=r, depth=uzunluk, location=(0, 0, 0),
                                        rotation=(0, math.pi / 2, 0))
    o = bpy.context.object
    o.name = ad
    bpy.ops.object.transform_apply(rotation=True)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0),
                           plane_no=(0, 0, -1), clear_outer=True)
    sinir = [e for e in bm.edges if e.is_boundary]
    yeni = bmesh.ops.holes_fill(bm, edges=sinir, sides=0)
    bm.to_mesh(o.data); bm.free()
    o.scale = (1, 1, zolc)
    bpy.ops.object.transform_apply(scale=True)
    o.location.x = x
    o.data.materials.append(m)
    if ic:
        o.data.materials.append(ic)
        for p in o.data.polygons:
            if p.normal.z < -0.9:
                p.material_index = 1
    bpy.ops.object.shade_smooth()
    if cizgi:
        kontur(o, cizgi)
        o.modifiers['kontur'].material_offset = 2 if ic else 1
    return o


# ── Ölçüler ───────────────────────────────────────────────────────────────
W, D, H, T = 2.4, 1.5, 1.05, 0.12  # en, derinlik, yükseklik, duvar
odun = tahta('odun', '#C9813F', '#7A4520', 4.2)
odun_ic = tahta('odun_ic', '#7A4A26', '#4A2A14', 4.2)
altin = malzeme('altin', '#F5B82E', puruz=.35, metal=.6)
koyu = malzeme('koyu', '#3A2410')
para = malzeme('para', '#FFD34D', puruz=.3, metal=.5, emisyon=.25)

on_nesneler = []
taban = kutu('taban', (0, 0, T / 2), (W, D, T), odun)
arka = kutu('arka', (0, D / 2 - T / 2, H / 2), (W, T, H), odun)
on = kutu('on', (0, -D / 2 + T / 2, H / 2), (W, T, H), odun); on_nesneler.append(on)
sol = kutu('sol', (-W / 2 + T / 2, 0, H / 2), (T, D - 2 * T + .02, H), odun)
sag = kutu('sag', (W / 2 - T / 2, 0, H / 2), (T, D - 2 * T + .02, H), odun); on_nesneler.append(sag)
for o in (taban, arka, sol, sag):
    pass
# İç yüzler koyu: iç tarafa ince koyu levhalar.
kutu('ic_arka', (0, D / 2 - T - .005, H / 2 + .02), (W - 2 * T, .01, H - .1), odun_ic, pah=0, cizgi=0)
kutu('ic_sol', (-W / 2 + T + .005, 0, H / 2 + .02), (.01, D - 2 * T, H - .1), odun_ic, pah=0, cizgi=0)
kutu('ic_sag', (W / 2 - T - .005, 0, H / 2 + .02), (.01, D - 2 * T, H - .1), odun_ic, pah=0, cizgi=0)
kutu('ic_on', (0, -D / 2 + T + .005, H / 2 + .02), (W - 2 * T, .01, H - .1), odun_ic, pah=0, cizgi=0)
# Kuşaklar: ön ve yanlarda dikey altın şeritler, altta ve üstte çerçeve.
for x in (-.78, .78):
    on_nesneler.append(kutu(f'kusak_on{x}', (x, -D / 2 - .015, H / 2), (.2, .06, H + .02), altin, pah=.03, cizgi=.02))
    kutu(f'kusak_arka{x}', (x, D / 2 + .015, H / 2), (.2, .06, H + .02), altin, pah=.03, cizgi=.02)
on_nesneler.append(kutu('ust_cerceve_on', (0, -D / 2 - .02, H - .04), (W + .04, .07, .1), altin, pah=.03, cizgi=.02))
on_nesneler.append(kutu('alt_cerceve_on', (0, -D / 2 - .02, .06), (W + .04, .07, .12), altin, pah=.03, cizgi=.02))
on_nesneler.append(kutu('kusak_sag', (W / 2 + .015, 0, H / 2), (.06, .2, H + .02), altin, pah=.03, cizgi=.02))
kutu('kusak_sol', (-W / 2 - .015, 0, H / 2), (.06, .2, H + .02), altin, pah=.03, cizgi=.02)
# Kilit: ön ortada altın levha, gülümseyen anahtar deliği.
kilit = kutu('kilit', (0, -D / 2 - .05, H - .2), (.42, .08, .46), altin, pah=.08, cizgi=.022)
on_nesneler.append(kilit)
bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=.065, depth=.04, location=(0, -D / 2 - .095, H - .15),
                                    rotation=(math.pi / 2, 0, 0))
delik = bpy.context.object; delik.data.materials.append(koyu); on_nesneler.append(delik)
delik2 = kutu('delik2', (0, -D / 2 - .095, H - .25), (.05, .04, .16), koyu, pah=.02, cizgi=0)
on_nesneler.append(delik2)

# Paralar ve taşlar: iç tepecik.
random.seed(7)
tas_renk = ['#7EF0FF', '#FF5D8F', '#D6F26B', '#B79CFF']
tas_m = [malzeme(f'tas{i}', c, puruz=.15, emisyon=.8) for i, c in enumerate(tas_renk)]
for i in range(70):
    u, v = random.uniform(-1, 1), random.uniform(-1, 1)
    x, y = u * (W / 2 - T - .12), v * (D / 2 - T - .12)
    tepe = .62 + .32 * (1 - (u * u * .7 + v * v * .5))
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=.11, depth=.035,
                                        location=(x, y, tepe + random.uniform(-.06, .04)),
                                        rotation=(random.uniform(-.5, .5), random.uniform(-.5, .5), 0))
    o = bpy.context.object; o.data.materials.append(para)
    bpy.ops.object.shade_smooth()
for i in range(7):
    u, v = random.uniform(-.8, .8), random.uniform(-.7, .7)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=.09,
                                          location=(u * (W / 2 - .3), v * (D / 2 - .3), .9 + random.uniform(-.05, .05)))
    o = bpy.context.object; o.data.materials.append(tas_m[i % 4])
    kontur(o, .015)
kutu('dolgu', (0, 0, .4), (W - 2 * T - .02, D - 2 * T - .02, .6), malzeme('dolgu', '#B8860B', emisyon=.3), pah=0, cizgi=0)

# Kapak: menteşe arka üst kenarda.
mentese = bpy.data.objects.new('mentese', None); sc.collection.objects.link(mentese)
mentese.location = (0, D / 2, H)
kapak = yarim_silindir('kapak', D / 2, W + .02, 0, odun, ic=odun_ic)
kapak.location = (0, D / 2 - D / 2, H)
kapak_parcalari = [kapak]
for x in (-.78, .78):
    k = yarim_silindir(f'kapak_kusak{x}', D / 2 + .03, .2, x, altin, cizgi=.02)
    k.location = (x, 0, H)
    kapak_parcalari.append(k)
on_kenar = kutu('kapak_on_kenar', (0, -D / 2 - .02, H + .05), (W + .04, .07, .1), altin, pah=.03, cizgi=.02)
kapak_parcalari.append(on_kenar)
# Kapak üstünde para yuvası (kumbara): koyu yarık.
yuva = kutu('yuva', (0, 0, H + D / 2 * .62 - .005), (.5, .09, .04), koyu, pah=.02, cizgi=0)
yuva_cerceve = kutu('yuva_c', (0, 0, H + D / 2 * .62 - .02), (.64, .2, .05), altin, pah=.03, cizgi=.015)
kapak_parcalari += [yuva, yuva_cerceve]
bpy.context.view_layer.update()
for o in kapak_parcalari:
    mw = o.matrix_world.copy()
    o.parent = mentese
    o.matrix_parent_inverse = mentese.matrix_world.inverted()

# Işık
ic_isik = bpy.data.lights.new('ic', 'POINT'); ic_isik.color = (1, .8, .4); ic_isik.shadow_soft_size = .4
ic_o = bpy.data.objects.new('ic', ic_isik); sc.collection.objects.link(ic_o); ic_o.location = (0, -.2, 1.6)
anah = bpy.data.lights.new('anahtar', 'AREA'); anah.energy = 900; anah.size = 4
a_o = bpy.data.objects.new('anahtar', anah); sc.collection.objects.link(a_o)
a_o.location = (-4, -5, 6); a_o.rotation_euler = (Vector((0, 0, .6)) - a_o.location).to_track_quat('-Z', 'Y').to_euler()
ark = bpy.data.lights.new('kenar', 'AREA'); ark.energy = 700; ark.size = 3; ark.color = (.75, .9, 1)
k_o = bpy.data.objects.new('kenar', ark); sc.collection.objects.link(k_o)
k_o.location = (4, 4, 4); k_o.rotation_euler = (Vector((0, 0, 1)) - k_o.location).to_track_quat('-Z', 'Y').to_euler()
sc.world = bpy.data.worlds.new('dunya'); sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs['Color'].default_value = renk('#9FC7B0')
sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .6

cam_d = bpy.data.cameras.new('kamera'); cam_d.lens = 70
cam = bpy.data.objects.new('kamera', cam_d); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (1.9, -8.2, 4.6)
cam.rotation_euler = (Vector((0, 0, 1.15)) - cam.location).to_track_quat('-Z', 'Y').to_euler()

sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
sc.cycles.samples = int(sys.argv[sys.argv.index('--ornek') + 1]) if '--ornek' in sys.argv else 16
sc.cycles.use_denoising = True; sc.cycles.max_bounces = 4
sc.render.film_transparent = True
boyut = int(sys.argv[sys.argv.index('--boyut') + 1]) if '--boyut' in sys.argv else 720
sc.render.resolution_x = sc.render.resolution_y = boyut
sc.render.use_persistent_data = True
sc.view_settings.view_transform = 'Khronos PBR Neutral'
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'

klasor = sys.argv[1]
adim = int(sys.argv[sys.argv.index('--adim') + 1]) if '--adim' in sys.argv else 36
yalniz = sys.argv[sys.argv.index('--yalniz') + 1] if '--yalniz' in sys.argv else None
tum = [o for o in sc.objects if o.type == 'MESH']
for i in range(adim):
    a = 1.1 * i / (adim - 1)  # açıklık; 1 = 100°, 1.1 = taşma
    mentese.rotation_euler = (-math.radians(100) * a, 0, 0)
    ic_isik.energy = 120 * min(a, 1) ** .7
    if yalniz and str(i) not in yalniz.split(','):
        continue
    for katman in ('arka', 'on'):
        for o in tum:
            o.is_holdout = katman == 'on' and o not in on_nesneler
        sc.render.filepath = f'{klasor}/{katman}_{i:04d}.png'
        bpy.ops.render.render(write_still=True)
