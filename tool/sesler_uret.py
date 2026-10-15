"""Harçlıklarım ses efektlerini sıfırdan sentezler → assets/sesler/*.wav

Neden sentez, neden hazır ses paketi değil: lisans derdi yok (her örnek bu
betikten çıkar), boyut küçük (toplam ~300 KB) ve karakter sesleri Kumbara
Takımı'na göre ayarlanabilir. Değiştirmek için parametreyi düzelt, yeniden
çalıştır: `python3 tool/sesler_uret.py` (numpy gerekir).

Ses dili: kısa (≤0,6 sn), yumuşak atak, tepe −6 dBFS; çocuk kulağına sert
gelmesin, telefon hoparlöründe de duyulsun (200 Hz altına inilmez).
"""

from pathlib import Path
import wave

import numpy as np

SR = 44100
CIKIS = Path(__file__).resolve().parent.parent / "assets" / "sesler"


def t(sure):
    return np.arange(int(SR * sure)) / SR


def zarf(n, atak=0.004, sonum=0.12):
    """Hızlı atak + üstel sönüm."""
    x = np.arange(n) / SR
    a = np.clip(x / atak, 0, 1)
    return a * np.exp(-x / sonum)


def kaydir(f0, f1, sure):
    """f0 → f1 frekans kayması, faz sürekli."""
    f = np.linspace(f0, f1, int(SR * sure))
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def nota(f, sure, sonum=0.18, harmonik=(1.0, 0.35, 0.12)):
    x = t(sure)
    s = sum(a * np.sin(2 * np.pi * f * (i + 1) * x) for i, a in enumerate(harmonik))
    return s * zarf(len(x), sonum=sonum)


def birlestir(*parcalar, aralik=0.0):
    bosluk = np.zeros(int(SR * aralik))
    out = []
    for p in parcalar:
        out += [p, bosluk]
    return np.concatenate(out[:-1]) if out else np.zeros(1)


def yaz(ad, s):
    s = s / (np.max(np.abs(s)) + 1e-9) * 0.5  # −6 dBFS
    kuyruk = int(SR * 0.006)  # sonda tık olmasın
    s[-kuyruk:] *= np.linspace(1, 0, kuyruk)
    CIKIS.mkdir(parents=True, exist_ok=True)
    with wave.open(str(CIKIS / f"{ad}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((s * 32767).astype("<i2").tobytes())


# ── Para: kavanoza düşen bozuk para. İnharmonik iki kısmi + kısa ikinci sekme.
def para():
    x = t(0.32)
    tini = (np.sin(2 * np.pi * 2637 * x) + 0.6 * np.sin(2 * np.pi * 3951 * x)
            + 0.3 * np.sin(2 * np.pi * 5274 * x)) * zarf(len(x), atak=0.001, sonum=0.07)
    sekme = np.zeros_like(tini)
    d = int(SR * 0.07)
    sekme[d:] = 0.45 * tini[: len(tini) - d]
    return tini + sekme


# ── Yum: karakter parayı yutar. Aşağıdan yukarı kayan yumuşak "nom".
def yum():
    a = kaydir(260, 420, 0.09) * zarf(int(SR * 0.09), sonum=0.06)
    b = kaydir(300, 520, 0.11) * zarf(int(SR * 0.11), sonum=0.08)
    return birlestir(a, b, aralik=0.03)


# ── Yaşasın: besleme bitti. Marimba benzeri do-mi-sol-do arpeji.
def yasasin():
    notalar = [523.25, 659.25, 783.99, 1046.5]
    return birlestir(*[nota(f, 0.16 if i < 3 else 0.34, sonum=0.1 if i < 3 else 0.2,
                            harmonik=(1.0, 0.0, 0.25, 0.0, 0.08))
                       for i, f in enumerate(notalar)], aralik=0.0)


# ── Çıkartma: parıltı. Yüksek, hafif çan dizisi.
def cikartma():
    notalar = [1567.98, 2093.0, 2637.0, 3135.96]
    return birlestir(*[nota(f, 0.12, sonum=0.12, harmonik=(1.0, 0.0, 0.2)) for f in notalar], aralik=0.0)


# ── Karakter sesleri (dokununca). Her biri karakterin kişiliğine göre.
def tortu():
    """Kaplumbağa: alçak, ağır, tok iki 'bup'."""
    a = kaydir(240, 200, 0.16) * zarf(int(SR * 0.16), atak=0.012, sonum=0.1)
    b = kaydir(220, 180, 0.2) * zarf(int(SR * 0.2), atak=0.012, sonum=0.12)
    return birlestir(a, b, aralik=0.06)


def zipzip():
    """Tavşan: yaylı 'boing', titreşimli yükselen ton."""
    x = t(0.38)
    f = 420 + 520 * (1 - np.exp(-x / 0.05)) + 40 * np.sin(2 * np.pi * 22 * x)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR)
    return s * zarf(len(x), atak=0.003, sonum=0.14)


def baykus():
    """Baykuş: yumuşak 'hu-huu' (nefesli, iki ton)."""
    rng = np.random.default_rng(7)

    def hu(f, sure):
        x = t(sure)
        ton = np.sin(2 * np.pi * f * x) + 0.2 * np.sin(2 * np.pi * 2 * f * x)
        nefes = rng.normal(0, 0.08, len(x))
        z = np.sin(np.pi * np.clip(x / sure, 0, 1)) ** 1.5
        return (ton + nefes) * z

    return birlestir(hu(440, 0.16), hu(392, 0.3), aralik=0.05)


def sincap():
    """Sincap: hızlı iki cıvıltı."""
    a = kaydir(1300, 1900, 0.06) * zarf(int(SR * 0.06), atak=0.002, sonum=0.04)
    return birlestir(a, a, a * 0.8, aralik=0.035)


if __name__ == "__main__":
    for ad, f in {
        "para": para, "yum": yum, "yasasin": yasasin, "cikartma": cikartma,
        "tortu": tortu, "zipzip": zipzip, "baykus": baykus, "sincap": sincap,
    }.items():
        yaz(ad, f())
    for p in sorted(CIKIS.glob("*.wav")):
        print(f"{p.name:14s} {p.stat().st_size / 1024:5.1f} KB")
