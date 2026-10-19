import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/saglayicilar.dart';
import 'karakter.dart';

/// Uygulamanın üstünde bir kez oynayan açılış sahnesi (bkz. [AcilisSahnesi]).
/// Sahne bitince ağaçtan çıkar; altındaki uygulama baştan beri kurulu olduğu
/// için ışıktan doğrudan ana ekran açılır.
class AcilisKatmani extends ConsumerStatefulWidget {
  const AcilisKatmani({super.key, required this.child, this.oynasin});

  final Widget child;

  /// Test için: null ise testte (`FLUTTER_TEST`) oynamaz, uygulamada oynar.
  /// Var olan testler sahnenin dokunuşu yutmasından etkilenmesin diye.
  final bool? oynasin;

  @override
  ConsumerState<AcilisKatmani> createState() => _AcilisKatmaniState();
}

/// Yerel gün anahtarı (yyyy-aa-gg).
String acilisGunu(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

class _AcilisKatmaniState extends ConsumerState<AcilisKatmani> {
  late bool _oynuyor;
  late final bool _kisa;

  static bool get _testte => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _oynuyor = widget.oynasin ?? !_testte;
    final depo = ref.read(depoProvider);
    final bugun = acilisGunu(DateTime.now());
    _kisa = depo.sonAcilisOku() == bugun;
    if (_oynuyor && !_kisa) depo.sonAcilisYaz(bugun);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_oynuyor)
          Positioned.fill(
            child: AcilisSahnesi(
              kisa: _kisa,
              ses: (s) => ref.read(sesProvider).cal(s),
              titresim: (d) => ref.read(dokunsalProvider).cal(d),
              bitti: () {
                if (mounted) setState(() => _oynuyor = false);
              },
            ),
          ),
      ],
    );
  }
}
