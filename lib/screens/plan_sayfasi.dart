import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/plan.dart';
import '../models/cikartma.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

/// "Benim planım" alt sayfası (bkz. [PlanSablon]): üç cümleden biri seçilir,
/// seçince kaydedilir ve kapanır. Uzun cümle çipe sığmadığı için satır.
Future<void> planGoster(BuildContext context, VarlikTuru tur) => altSayfaGoster<void>(context, _PlanSayfasi(tur: tur));

class _PlanSayfasi extends ConsumerWidget {
  const _PlanSayfasi({required this.tur});
  final VarlikTuru tur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final ad = l.karakter(tur);
    final secili = ref.watch(planlarProvider)[tur];

    Future<void> sec(PlanSablon p) async {
      await ref.read(planlarProvider.notifier).koy(tur, p);
      ref.read(dokunsalProvider).cal(Dokunus.onay);
      if (context.mounted) Navigator.of(context).pop();
    }

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
          Row(children: [
            Karakter(tur: tur, ruh: Ruh.mutlu, boyut: 64, kostum: ref.watch(cikartmalarProvider).contains(Cikartma.kostum(tur))),
            const SizedBox(width: Bosluk.m),
            Expanded(child: Text(l.planBaslik, style: context.t.titleLarge)),
          ]),
          const SizedBox(height: Bosluk.s),
          Text(l.planSayfaAlt, style: context.t.bodyMedium?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.l),
          for (final p in PlanSablon.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Bosluk.s),
              child: Semantics(
                selected: secili == p,
                child: Kart(
                  onTap: () => sec(p),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(children: [
                      // Seçili olan yalnız renkle değil, işaretle de ayrılır.
                      Icon(
                        secili == p ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: secili == p ? r.acc : r.sub,
                      ),
                      const SizedBox(width: Bosluk.m),
                      Expanded(child: Text(l.planCumle(p.name, ad), style: context.t.titleMedium)),
                    ]),
                  ),
                ),
              ),
            ),
          if (secili != null) ...[
            const SizedBox(height: Bosluk.m),
            AnaDugme(
              metin: l.planKaldir,
              ikincil: true,
              onTap: () async {
                await ref.read(planlarProvider.notifier).kaldir(tur);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}
