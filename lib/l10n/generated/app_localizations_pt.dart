// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get uygulamaAdi => 'Minha Mesada';

  @override
  String get karakterAltin => 'Jabu';

  @override
  String get karakterDolar => 'Pipoca';

  @override
  String get karakterEuro => 'Juju';

  @override
  String get karakterNakit => 'Nozinho';

  @override
  String get varlikAltin => 'Ouro';

  @override
  String get varlikDolar => 'Dólar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Dinheiro';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'Eu ando devagar, mas meu casco é forte. Nos dias difíceis, eu aguento firme.';

  @override
  String get huyDolar =>
      'Eu pulo! Às vezes para cima, às vezes para baixo. Quem tem paciência ganha.';

  @override
  String get huyEuro =>
      'Eu observo com calma. Guardo o dinheiro de países distantes.';

  @override
  String get huyNakit =>
      'Eu guardo tudo o que você me dá. Mas quando os preços sobem, ele compra menos.';

  @override
  String get karsilamaBaslik => 'A Turma do Cofrinho está esperando você';

  @override
  String get karsilamaAlt =>
      'Quando colocar dinheiro no seu cofrinho de verdade, dê para um amigo aqui. Os quatro crescem com suas economias e sua fogueira acende.';

  @override
  String get karsilamaBasla => 'Começar';

  @override
  String get adSoru => 'Como podemos chamar você?';

  @override
  String get adIpucu => 'Seu nome ou apelido';

  @override
  String get yasSoru => 'Quantos anos você tem?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get dunyaSoru => 'Onde vamos montar o acampamento?';

  @override
  String get dunyaAlt => 'Você pode mudar quando quiser.';

  @override
  String get devam => 'Continuar';

  @override
  String get geri => 'Voltar';

  @override
  String get veliBaslik => 'Cantinho dos pais';

  @override
  String get veliAciklama =>
      'Este PIN de 4 dígitos protege a correção de preços, a exclusão de dados e as configurações. As telas das crianças não têm anúncios, notificações nem compras.';

  @override
  String get veliPinIpucu => 'PIN de 4 dígitos';

  @override
  String get veliPinTekrar => 'Repita o PIN';

  @override
  String get veliPinUyusmaz => 'Os PINs não são iguais';

  @override
  String get veliPinSonra => 'Pular por enquanto';

  @override
  String get hazir => 'Vamos lá!';

  @override
  String get sekmeKamp => 'Acampamento';

  @override
  String get sekmeOgren => 'Aprender';

  @override
  String get sekmeCikartma => 'Figurinhas';

  @override
  String get sekmeAyarlar => 'Ajustes';

  @override
  String kampSelam(String ad) {
    return 'Oi, $ad';
  }

  @override
  String get kampAtesim => 'Minha fogueira';

  @override
  String get kampBos =>
      'Sua fogueira ainda não foi acesa. Quando colocar dinheiro no cofrinho, toque em um amigo e dê para ele.';

  @override
  String get kampFiyatYok =>
      'Preços indisponíveis, não dá para mostrar o valor.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Preços de $zaman';
  }

  @override
  String get fark => 'Diferença';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter está sorrindo: $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter está debaixo de uma nuvem: $fark';
  }

  @override
  String farkDuz(String karakter) {
    return 'Tudo calmo com $karakter: nada mudou';
  }

  @override
  String get besle => 'Alimentar';

  @override
  String besleBaslik(String karakter, String tur) {
    return 'Alimentar $karakter';
  }

  @override
  String get besleTutar => 'Quanto?';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Hoje 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return '$tutar compra $miktar';
  }

  @override
  String besleVer(String karakter) {
    return 'Dar para $karakter';
  }

  @override
  String get besleFiyatYok =>
      'Não deu para carregar o preço de hoje. Tente de novo quando estiver on-line.';

  @override
  String get besleGecersiz => 'Digite um valor';

  @override
  String besleDoydu(String karakter) {
    return '$karakter ficou de barriga cheia!';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'Nova figurinha: $ad';
  }

  @override
  String get detayVerdin => 'Você deu';

  @override
  String get detayBugun => 'Hoje';

  @override
  String detayMiktar(String miktar) {
    return 'Você tem $miktar';
  }

  @override
  String detayBos(String karakter) {
    return 'Ainda não há alimentações para $karakter.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter explica';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Desde que você comprou, o $varlik ganhou valor. A mesma quantidade agora vale mais: $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Desde que você comprou, o $varlik ficou um pouco mais barato. A culpa não é sua; os preços mudam como o tempo. Sua quantidade continua a mesma, só o valor de hoje está um pouco menor: $fark. As nuvens vêm e vão.';
  }

  @override
  String get detayNedenNakit =>
      'O dinheiro mostra sempre o mesmo número. Mas quando os preços sobem, o mesmo dinheiro compra menos; isso se chama inflação.';

  @override
  String get detayBeslemeler => 'Suas alimentações';

  @override
  String get detayBirazDaha => 'Alimentar mais um pouco';

  @override
  String get detaySil => 'Apagar esta alimentação';

  @override
  String get detaySilOnay => 'Apagar esta alimentação?';

  @override
  String get iptal => 'Cancelar';

  @override
  String get sil => 'Apagar';

  @override
  String get ogrenBaslik => 'Ideia do dia';

  @override
  String ogrenSayac(int n, int toplam) {
    return '$n / $toplam';
  }

  @override
  String get ogrenSonraki => 'Próxima lição';

  @override
  String get ogrenBitti =>
      'Você terminou todas as lições. Novas estão a caminho.';

  @override
  String get ogrenBastan => 'Ler de novo';

  @override
  String get cikartmaBaslik => 'Minhas figurinhas';

  @override
  String get cikartmaAlt => 'Ganhas pelo que você faz, não por sorte.';

  @override
  String get cikartmaKilitli => 'Bloqueada';

  @override
  String cikartmaSayac(int n, int toplam) {
    return '$n / $toplam desbloqueadas';
  }

  @override
  String get ayarlarBaslik => 'Ajustes';

  @override
  String get ayarlarDunya => 'Lugar do acampamento';

  @override
  String get ayarlarYas => 'Modo de idade';

  @override
  String get ayarlarPara => 'Moeda';

  @override
  String get ayarlarSes => 'Sons';

  @override
  String get sesAcik => 'Ligado';

  @override
  String get sesKapali => 'Desligado';

  @override
  String get ayarlarTitresim => 'Vibração';

  @override
  String get ayarlarGorunum => 'Aparência dos personagens';

  @override
  String get gorunumKlasik => 'Clássico';

  @override
  String get gorunum3d => '3D';

  @override
  String get ayarlarDil => 'Idioma';

  @override
  String get ayarlarVeli => 'Cantinho dos pais';

  @override
  String ayarlarSurum(String s) {
    return 'Versão $s';
  }

  @override
  String get ayarlarKaynak =>
      'Os preços vêm de fornecedores públicos de dados de mercado e não são recomendação de investimento.';

  @override
  String get dilCihaz => 'Idioma do aparelho';

  @override
  String get kilitBaslik => 'Digite o PIN';

  @override
  String get kilitYanlis => 'PIN incorreto';

  @override
  String get kilitKur => 'Criar um PIN';

  @override
  String get veliSil => 'Apagar todos os dados';

  @override
  String get veliSilOnay =>
      'O perfil, as alimentações e as figurinhas serão apagados. Isso não pode ser desfeito.';

  @override
  String get veliSilOnayDugme => 'Sim, apagar';

  @override
  String get veliYedekNot =>
      'Os dados ficam só neste celular e, se estiver ativado, no backup do próprio celular (iCloud ou Google). Nós não vemos esse backup.';

  @override
  String get veliPinDegistir => 'Mudar o PIN';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad fez $n alimentações no total. Fogueira: $toplam.';
  }

  @override
  String get veliNot =>
      'As telas das crianças não têm notificações, anúncios nem compras. Os dados ficam só neste aparelho.';

  @override
  String get dunyaBahce => 'Jardim';

  @override
  String get dunyaUzay => 'Espaço';

  @override
  String get dunyaOkyanus => 'Oceano';

  @override
  String get dunyaNeon => 'Neon';

  @override
  String get dunyaSeker => 'Doces';

  @override
  String get dunyaSafari => 'Safári';

  @override
  String get ckIlkbeslemeAd => 'Primeira faísca';

  @override
  String get ckIlkbeslemeAciklama =>
      'Você acendeu a fogueira pela primeira vez.';

  @override
  String get ckTortusapkaAd => 'Chapéu do Jabu';

  @override
  String get ckTortusapkaAciklama => 'Você alimentou o Jabu três vezes.';

  @override
  String get ckZipzipatkiAd => 'Cachecol da Pipoca';

  @override
  String get ckZipzipatkiAciklama => 'Você alimentou a Pipoca três vezes.';

  @override
  String get ckBaykusgozlukAd => 'Óculos da Juju';

  @override
  String get ckBaykusgozlukAciklama => 'Você alimentou a Juju três vezes.';

  @override
  String get ckSincapfularAd => 'Bandana do Nozinho';

  @override
  String get ckSincapfularAciklama => 'Você alimentou o Nozinho três vezes.';

  @override
  String get ckTakimtamAd => 'Turma completa';

  @override
  String get ckTakimtamAciklama => 'Você alimentou todos os amigos.';

  @override
  String get ckAtes1000Ad => 'Fogueira grande';

  @override
  String get ckAtes1000Aciklama =>
      'Você alimentou a turma em quatro semanas diferentes.';

  @override
  String get ckAtes5000Ad => 'Fogueira de festa';

  @override
  String get ckAtes5000Aciklama =>
      'Você alimentou a turma em doze semanas diferentes.';

  @override
  String get ckDers5Ad => 'Curiosidade';

  @override
  String get ckDers5Aciklama => 'Você terminou cinco lições.';

  @override
  String get ckDers10Ad => 'Sabedoria';

  @override
  String get ckDers10Aciklama => 'Você terminou dez lições.';

  @override
  String get ckSabir30Ad => 'Paciente';

  @override
  String get ckSabir30Aciklama =>
      '30 dias desde a sua primeira alimentação, e você continua por aqui.';

  @override
  String get ckTortuparlakAd => 'Jabu brilhante';

  @override
  String get ckTortuparlakAciklama =>
      'Você alimentou o Jabu em cinco semanas diferentes.';

  @override
  String get donusKarsilama => 'A equipe veio correndo te ver!';

  @override
  String kampOdunEtiket(int n) {
    return 'Fogueira, $n lenhas';
  }

  @override
  String get odunEklendi => 'Uma lenha nova na fogueira esta semana!';

  @override
  String get cikisBaslik => 'Tirei dinheiro';

  @override
  String cikisAlt(String karakter) {
    return '$karakter guardou para você. Quanto você tirou?';
  }

  @override
  String cikisKumbarada(String tutar) {
    return 'No cofrinho: $tutar';
  }

  @override
  String get cikisHepsi => 'Tudo';

  @override
  String get cikisFazla => 'É mais do que tem no cofrinho.';

  @override
  String get cikisDugme => 'Pronto';

  @override
  String cikisTamam(String karakter) {
    return '$karakter: Aproveite!';
  }

  @override
  String get cikisSatir => 'Retirado';

  @override
  String get cikisSil => 'Apagar este registro';

  @override
  String get cikisSilOnay => 'Apagar este registro?';

  @override
  String get geriBildirim => 'Enviar feedback';

  @override
  String get geriBildirimAciklama =>
      'Só o que aparece abaixo é enviado: sem valores, nomes ou dados pessoais. Você pode ler antes e escolhe para onde vai.';

  @override
  String get geriBildirimOzet => 'O que será enviado';

  @override
  String get geriBildirimSoru1 => 'Do que seu filho ou filha mais gostou?';

  @override
  String get geriBildirimSoru2 => 'Onde travou?';

  @override
  String get geriBildirimSoru3 => 'Se parou de usar, por quê?';

  @override
  String get geriBildirimPaylas => 'Compartilhar';

  @override
  String get geriBildirimKilitGerek =>
      'Crie primeiro um PIN dos pais para enviar feedback.';

  @override
  String get geriBildirimKonu => 'Feedback do Harçlıklarım';

  @override
  String get gbSurum => 'Versão';

  @override
  String get gbDil => 'Idioma';

  @override
  String get gbPara => 'Moeda';

  @override
  String get gbYas => 'Modo de idade';

  @override
  String get gbGorunum => 'Estilo dos personagens';

  @override
  String get gbKurulu => 'Dias desde a instalação';

  @override
  String get gbGun => 'Dias diferentes de alimentar';

  @override
  String get gbOdun => 'Lenhas da fogueira';

  @override
  String get gbCikis => 'Vezes que tirou';

  @override
  String get gbDers => 'Lições lidas';

  @override
  String get gbCikartma => 'Figurinhas desbloqueadas';

  @override
  String ikilemBaslik(String karakter) {
    return '$karakter está pensando';
  }

  @override
  String ikilemSoru(String karakter) {
    return '$karakter tem um pouco de dinheiro. Bolotas novas ou uma tábua para o ninho de inverno?';
  }

  @override
  String get ikilemIstek => 'Bolotas novas';

  @override
  String get ikilemIhtiyac => 'Uma tábua para o ninho';

  @override
  String get ikilemIstekCevap =>
      'Algo que dá vontade! Isso é um desejo. Desejos também são bons, na hora certa.';

  @override
  String get ikilemIhtiyacCevap =>
      'Um ninho quentinho para o inverno! Isso é uma necessidade. Primeiro o necessário, depois os desejos.';

  @override
  String get ikilemTamam => 'OK';

  @override
  String get ayarlarGizlilik => 'Privacidade';

  @override
  String get hedefBaslik => 'Meta';

  @override
  String get hedefSec => 'Escolher meta';

  @override
  String get hedefDegistir => 'Trocar';

  @override
  String get hedefYeni => 'Nova meta';

  @override
  String get hedefKaydet => 'Definir meta';

  @override
  String get hedefKaldir => 'Tirar meta';

  @override
  String hedefYok(String karakter) {
    return 'Está juntando para alguma coisa? Escolha e $karakter vai carregar; o objeto enche quando você alimenta.';
  }

  @override
  String hedefEsyaAdi(String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'Bicicleta',
      'top': 'Bola',
      'kitap': 'Livro',
      'kulaklik': 'Fones',
      'oyuncak': 'Brinquedo',
      'kaykay': 'Skate',
      'oyun': 'Jogo',
      'hediye': 'Presente',
      'cizim': 'Desenhe',
      'other': 'Presente',
    });
    return '$_temp0';
  }

  @override
  String hedefCumle(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'uma bicicleta',
      'top': 'uma bola',
      'kitap': 'um livro',
      'kulaklik': 'fones de ouvido',
      'oyuncak': 'um brinquedo',
      'kaykay': 'um skate',
      'oyun': 'um jogo',
      'hediye': 'um presente',
      'cizim': 'o que você desenhou',
      'other': 'um presente',
    });
    return '$karakter está juntando para $_temp0';
  }

  @override
  String hedefHazir(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'A bicicleta está pronta!',
      'top': 'A bola está pronta!',
      'kitap': 'O livro está pronto!',
      'kulaklik': 'Os fones estão prontos!',
      'oyuncak': 'O brinquedo está pronto!',
      'kaykay': 'O skate está pronto!',
      'oyun': 'O jogo está pronto!',
      'hediye': 'O presente está pronto!',
      'cizim': 'O que você desenhou está pronto!',
      'other': 'A meta está pronta!',
    });
    return '$_temp0 $karakter está muito feliz.';
  }

  @override
  String hedefKademe(String kademe) {
    String _temp0 = intl.Intl.selectLogic(kademe, {
      'yeni': 'Começa a encher na primeira vez',
      'basladi': 'Enchendo',
      'yarim': 'Na metade',
      'neredeyse': 'Quase lá',
      'hazir': 'Completo!',
      'other': 'Enchendo',
    });
    return '$_temp0';
  }

  @override
  String hedefSayfaBaslik(String karakter) {
    return 'Para que $karakter vai juntar?';
  }

  @override
  String get hedefFiyat => 'Mais ou menos quanto?';

  @override
  String get hedefFiyatNot =>
      'Este número só aparece aqui; depois, o objeto enche na tela.';

  @override
  String get karsilamaParaNot =>
      'A moeda não pode ser trocada depois que o primeiro dinheiro for dado a um personagem.';

  @override
  String ogrenKarakterSoruyor(String karakter) {
    return '$karakter travou nisso. Você explica?';
  }

  @override
  String ogrenOgretti(String karakter) {
    return '$karakter: \"Agora entendi, obrigado!\"';
  }

  @override
  String ogrenBirlikte(String karakter) {
    return '$karakter: \"Hmm, eu também me confundi. Vamos ler de novo juntos?\"';
  }

  @override
  String detayOgrettiklerin(String karakter) {
    return '$karakter aprendeu com você';
  }

  @override
  String get planBaslik => 'Meu plano';

  @override
  String get planYok =>
      'Você pode escolher um pequeno plano para você. Ninguém confere.';

  @override
  String get planSec => 'Escolher um plano';

  @override
  String get planSayfaAlt =>
      'Escolha uma frase para ser a sua promessa. Você pode mudar quando quiser.';

  @override
  String planCumle(String sablon, String karakter) {
    String _temp0 = intl.Intl.selectLogic(sablon, {
      'biriktiririm':
          'Quando recebo minha mesada, guardo uma parte com $karakter.',
      'beklerim': 'Antes de comprar algo, eu espero um dia.',
      'bakarim': 'No fim de semana, olho meu cofrinho com $karakter.',
      'other': 'Antes de comprar algo, eu espero um dia.',
    });
    return '$_temp0';
  }

  @override
  String get planKaldir => 'Remover o plano';

  @override
  String get cizimBaslik => 'Desenhe sua meta';

  @override
  String get cizimAlt =>
      'Desenhe aqui com o dedo aquilo para o que está juntando.';

  @override
  String get cizimAlani => 'Área de desenho. Desenhe com o dedo.';

  @override
  String get cizimGeriAl => 'Desfazer';

  @override
  String get cizimTemizle => 'Limpar';

  @override
  String get cizimBitti => 'Pronto';

  @override
  String get cizimVazgec => 'Fechar';

  @override
  String get cizimYeniden => 'Desenhar de novo';

  @override
  String get cizimEtiket => 'Seu desenho';

  @override
  String cizimRenk(String renk) {
    String _temp0 = intl.Intl.selectLogic(renk, {
      'r0': 'Preto',
      'r1': 'Vermelho',
      'r2': 'Amarelo',
      'r3': 'Verde',
      'r4': 'Azul',
      'other': 'Preto',
    });
    return '$_temp0';
  }
}
