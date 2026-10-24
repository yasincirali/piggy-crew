import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cocuk.dart';
import '../models/evre.dart';
import '../models/hedef.dart';
import '../models/odun.dart';
import '../models/varlik.dart';
import '../services/depo.dart';
import '../services/dokunsal.dart';
import '../services/fiyat_servisi.dart';
import '../services/ses_servisi.dart';

/// `main()` içinde override edilir (Depo.ac() async).
final depoProvider = Provider<Depo>((_) => throw UnimplementedError('Depo override edilmeli'));
final fiyatServisiProvider = Provider<FiyatServisi>((_) => FiyatServisi());

/// Sesler açık mı (Ayarlar). Değişince servis de güncellenir.
class SesAcikNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(depoProvider).sesAcikOku();

  Future<void> ayarla(bool v) async {
    state = v;
    ref.read(sesProvider).acik = v;
    await ref.read(depoProvider).sesAcikYaz(v);
  }
}

final sesAcikProvider = NotifierProvider<SesAcikNotifier, bool>(SesAcikNotifier.new);
final sesProvider = Provider<SesServisi>((ref) => SesServisi(acik: ref.read(depoProvider).sesAcikOku()));

/// Titreşim açık mı (Ayarlar). Değişince servis de güncellenir.
class TitresimAcikNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(depoProvider).titresimAcikOku();

  Future<void> ayarla(bool v) async {
    state = v;
    ref.read(dokunsalProvider).acik = v;
    await ref.read(depoProvider).titresimAcikYaz(v);
  }
}

final titresimAcikProvider = NotifierProvider<TitresimAcikNotifier, bool>(TitresimAcikNotifier.new);

/// Karakter görünümü: 3D (deneme) açık mı (veli köşesi).
class Karakter3dNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(depoProvider).karakter3dOku();

  Future<void> ayarla(bool v) async {
    state = v;
    await ref.read(depoProvider).karakter3dYaz(v);
  }
}

final karakter3dProvider = NotifierProvider<Karakter3dNotifier, bool>(Karakter3dNotifier.new);
final dokunsalProvider = Provider<DokunsalServisi>((ref) => DokunsalServisi(acik: ref.read(depoProvider).titresimAcikOku()));

/// Ortak bileşenler (ref'siz) için: ağaçtaki servisle çalar; ProviderScope
/// yoksa (tek bileşen testi) sistemin hafif darbesine düşer.
void dokunsalCal(BuildContext context, Dokunus d) {
  try {
    ProviderScope.containerOf(context, listen: false).read(dokunsalProvider).cal(d);
  } catch (_) {
    HapticFeedback.lightImpact();
  }
}

/// Çocuk profili; null → karşılama akışı.
class CocukNotifier extends Notifier<Cocuk?> {
  @override
  Cocuk? build() => ref.read(depoProvider).cocukOku();

  Future<void> kaydet(Cocuk c) async {
    state = c;
    await ref.read(depoProvider).cocukYaz(c);
  }

  Future<void> guncelle(Cocuk Function(Cocuk) f) async {
    final c = state;
    if (c == null) return;
    await kaydet(f(c));
  }

  /// Veli köşesi "veriyi sil": profil + hareketler + çıkartmalar gider.
  Future<void> hepsiniSil() async {
    await ref.read(depoProvider).hepsiniSil();
    ref.invalidate(hareketlerProvider);
    ref.invalidate(cikartmalarProvider);
    ref.invalidate(hedeflerProvider);
    state = null;
  }
}

final cocukProvider = NotifierProvider<CocukNotifier, Cocuk?>(CocukNotifier.new);

/// Fiyatlar: önce önbellek (anında), sonra ağ. `yenile()` çekmeyi tekrarlar.
class FiyatNotifier extends AsyncNotifier<Fiyatlar> {
  @override
  Future<Fiyatlar> build() async {
    final s = ref.read(fiyatServisiProvider);
    final onb = await s.onbellek();
    // Ağ sonucu geldiğinde state'i güncelle; önbellek varsa bekletme.
    final agFuture = s.cek();
    if (onb.yok) return (await agFuture) ?? onb;
    agFuture.then((f) {
      if (f != null) state = AsyncData(f);
    });
    return onb;
  }

  Future<void> yenile() async {
    final f = await ref.read(fiyatServisiProvider).cek();
    if (f != null) state = AsyncData(f);
  }
}

final fiyatProvider = AsyncNotifierProvider<FiyatNotifier, Fiyatlar>(FiyatNotifier.new);

class HareketlerNotifier extends Notifier<List<Hareket>> {
  @override
  List<Hareket> build() => ref.read(depoProvider).hareketleriOku();

  Future<void> ekle(Hareket h) async {
    state = [...state, h];
    await ref.read(depoProvider).hareketleriYaz(state);
  }

  Future<void> sil(String id) async {
    state = state.where((h) => h.id != id).toList();
    await ref.read(depoProvider).hareketleriYaz(state);
  }
}

final hareketlerProvider = NotifierProvider<HareketlerNotifier, List<Hareket>>(HareketlerNotifier.new);

