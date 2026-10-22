import '../l10n/generated/app_localizations.dart';
import 'cikartma.dart';
import 'cocuk.dart';
import 'varlik.dart';

/// Veli onaylı geri bildirim (Ar-Ge raporu 2026-10-23 #3). Analitik yok
/// (Kids kategorisi); yol haritasının en büyük açığı gerçek ailenin sesi.
/// Tek yol: veli, cihazda ZATEN saklanan birkaç sayıyı ve kendi cevaplarını
/// görür, isterse kendisi paylaşır.
///
/// Neden yeni sayaç yok: ekran açılışı saymak yeni bir izleme kodu olurdu;
/// Kids'te kötü görünür ve veri gerçekten de cihazda kalmazdı. Neden ad ve
/// tutar yok: ikisi de çocuğa/aileye dair; geri bildirim için gerekmez
/// (`geri_bildirim_test` metinde ikisinin de olmadığını kilitler).
String geriBildirimMetni({
  required AppLocalizations l,
  required Cocuk cocuk,
  required List<Hareket> hareketler,
  required int odun,
  required int ders,
  required int cikartma,
  required bool ucBoyut,
  required String? surum,
  required String dil,
  required DateTime simdi,
  List<String> cevaplar = const [],
}) {
  final gunler = hareketler.beslemeler.map((h) => DateTime(h.tarih.year, h.tarih.month, h.tarih.day)).toSet().length;
  final satirlar = <(String, String)>[
    (l.gbSurum, surum ?? '?'),
    (l.gbDil, dil),
    (l.gbPara, cocuk.para.kod),
    (l.gbYas, cocuk.yas.etiket),
    (l.gbGorunum, ucBoyut ? '3D' : '2D'),
    (l.gbKurulu, '${simdi.difference(cocuk.olusturma).inDays}'),
    (l.gbGun, '$gunler'),
    (l.gbOdun, '$odun'),
    (l.gbCikis, '${hareketler.where((h) => h.cikis).length}'),
    (l.gbDers, '$ders'),
    (l.gbCikartma, '$cikartma/${Cikartma.hepsi.length}'),
  ];
  final sorular = [l.geriBildirimSoru1, l.geriBildirimSoru2, l.geriBildirimSoru3];
  final b = StringBuffer()..writeln(l.geriBildirimKonu)..writeln();
  for (final (k, v) in satirlar) {
    b.writeln('$k: $v');
  }
  for (var i = 0; i < sorular.length; i++) {
    final c = i < cevaplar.length ? cevaplar[i].trim() : '';
    if (c.isEmpty) continue;
    b
      ..writeln()
      ..writeln(sorular[i])
      ..writeln(c);
  }
  return b.toString().trimRight();
}
