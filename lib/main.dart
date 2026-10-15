import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';
import 'providers/saglayicilar.dart';
import 'screens/ana_iskelet.dart';
import 'screens/karsilama_ekrani.dart';
import 'services/depo.dart';
import 'models/varlik.dart';
import 'theme/dunya.dart';
import 'widgets/karakter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Gömülü fontların OFL metni lisans sayfasında görünsün (OFL koşulu).
  LicenseRegistry.addLicense(() async* {
    for (final (ad, dosya) in [('Baloo 2', 'OFL-Baloo2.txt'), ('Nunito', 'OFL-Nunito.txt')]) {
      yield LicenseEntryWithLineBreaks([ad], await rootBundle.loadString('assets/fonts/$dosya'));
    }
  });
  final depo = await Depo.ac();
  runApp(ProviderScope(
    overrides: [depoProvider.overrideWithValue(depo)],
    child: const HarcliklarimApp(),
  ));
}

class HarcliklarimApp extends ConsumerWidget {
  const HarcliklarimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cocuk = ref.watch(cocukProvider);
    return MaterialApp(
      onGenerateTitle: (c) => c.l10n.uygulamaAdi,
      debugShowCheckedModeBanner: false,
      theme: dunyaTemasi(cocuk?.dunya ?? Dunya.bahce),
      locale: cocuk?.dil == null ? null : Locale(cocuk!.dil!),
      supportedLocales: AppLocalizations.supportedLocales,
      // Global: cihaz dili destekleniyorsa o, değilse İngilizce. Flutter'ın
      // varsayılanı listenin ilkine (şablon Türkçe) düşerdi; Japonca telefonda
      // Türkçe açılırdı.
      localeResolutionCallback: (cihaz, destek) => dilCoz(cihaz, destek),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Sincap'ın parasında çocuğun para birimi görünür (global).
      builder: (context, child) => ParaSembolu(sembol: (cocuk?.para ?? ParaBirimi.tryy).sembol, child: child!),
      home: cocuk == null ? const KarsilamaEkrani() : const AnaIskelet(),
    );
  }
}