/// Karakter başına hedef eşya (bkz. [Hedef]).
class HedeflerNotifier extends Notifier<Map<VarlikTuru, Hedef>> {
  @override
  Map<VarlikTuru, Hedef> build() => ref.read(depoProvider).hedefleriOku();

  Future<void> koy(VarlikTuru t, Hedef h) async {
    state = {...state, t: h};
    await ref.read(depoProvider).hedefleriYaz(state);
  }

  Future<void> kaldir(VarlikTuru t) async {
    state = {...state}..remove(t);
    await ref.read(depoProvider).hedefleriYaz(state);
  }

  /// Hedef bu durumla ilk kez dolduysa işaretler ve true döner (sevinç bir kez).
  Future<bool> ulastiysaIsaretle(VarlikTuru t, KarakterDurumu d) async {
    final h = state[t];
    if (h == null || !h.simdiDoldu(d)) return false;
    await koy(t, h.ulas(DateTime.now()));
    return true;
  }
}

final hedeflerProvider = NotifierProvider<HedeflerNotifier, Map<VarlikTuru, Hedef>>(HedeflerNotifier.new);

/// Karakter durumları — hesap burada, build() içinde değil.
final karakterlerProvider = Provider<Map<VarlikTuru, KarakterDurumu>>((ref) {
  final hareketler = ref.watch(hareketlerProvider);
  final fiyatlar = ref.watch(fiyatProvider).valueOrNull ?? Fiyatlar.bos;
  final ev = ref.watch(cocukProvider)?.para ?? ParaBirimi.tryy;
  return {
    for (final t in VarlikTuru.values.where((t) => t.gorunur(ev)))
      t: KarakterDurumu.hesapla(t, hareketler, fiyatlar.fiyat(t, ev)),
  };
});

/// Görünen büyüme evreleri: hesaplanan ile saklanan en yüksek evrenin büyüğü.
/// Evre geri gitmez (besleme silinse de); ulaşılan evre burada saklanır ki
/// hesap düşse de görünen düşmesin.
final evrelerProvider = Provider<Map<VarlikTuru, Evre>>((ref) {
  final depo = ref.read(depoProvider);
  final hesap = evreler(ref.watch(hareketlerProvider));
  final kayitli = depo.evreOku();
  final kayit = {
    for (final t in VarlikTuru.values)
      if (hesap[t] != null || kayitli[t] != null) t: gosterilenEvre(hesap[t], kayitli[t]),
  };
  if (!mapEquals(kayit, kayitli)) depo.evreYaz(kayit);
  return {for (final t in VarlikTuru.values) t: kayit[t] ?? Evre.minik};
});

/// Kamp ateşindeki odun: hesaplanan ile saklananın büyüğü (eksilmez; bkz. [Odun]).
final odunProvider = Provider<int>((ref) {
  final depo = ref.read(depoProvider);
  final kayitli = depo.odunOku();
  final n = Odun.gosterilen(Odun.say(ref.watch(hareketlerProvider)), kayitli);
  if (n != kayitli) depo.odunYaz(n);
  return n;
});

/// Toplam değer; bir karakterin fiyatı bilinmiyorsa o karakter toplamdan
/// DÜŞÜLMEZ, toplam null olur — uydurma toplam en kötü sayıdır.
@immutable
class Toplam {
  const Toplam({required this.degerTl, required this.maliyetTl});
  final double? degerTl;
  final double maliyetTl;
  double? get farkTl => degerTl == null ? null : degerTl! - maliyetTl;
}

final toplamProvider = Provider<Toplam>((ref) {
  final k = ref.watch(karakterlerProvider).values.where((d) => !d.bos);
  double? deger = 0;
  var maliyet = 0.0;
  for (final d in k) {
    maliyet += d.maliyetTl;
    if (deger == null) continue;
    final v = d.degerTl;
    deger = v == null ? null : deger + v;
  }
  return Toplam(degerTl: deger, maliyetTl: maliyet);
});

class CikartmalarNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(depoProvider).cikartmalariOku();

  /// Yeni açıldıysa true döner (kutlama tetikleyici).
  Future<bool> ac(String id) async {
    if (state.contains(id)) return false;
    state = {...state, id};
    await ref.read(depoProvider).cikartmalariYaz(state);
    return true;
  }
}

final cikartmalarProvider = NotifierProvider<CikartmalarNotifier, Set<String>>(CikartmalarNotifier.new);

class DersIlerlemeNotifier extends Notifier<int> {
  @override
  int build() => ref.read(depoProvider).dersIlerlemeOku();

  Future<void> ilerle(int n) async {
    if (n <= state) return;
    state = n;
    await ref.read(depoProvider).dersIlerlemeYaz(n);
  }

  /// Dersler bitince baştan okumak için.
  Future<void> ilerleSifirla() async {
    state = 0;
    await ref.read(depoProvider).dersIlerlemeYaz(0);
  }
}

final dersIlerlemeProvider = NotifierProvider<DersIlerlemeNotifier, int>(DersIlerlemeNotifier.new);
