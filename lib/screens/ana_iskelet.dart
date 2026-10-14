import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/dunya.dart';
import '../widgets/ortak.dart';
import 'ayarlar_ekrani.dart';
import 'cikartmalar_ekrani.dart';
import 'kamp_ekrani.dart';
import 'ogren_ekrani.dart';

/// Alt sekmeler: Kamp · Öğren · Çıkartmalar · Ayarlar. Sekme geçişinde
/// animasyon yok (sandık kuralı); içerik anında değişir.
class AnaIskelet extends ConsumerStatefulWidget {
  const AnaIskelet({super.key});
  @override
  ConsumerState<AnaIskelet> createState() => _AnaIskeletState();
}

class _AnaIskeletState extends ConsumerState<AnaIskelet> {
  int _sekme = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    return Scaffold(
      body: DunyaZemini(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _sekme,
            children: const [KampEkrani(), OgrenEkrani(), CikartmalarEkrani(), AyarlarEkrani()],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: r.bg1,
          indicatorColor: r.accSoft,
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? r.fg : r.sub)),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => context.t.labelMedium?.copyWith(color: s.contains(WidgetState.selected) ? r.fg : r.sub, fontWeight: FontWeight.w700),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _sekme,
          onDestinationSelected: (i) => setState(() => _sekme = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.local_fire_department_outlined), selectedIcon: const Icon(Icons.local_fire_department_rounded), label: l.sekmeKamp),
            NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book_rounded), label: l.sekmeOgren),
            NavigationDestination(icon: const Icon(Icons.star_outline_rounded), selectedIcon: const Icon(Icons.star_rounded), label: l.sekmeCikartma),
            NavigationDestination(icon: const Icon(Icons.tune_rounded), selectedIcon: const Icon(Icons.tune_rounded), label: l.sekmeAyarlar),
          ],
        ),
      ),
    );
  }
}
