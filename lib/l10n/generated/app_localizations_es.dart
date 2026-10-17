// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get uygulamaAdi => 'Mi Dinero de Bolsillo';

  @override
  String get karakterAltin => 'Tortu';

  @override
  String get karakterDolar => 'Saltín';

  @override
  String get karakterEuro => 'Bubo';

  @override
  String get karakterNakit => 'Bellota';

  @override
  String get varlikAltin => 'Oro';

  @override
  String get varlikDolar => 'Dólar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Efectivo';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'Camino despacio, pero mi caparazón es fuerte. En los días difíciles, aguanto.';

  @override
  String get huyDolar =>
      '¡Yo salto! A veces arriba, a veces abajo. La paciencia gana.';

  @override
  String get huyEuro => 'Miro con calma. Guardo el dinero de países lejanos.';

  @override
  String get huyNakit =>
      'Guardo todo lo que me das. Pero cuando los precios suben, alcanza para menos.';

  @override
  String get karsilamaBaslik => 'El Equipo Alcancía te espera';

  @override
  String get karsilamaAlt =>
      'Tus ahorros viven en cuatro personajes amigos. Dales de comer y tu fogata crece.';

  @override
  String get karsilamaBasla => 'Empezar';

  @override
  String get adSoru => '¿Cómo te llamamos?';

  @override
  String get adIpucu => 'Tu nombre o apodo';

  @override
  String get yasSoru => '¿Cuántos años tienes?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get paraSoru => '¿Qué dinero usas?';

  @override
  String get dunyaSoru => '¿Dónde ponemos el campamento?';

  @override
  String get dunyaAlt => 'Puedes cambiarlo cuando quieras.';

  @override
  String get devam => 'Seguir';

  @override
  String get geri => 'Atrás';

  @override
  String get veliBaslik => 'Rincón de padres';

  @override
  String get veliAciklama =>
      'Este PIN de 4 cifras protege las correcciones de precio, el borrado de datos y los ajustes. Las pantallas de los niños no tienen anuncios, notificaciones ni compras.';

  @override
  String get veliPinIpucu => 'PIN de 4 cifras';

  @override
  String get veliPinTekrar => 'Repite el PIN';

  @override
  String get veliPinUyusmaz => 'Los PIN no coinciden';

  @override
  String get veliPinSonra => 'Ahora no';

  @override
  String get hazir => '¡Vamos!';

  @override
  String get sekmeKamp => 'Campamento';

  @override
  String get sekmeOgren => 'Aprender';

  @override
  String get sekmeCikartma => 'Pegatinas';

  @override
  String get sekmeAyarlar => 'Ajustes';

  @override
  String kampSelam(String ad) {
    return 'Hola, $ad';
  }

  @override
  String get kampAtesim => 'Mi fogata';

  @override
  String get kampBos =>
      'Tu fogata todavía no está encendida. Toca un personaje y dale de comer.';

  @override
  String get kampFiyatYok => 'No hay precios, no se puede mostrar el valor.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Precios de $zaman';
  }

  @override
  String get fark => 'Cambio';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter sonríe: $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter tiene una nubecita: $fark';
  }

  @override
  String farkDuz(String karakter) {
    return '$karakter sigue en calma: sin cambios';
  }

  @override
  String get besle => 'Dar de comer';

  @override
  String besleBaslik(String karakter, String tur) {
    return 'Dar de comer a $karakter';
  }

  @override
  String get besleTutar => '¿Cuánto?';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Hoy 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return 'Con $tutar compras $miktar';
  }

  @override
  String besleVer(String karakter) {
    return 'Dar a $karakter';
  }

  @override
  String get besleFiyatYok =>
      'No se pudo cargar el precio de hoy. Prueba otra vez cuando tengas internet.';

  @override
  String get besleGecersiz => 'Escribe una cantidad';

  @override
  String besleDoydu(String karakter) {
    return '¡$karakter ya comió bien!';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'Pegatina nueva: $ad';
  }

  @override
  String get detayVerdin => 'Diste';

  @override
  String get detayBugun => 'Hoy';

  @override
  String detayMiktar(String miktar) {
    return 'Tienes $miktar';
  }

  @override
  String detayBos(String karakter) {
    return '$karakter todavía no ha comido.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter te explica';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Desde que lo compraste, el $varlik subió de valor. La misma cantidad ahora vale más: $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Desde que lo compraste, el $varlik bajó un poco. No es tu culpa; los precios cambian como el clima. Tu cantidad sigue igual, hoy vale un poco menos: $fark. Las nubes vienen y se van.';
  }

  @override
  String get detayNedenNakit =>
      'El efectivo siempre muestra el mismo número. Pero cuando los precios suben, el mismo dinero compra menos; eso se llama inflación.';

  @override
  String get detayBeslemeler => 'Tus comidas';

  @override
  String get detayBirazDaha => 'Dar un poco más';

  @override
  String get detaySil => 'Borrar esta comida';

  @override
  String get detaySilOnay => '¿Borrar esta comida?';

  @override
  String get iptal => 'Cancelar';

  @override
  String get sil => 'Borrar';

  @override
  String get ogrenBaslik => 'La idea de hoy';

  @override
  String ogrenSayac(int n, int toplam) {
    return '$n / $toplam';
  }

  @override
  String get ogrenSoru => 'Pregunta';

  @override
  String ogrenDogru(String karakter) {
    return '¡Correcto! $karakter te aplaude.';
  }

  @override
  String get ogrenYanlis => 'Piénsalo otra vez. La pista está en el texto.';

  @override
  String get ogrenSonraki => 'Siguiente lección';

  @override
  String get ogrenBitti =>
      'Terminaste todas las lecciones. Pronto habrá nuevas.';

  @override
  String get ogrenBastan => 'Leer otra vez';

  @override
  String get cikartmaBaslik => 'Mis pegatinas';

  @override
  String get cikartmaAlt => 'Se ganan por lo que haces, no por suerte.';

  @override
  String get cikartmaKilitli => 'Bloqueada';

  @override
  String cikartmaSayac(int n, int toplam) {
    return '$n / $toplam desbloqueadas';
  }

  @override
  String get ayarlarBaslik => 'Ajustes';

  @override
  String get ayarlarDunya => 'Lugar del campamento';

  @override
  String get ayarlarYas => 'Modo de edad';

  @override
  String get ayarlarPara => 'Moneda';

  @override
  String get ayarlarSes => 'Sonidos';

  @override
  String get sesAcik => 'Sí';

  @override
  String get sesKapali => 'No';

  @override
  String get ayarlarTitresim => 'Vibración';

  @override
  String get ayarlarGorunum => 'Aspecto de los personajes';

  @override
  String get gorunumKlasik => 'Clásico';

  @override
  String get gorunum3d => '3D (prueba)';

  @override
  String get ayarlarDil => 'Idioma';

  @override
  String get ayarlarVeli => 'Rincón de padres';

  @override
  String ayarlarSurum(String s) {
    return 'Versión $s';
  }

  @override
  String get ayarlarKaynak =>
      'Los precios vienen de proveedores públicos de datos de mercado y no son consejos de inversión.';

  @override
  String get dilCihaz => 'Idioma del dispositivo';

  @override
  String get kilitBaslik => 'Escribe el PIN';

  @override
  String get kilitYanlis => 'PIN incorrecto';

  @override
  String get kilitKur => 'Crea un PIN';

  @override
  String get veliSil => 'Borrar todos los datos';

  @override
  String get veliSilOnay =>
      'Se borrarán el perfil, las comidas y las pegatinas. No se puede deshacer.';

  @override
  String get veliSilOnayDugme => 'Sí, borrar';

  @override
  String get veliPinDegistir => 'Cambiar PIN';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad dio de comer $n veces en total. Fogata: $toplam.';
  }

  @override
  String get veliNot =>
      'Las pantallas de los niños no tienen notificaciones, anuncios ni compras. Los datos se quedan solo en este dispositivo.';

  @override
  String get dunyaBahce => 'Jardín';

  @override
  String get dunyaUzay => 'Espacio';

  @override
  String get dunyaOkyanus => 'Océano';

  @override
  String get dunyaNeon => 'Neón';

  @override
  String get dunyaSeker => 'Dulces';

  @override
  String get dunyaSafari => 'Safari';

  @override
  String get ckIlkbeslemeAd => 'Primera chispa';

  @override
  String get ckIlkbeslemeAciklama => 'Encendiste la fogata por primera vez.';

  @override
  String get ckTortusapkaAd => 'El sombrero de Tortu';

  @override
  String get ckTortusapkaAciklama => 'Le diste de comer a Tortu tres veces.';

  @override
  String get ckZipzipatkiAd => 'La bufanda de Saltín';

  @override
  String get ckZipzipatkiAciklama => 'Le diste de comer a Saltín tres veces.';

  @override
  String get ckBaykusgozlukAd => 'Las gafas de Bubo';

  @override
  String get ckBaykusgozlukAciklama => 'Le diste de comer a Bubo tres veces.';

  @override
  String get ckSincapfularAd => 'El pañuelo de Bellota';

  @override
  String get ckSincapfularAciklama => 'Le diste de comer a Bellota tres veces.';

  @override
  String get ckTakimtamAd => 'Equipo completo';

  @override
  String get ckTakimtamAciklama => 'Diste de comer a todos los personajes.';

  @override
  String get ckAtes1000Ad => 'Fuego grande';

  @override
  String get ckAtes1000Aciklama =>
      'Diste de comer al equipo en cuatro semanas distintas.';

  @override
  String get ckAtes5000Ad => 'Hoguera';

  @override
  String get ckAtes5000Aciklama =>
      'Diste de comer al equipo en doce semanas distintas.';

  @override
  String get ckDers5Ad => 'Curiosidad';

  @override
  String get ckDers5Aciklama => 'Terminaste cinco lecciones.';

  @override
  String get ckDers10Ad => 'Sabiduría';

  @override
  String get ckDers10Aciklama => 'Terminaste diez lecciones.';

  @override
  String get ckSabir30Ad => 'Paciente';

  @override
  String get ckSabir30Aciklama =>
      'Ya pasaron 30 días desde tu primera comida, y sigues aquí.';

  @override
  String get ckTortuparlakAd => 'Tortu brillante';

  @override
  String get ckTortuparlakAciklama =>
      'Le diste de comer a Tortu en cinco semanas distintas.';

  @override
  String get donusKarsilama => '¡El equipo vino corriendo a verte!';
}
