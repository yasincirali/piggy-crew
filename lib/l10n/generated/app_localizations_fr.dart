// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get uygulamaAdi => 'Mon argent de poche';

  @override
  String get karakterAltin => 'Torti';

  @override
  String get karakterDolar => 'Bondi';

  @override
  String get karakterEuro => 'Plume';

  @override
  String get karakterNakit => 'Noisette';

  @override
  String get varlikAltin => 'Or';

  @override
  String get varlikDolar => 'Dollar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Espèces';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'Je marche lentement, mais ma carapace est solide. Les jours difficiles, je tiens bon.';

  @override
  String get huyDolar =>
      'Je saute ! Parfois en haut, parfois en bas. La patience gagne.';

  @override
  String get huyEuro =>
      'J\'observe tranquillement. Je garde l\'argent des pays lointains.';

  @override
  String get huyNakit =>
      'Je garde tout ce que tu me donnes. Mais quand les prix montent, j\'achète moins.';

  @override
  String get karsilamaBaslik => 'L\'équipe Tirelire t\'attend';

  @override
  String get karsilamaAlt =>
      'Quand tu mets de l\'argent dans ta vraie tirelire, donne-le ici à un personnage. Les quatre grandissent avec tes économies et ton feu de camp s\'allume.';

  @override
  String get karsilamaBasla => 'Commencer';

  @override
  String get adSoru => 'Comment on t\'appelle ?';

  @override
  String get adIpucu => 'Ton prénom ou ton surnom';

  @override
  String get yasSoru => 'Quel âge as-tu ?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get dunyaSoru => 'Où installer le camp ?';

  @override
  String get dunyaAlt => 'Tu peux changer quand tu veux.';

  @override
  String get devam => 'Continuer';

  @override
  String get geri => 'Retour';

  @override
  String get veliBaslik => 'Coin des parents';

  @override
  String get veliAciklama =>
      'Ce code PIN à 4 chiffres protège la correction des prix, la suppression des données et les réglages. Les écrans des enfants n\'ont ni publicité, ni notification, ni achat.';

  @override
  String get veliPinIpucu => 'Code PIN à 4 chiffres';

  @override
  String get veliPinTekrar => 'Répète le code PIN';

  @override
  String get veliPinUyusmaz => 'Les codes PIN ne sont pas identiques';

  @override
  String get veliPinSonra => 'Plus tard';

  @override
  String get hazir => 'C\'est parti !';

  @override
  String get sekmeKamp => 'Camp';

  @override
  String get sekmeOgren => 'Apprendre';

  @override
  String get sekmeCikartma => 'Autocollants';

  @override
  String get sekmeAyarlar => 'Réglages';

  @override
  String kampSelam(String ad) {
    return 'Salut $ad';
  }

  @override
  String get kampAtesim => 'Mon feu de camp';

  @override
  String get kampBos =>
      'Ton feu de camp n\'est pas encore allumé. Quand tu mets de l\'argent dans ta tirelire, touche un personnage et donne-le-lui.';

  @override
  String get kampFiyatYok =>
      'Prix indisponibles, la valeur ne peut pas être affichée.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Prix du $zaman';
  }

  @override
  String get fark => 'Différence';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter sourit : $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter est sous un nuage : $fark';
  }

  @override
  String farkDuz(String karakter) {
    return '$karakter est calme : pas de changement';
  }

  @override
  String get besle => 'Nourrir';

  @override
  String besleBaslik(String karakter, String tur) {
    return 'Nourrir $karakter';
  }

  @override
  String get besleTutar => 'Combien ?';

  @override
  String get kupurIpucu => 'Touche l\'argent que tu as en main, ou écris-le.';

  @override
  String kupurEkle(String tutar) {
    return 'Ajouter $tutar';
  }

  @override
  String get kupurGeriAl => 'Annuler';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Aujourd\'hui 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return 'Avec $tutar, tu as $miktar';
  }

  @override
  String besleVer(String karakter) {
    return 'Donner à $karakter';
  }

  @override
  String get besleFiyatYok =>
      'Le prix du jour n\'a pas pu être chargé. Réessaie quand Internet est disponible.';

  @override
  String get besleGecersiz => 'Écris un montant';

  @override
  String besleDoydu(String karakter) {
    return 'Miam ! $karakter a bien mangé.';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'Nouvel autocollant : $ad';
  }

  @override
  String get detayVerdin => 'Tu as donné';

  @override
  String get detayBugun => 'Aujourd\'hui';

  @override
  String detayMiktar(String miktar) {
    return 'Tu as $miktar';
  }

  @override
  String detayBos(String karakter) {
    return 'Pas encore de repas pour $karakter.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter t\'explique';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Depuis ton achat, $varlik a pris de la valeur. La même quantité vaut maintenant plus : $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Depuis ton achat, $varlik est devenu un peu moins cher. Ce n\'est pas ta faute : les prix changent comme la météo. Ta quantité est toujours la même, sa valeur aujourd\'hui est un peu plus basse : $fark. Les nuages passent.';
  }

  @override
  String get detayNedenNakit =>
      'Les espèces montrent toujours le même nombre. Mais quand les prix montent, le même argent achète moins de choses : on appelle ça l\'inflation.';

  @override
  String get detayBeslemeler => 'Tes repas donnés';

  @override
  String get detayBirazDaha => 'Nourrir encore un peu';

  @override
  String get detaySil => 'Supprimer ce repas';

  @override
  String get detaySilOnay => 'Supprimer ce repas ?';

  @override
  String get iptal => 'Annuler';

  @override
  String get sil => 'Supprimer';

  @override
  String get ogrenBaslik => 'Une nouvelle idée';

  @override
  String get ogrenSonraki => 'Leçon suivante';

  @override
  String get ogrenBitti =>
      'Tu as fini toutes les leçons. De nouvelles arrivent.';

  @override
  String get ogrenBastan => 'Relire';

  @override
  String get hatirlaBaslik => 'Tu te souviens ?';

  @override
  String hatirlaSoruyor(String karakter, String kavram) {
    return '$karakter essaie de se souvenir de la leçon $kavram. Tu l\'aides ?';
  }

  @override
  String hatirlaDogru(String karakter) {
    return '$karakter : \"Oui, je m\'en souviens maintenant !\"';
  }

  @override
  String get cikartmaBaslik => 'Mes autocollants';

  @override
  String get cikartmaAlt =>
      'Gagnés grâce à ce que tu fais, pas grâce à la chance.';

  @override
  String get cikartmaKilitli => 'Verrouillé';

  @override
  String get ayarlarBaslik => 'Réglages';

  @override
  String get ayarlarDunya => 'Lieu du camp';

  @override
  String get ayarlarYas => 'Mode d\'âge';

  @override
  String get ayarlarPara => 'Monnaie';

  @override
  String get ayarlarSes => 'Sons';

  @override
  String get sesAcik => 'Activés';

  @override
  String get sesKapali => 'Désactivés';

  @override
  String get ayarlarTitresim => 'Vibrations';

  @override
  String get ayarlarGorunum => 'Apparence des personnages';

  @override
  String get gorunumKlasik => 'Classique';

  @override
  String get gorunum3d => '3D';

  @override
  String get ayarlarDil => 'Langue';

  @override
  String get ayarlarVeli => 'Coin des parents';

  @override
  String ayarlarSurum(String s) {
    return 'Version $s';
  }

  @override
  String get ayarlarKaynak =>
      'Les prix viennent de fournisseurs publics de données de marché et ne sont pas des conseils d\'investissement.';

  @override
  String get dilCihaz => 'Langue de l\'appareil';

  @override
  String get kilitBaslik => 'Saisis le code PIN';

  @override
  String get kilitYanlis => 'Code PIN incorrect';

  @override
  String get kilitKur => 'Créer un code PIN';

  @override
  String get veliSil => 'Supprimer toutes les données';

  @override
  String get veliSilOnay =>
      'Le profil, les repas et les autocollants seront supprimés. Impossible de revenir en arrière.';

  @override
  String get veliSilOnayDugme => 'Oui, supprimer';

  @override
  String get veliYedekNot =>
      'Les données restent uniquement sur ce téléphone et, si elle est activée, dans sa propre sauvegarde (iCloud ou Google). Nous ne voyons pas cette sauvegarde.';

  @override
  String get veliPinDegistir => 'Changer le code PIN';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad a nourri l\'équipe $n fois au total. Feu de camp : $toplam.';
  }

  @override
  String get veliNot =>
      'Les écrans des enfants n\'ont ni notification, ni publicité, ni achat. Les données restent uniquement sur cet appareil.';

  @override
  String get dunyaBahce => 'Jardin';

  @override
  String get dunyaUzay => 'Espace';

  @override
  String get dunyaOkyanus => 'Océan';

  @override
  String get dunyaNeon => 'Néon';

  @override
  String get dunyaSeker => 'Bonbons';

  @override
  String get dunyaSafari => 'Safari';

  @override
  String get ckIlkbeslemeAd => 'Première étincelle';

  @override
  String get ckIlkbeslemeAciklama =>
      'Tu as allumé le feu de camp pour la première fois.';

  @override
  String get ckTortusapkaAd => 'Le chapeau de Torti';

  @override
  String get ckTortusapkaAciklama => 'Tu as nourri Torti trois fois.';

  @override
  String get ckZipzipatkiAd => 'L\'écharpe de Bondi';

  @override
  String get ckZipzipatkiAciklama => 'Tu as nourri Bondi trois fois.';

  @override
  String get ckBaykusgozlukAd => 'Les lunettes de Plume';

  @override
  String get ckBaykusgozlukAciklama => 'Tu as nourri Plume trois fois.';

  @override
  String get ckSincapfularAd => 'Le bandana de Noisette';

  @override
  String get ckSincapfularAciklama => 'Tu as nourri Noisette trois fois.';

  @override
  String get ckTakimtamAd => 'Équipe au complet';

  @override
  String get ckTakimtamAciklama => 'Tu as nourri tous les personnages.';

  @override
  String get ckAtes1000Ad => 'Grand feu';

  @override
  String get ckAtes1000Aciklama =>
      'Tu as nourri l\'équipe pendant quatre semaines différentes.';

  @override
  String get ckAtes5000Ad => 'Feu de joie';

  @override
  String get ckAtes5000Aciklama =>
      'Tu as nourri l\'équipe pendant douze semaines différentes.';

  @override
  String get ckDers5Ad => 'Curiosité';

  @override
  String get ckDers5Aciklama => 'Tu as fini cinq leçons.';

  @override
  String get ckDers10Ad => 'Sage';

  @override
  String get ckDers10Aciklama => 'Tu as fini dix leçons.';

  @override
  String get ckSabir30Ad => 'Patient';

  @override
  String get ckSabir30Aciklama =>
      '30 jours depuis ton premier repas donné, et tu es toujours là.';

  @override
  String get ckTortuparlakAd => 'Torti qui brille';

  @override
  String get ckTortuparlakAciklama =>
      'Tu as nourri Torti pendant cinq semaines différentes.';

  @override
  String get donusKarsilama => 'L\'équipe accourt pour te voir !';

  @override
  String kampOdunEtiket(int n) {
    return 'Feu de camp, $n bûches';
  }

  @override
  String get odunEklendi => 'Une nouvelle bûche pour le feu cette semaine !';

  @override
  String get cikisBaslik => 'J\'ai pris de l\'argent';

  @override
  String cikisAlt(String karakter) {
    return '$karakter l\'a gardé pour toi. Combien as-tu pris ?';
  }

  @override
  String cikisKumbarada(String tutar) {
    return 'Dans la tirelire : $tutar';
  }

  @override
  String get cikisHepsi => 'Tout';

  @override
  String get cikisFazla => 'C\'est plus que ce qu\'il y a dans la tirelire.';

  @override
  String get cikisDugme => 'C\'est fait';

  @override
  String cikisTamam(String karakter) {
    return '$karakter : profites-en bien !';
  }

  @override
  String get cikisSatir => 'Retiré';

  @override
  String get cikisSil => 'Supprimer cette entrée';

  @override
  String get cikisSilOnay => 'Supprimer cette entrée ?';

  @override
  String get geriBildirim => 'Envoyer un avis';

  @override
  String get geriBildirimAciklama =>
      'Seul ce qui figure ci-dessous est envoyé : ni montants, ni noms, ni données personnelles. Tu peux le lire avant et tu choisis où il part.';

  @override
  String get geriBildirimOzet => 'Ce qui sera envoyé';

  @override
  String get geriBildirimSoru1 => 'Qu\'est-ce que ton enfant a préféré ?';

  @override
  String get geriBildirimSoru2 => 'Où a-t-il ou elle bloqué ?';

  @override
  String get geriBildirimSoru3 => 'S\'il ou elle a arrêté, pourquoi ?';

  @override
  String get geriBildirimPaylas => 'Partager';

  @override
  String get geriBildirimKilitGerek =>
      'Crée d\'abord un code parent pour envoyer un avis.';

  @override
  String get geriBildirimKonu => 'Avis sur Harçlıklarım';

  @override
  String get gbSurum => 'Version';

  @override
  String get gbDil => 'Langue';

  @override
  String get gbPara => 'Devise';

  @override
  String get gbYas => 'Mode d\'âge';

  @override
  String get gbGorunum => 'Style des personnages';

  @override
  String get gbKurulu => 'Jours depuis l\'installation';

  @override
  String get gbGun => 'Jours différents de nourrissage';

  @override
  String get gbOdun => 'Bûches du feu';

  @override
  String get gbCikis => 'Retraits';

  @override
  String get gbDers => 'Leçons lues';

  @override
  String get gbCikartma => 'Autocollants débloqués';

  @override
  String ikilemBaslik(String karakter) {
    return '$karakter réfléchit';
  }

  @override
  String ikilemSoru(String karakter) {
    return '$karakter a un peu d\'argent. De nouveaux glands ou une planche pour le nid d\'hiver ?';
  }

  @override
  String get ikilemIstek => 'De nouveaux glands';

  @override
  String get ikilemIhtiyac => 'Une planche pour le nid';

  @override
  String get ikilemIstekCevap =>
      'Une envie ! C\'est un désir. Les envies, c\'est bien aussi, chacune à son tour.';

  @override
  String get ikilemIhtiyacCevap =>
      'Un nid bien chaud pour l\'hiver ! C\'est un besoin. D\'abord les besoins, ensuite les envies.';

  @override
  String get ikilemTamam => 'D\'accord';

  @override
  String get ayarlarGizlilik => 'Confidentialité';

  @override
  String get hedefBaslik => 'Objectif';

  @override
  String get hedefSec => 'Choisir un objectif';

  @override
  String get hedefDegistir => 'Changer';

  @override
  String get hedefYeni => 'Nouvel objectif';

  @override
  String get hedefKaydet => 'Fixer l’objectif';

  @override
  String get hedefKaldir => 'Retirer l’objectif';

  @override
  String hedefYok(String karakter) {
    return 'Tu économises pour quelque chose ? Choisis-le et $karakter le portera ; il se remplit quand tu nourris.';
  }

  @override
  String hedefEsyaAdi(String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'Vélo',
      'top': 'Ballon',
      'kitap': 'Livre',
      'kulaklik': 'Casque',
      'oyuncak': 'Jouet',
      'kaykay': 'Skate',
      'oyun': 'Jeu',
      'hediye': 'Cadeau',
      'cizim': 'Dessine-le',
      'other': 'Cadeau',
    });
    return '$_temp0';
  }

  @override
  String hedefCumle(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'un vélo',
      'top': 'un ballon',
      'kitap': 'un livre',
      'kulaklik': 'un casque',
      'oyuncak': 'un jouet',
      'kaykay': 'un skate',
      'oyun': 'un jeu',
      'hediye': 'un cadeau',
      'cizim': 'ce que tu as dessiné',
      'other': 'un cadeau',
    });
    return '$karakter économise pour $_temp0';
  }

  @override
  String hedefHazir(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'Le vélo est prêt !',
      'top': 'Le ballon est prêt !',
      'kitap': 'Le livre est prêt !',
      'kulaklik': 'Le casque est prêt !',
      'oyuncak': 'Le jouet est prêt !',
      'kaykay': 'Le skate est prêt !',
      'oyun': 'Le jeu est prêt !',
      'hediye': 'Le cadeau est prêt !',
      'cizim': 'Ce que tu as dessiné est prêt !',
      'other': 'L’objectif est atteint !',
    });
    return '$_temp0 $karakter est très content.';
  }

  @override
  String hedefKademe(String kademe) {
    String _temp0 = intl.Intl.selectLogic(kademe, {
      'yeni': 'Se remplit dès le premier repas',
      'basladi': 'Ça se remplit',
      'yarim': 'À moitié',
      'neredeyse': 'Presque plein',
      'hazir': 'Plein !',
      'other': 'Ça se remplit',
    });
    return '$_temp0';
  }

  @override
  String hedefSayfaBaslik(String karakter) {
    return 'Pour quoi $karakter économise ?';
  }

  @override
  String get hedefFiyat => 'Environ combien ?';

  @override
  String get hedefFiyatNot =>
      'Ce nombre ne se voit qu’ici ; ensuite, l’objet se remplit à l’écran.';

  @override
  String get karsilamaParaNot =>
      'La monnaie ne peut plus être changée une fois qu’on a donné de l’argent à un personnage.';

  @override
  String ogrenKarakterSoruyor(String karakter) {
    return '$karakter bloque là-dessus. Tu peux lui expliquer ?';
  }

  @override
  String ogrenOgretti(String karakter) {
    return '$karakter : \"Maintenant je comprends, merci !\"';
  }

  @override
  String ogrenBirlikte(String karakter) {
    return '$karakter : \"Hmm, je me suis trompé aussi. On relit ensemble ?\"';
  }

  @override
  String detayOgrettiklerin(String karakter) {
    return '$karakter a appris de toi';
  }

  @override
  String get planBaslik => 'Mon plan';

  @override
  String get planYok =>
      'Tu peux choisir un petit plan pour toi. Personne ne le vérifie.';

  @override
  String get planSec => 'Choisir un plan';

  @override
  String get planSayfaAlt =>
      'Choisis une phrase, ce sera ta promesse. Tu peux la changer quand tu veux.';

  @override
  String planCumle(String sablon, String karakter) {
    String _temp0 = intl.Intl.selectLogic(sablon, {
      'biriktiririm':
          'Quand je reçois mon argent de poche, j\'en mets une partie de côté avec $karakter.',
      'beklerim': 'Avant d\'acheter quelque chose, j\'attends un jour.',
      'bakarim': 'Le week-end, je regarde ma tirelire avec $karakter.',
      'other': 'Avant d\'acheter quelque chose, j\'attends un jour.',
    });
    return '$_temp0';
  }

  @override
  String get planKaldir => 'Retirer le plan';

  @override
  String get cizimBaslik => 'Dessine ton objectif';

  @override
  String get cizimAlt =>
      'Dessine ici avec ton doigt ce pour quoi tu économises.';

  @override
  String get cizimAlani => 'Zone de dessin. Dessine avec ton doigt.';

  @override
  String get cizimGeriAl => 'Annuler';

  @override
  String get cizimTemizle => 'Effacer';

  @override
  String get cizimBitti => 'Fini';

  @override
  String get cizimVazgec => 'Fermer';

  @override
  String get cizimYeniden => 'Redessiner';

  @override
  String get cizimEtiket => 'Ton dessin';

  @override
  String cizimRenk(String renk) {
    String _temp0 = intl.Intl.selectLogic(renk, {
      'r0': 'Noir',
      'r1': 'Rouge',
      'r2': 'Jaune',
      'r3': 'Vert',
      'r4': 'Bleu',
      'other': 'Noir',
    });
    return '$_temp0';
  }

  @override
  String get ulastiklarimBaslik => 'Objectifs atteints';

  @override
  String ulasilanCumle(String ay) {
    return 'Objectif atteint : $ay';
  }

  @override
  String get besleNereden => 'D’où vient-il ? (si tu veux)';

  @override
  String kaynakAdi(String kaynak) {
    String _temp0 = intl.Intl.selectLogic(kaynak, {
      'harclik': 'Argent de poche',
      'hediye': 'Cadeau',
      'emek': 'Je l’ai gagné',
      'other': 'Argent de poche',
    });
    return '$_temp0';
  }

  @override
  String besleEmek(String karakter) {
    return '$karakter : Tu l’as gagné toi-même ! Je le garde bien.';
  }

  @override
  String besleHediye(String karakter) {
    return '$karakter : Un cadeau ! Je le garde bien.';
  }
}
