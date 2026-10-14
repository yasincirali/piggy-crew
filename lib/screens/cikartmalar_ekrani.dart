import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/cikartma.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

/// Çıkartmalar: davranış rozetleri; kilitliler soluk ama görünür (hedef belli).
class CikartmalarEkrani extends ConsumerWidget {
  const CikartmalarEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final acik = ref.watch(cikartmalarProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
      children: [
        Text(l.cikartmaBaslik, style: context.t.headlineMedium),
        const SizedBox(height: Bosluk.xs),
        Text(l.cikartmaAlt, style: context.t.bodyMedium),
        const SizedBox(height: Bosluk.s),
        Text(l.cikartmaSayac(acik.length, Cikartma.hepsi.length), style: context.t.labelLarge?.copyWith(color: r.sub)),
        const SizedBox(height: Bosluk.l),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Bosluk.m,
            crossAxisSpacing: Bosluk.m,
            childAspectRatio: .92,
          ),
          itemCount: Cikartma.hepsi.length,
          itemBuilder: (_, i) {
            final c = Cikartma.hepsi[i];
            final var_ = acik.contains(c.id);
            return Semantics(
              label: '${l.cikartmaAd(c)}${var_ ? '' : ', ${l.cikartmaKilitli}'}',
              child: Kart(
                padding: const EdgeInsets.all(Bosluk.m),
                child: Opacity(
                  opacity: var_ ? 1 : .45,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (c.tur != null)
                      Karakter(tur: c.tur!, ruh: var_ ? Ruh.mutlu : Ruh.duz, boyut: 64)
                    else
                      Icon(var_ ? Icons.local_fire_department_rounded : Icons.lock_rounded, size: 48, color: var_ ? r.petal : r.sub),
                    const SizedBox(height: Bosluk.s),
                    Text(l.cikartmaAd(c), textAlign: TextAlign.center, style: context.t.titleMedium),
                    const SizedBox(height: Bosluk.xs),
                    Text(l.cikartmaAciklama(c), textAlign: TextAlign.center, style: context.t.bodySmall?.copyWith(color: r.sub)),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
