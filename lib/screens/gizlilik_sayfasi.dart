import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/dunya.dart';
import '../widgets/ortak.dart';

/// Gizlilik politikası, uygulama içinde (App Store 5.1.1: politika mağaza
/// kaydında VE uygulamada kolayca bulunmalı).
///
/// Tek kaynak: mağazaya verilen URL'deki `legal/*.md` dosyasının kendisi
/// paketlenir ve burada düz metin olarak gösterilir; uygulamaya ayrı metin
/// yazılmaz (sandık "yasal metin tek kaynak" kuralı). Dış bağlantı açılmaz,
/// bu yüzden Kids ebeveyn kapısı gerekmez; metindeki bağlantılar yalnız
/// etiketleriyle görünür.
const gizlilikDosyalari = {
  'tr': 'gizlilik',
  'en': 'privacy',
  'de': 'datenschutz',
  'es': 'privacidad',
  'fr': 'confidentialite',
  'pt': 'privacidade',
};

Future<void> gizlilikGoster(BuildContext context) {
  final dil = Localizations.localeOf(context).languageCode;
  final ad = gizlilikDosyalari[dil] ?? gizlilikDosyalari['en']!;
  return altSayfaGoster<void>(context, _GizlilikSayfasi(yol: 'legal/$ad.md'));
}

/// Markdown'ın burada kullanılan küçük alt kümesi: `# başlık`, `**kalın**`,
/// `[etiket](url)`. Sürüm satırındaki dil bağlantıları uygulamada gereksiz.
@visibleForTesting
List<(String, bool)> gizlilikParcalari(String satir) {
  final temiz = satir
      .replaceAll(RegExp(r' · \[.*$'), '')
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!);
  final parcalar = <(String, bool)>[];
  final kalin = RegExp(r'\*\*(.+?)\*\*');
  var i = 0;
  for (final m in kalin.allMatches(temiz)) {
    if (m.start > i) parcalar.add((temiz.substring(i, m.start), false));
    parcalar.add((m[1]!, true));
    i = m.end;
  }
  if (i < temiz.length) parcalar.add((temiz.substring(i), false));
  return parcalar;
}

class _GizlilikSayfasi extends StatelessWidget {
  const _GizlilikSayfasi({required this.yol});
  final String yol;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return FutureBuilder<String>(
      future: rootBundle.loadString(yol),
      builder: (context, s) {
        final satirlar = (s.data ?? '').split('\n').where((x) => x.trim().isNotEmpty).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: r.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: Bosluk.l),
              for (final satir in satirlar) ...[
                if (satir.startsWith('# '))
                  Text(satir.substring(2), style: context.t.titleLarge)
                else
                  Text.rich(
                    TextSpan(children: [
                      for (final (metin, kalin) in gizlilikParcalari(satir))
                        TextSpan(text: metin, style: kalin ? const TextStyle(fontWeight: FontWeight.w700) : null),
                    ]),
                    style: context.t.bodyMedium,
                  ),
                const SizedBox(height: Bosluk.s),
              ],
            ],
          ),
        );
      },
    );
  }
}
