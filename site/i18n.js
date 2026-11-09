// A página está em inglês no HTML, e sem JavaScript fica assim. Os outros idiomas moram
// aqui: cada [data-t] recebe o texto da chave, e [data-t-alt] o da descrição da imagem.
const SPOTIFY = 'https://www.figma.com/community/file/1376999463181735262/spotify-redesign';
const APPLE = 'https://www.figma.com/community/file/1622299389536274468';
const DESIGN = `<a href="${SPOTIFY}">Spotify Redesign</a>`;
const DESIGN2 = `<a href="${APPLE}">Apple Music Redesign</a>`;
const LATEST = 'https://github.com/francisceioseph/psito-player/releases/latest';
const SOURCE = 'https://github.com/francisceioseph/psito-player#install';

const STRINGS = {
  en: { copied: 'Copied' },
  pt: {
    heroTitle: 'A sua música, no seu computador.',
    heroLead: 'Um player de música local para Linux e Windows, com letras sincronizadas. Sem conta, sem streaming e sem telemetria: o que você ouve fica com você.',
    install: 'Instalar',
    sourceCode: 'Código-fonte',
    lookInside: 'Por dentro',
    shotHome: 'A página Início, com mixes e álbuns recentes',
    shotTrack: 'A página da música, com a letra',
    shotEqualizer: 'O equalizador de dez bandas',
    shotNote: 'Capturas com dados de exemplo. O player segue o idioma do sistema, em sete idiomas.',
    whatItDoes: 'O que ele faz',
    feature1: 'Toca FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF e WAV, sem pausa entre as faixas',
    feature2: 'Biblioteca de álbuns, artistas, gêneros e pastas, atualizada quando os arquivos mudam',
    feature3: 'Letras sincronizadas de <code>.lrc</code>, <code>.srt</code> ou das tags do arquivo',
    feature4: 'Favoritos, notas por estrelas opcionais, playlists e mixes diários feitos da sua biblioteca',
    feature5: 'Equalizador de dez bandas e ReplayGain',
    feature6: 'Modos compacto e miniplayer, teclas de mídia e applets de som do sistema',
    windowsIntro: 'No Windows 10 (1809 ou mais novo) ou no Windows 11, em x64. Não pede administrador.',
    windowsDownload: 'Baixar o instalador',
    windowsNote: 'O SmartScreen pode avisar que o editor é desconhecido, porque o instalador não tem um certificado pago. Escolha Mais informações e depois Executar assim mesmo.',
    debIntro: 'No Debian 13, Ubuntu 24.04, Mint 22 ou mais novos, em amd64. Ele atualiza junto com o sistema.',
    fedoraIntro: 'Em x86_64, testado no Fedora 45. Ele atualiza junto com o sistema. A primeira instalação pede para aceitar a chave de assinatura.',
    archIntro: 'Pelo AUR, com o seu assistente de sempre:',
    removeIntro: 'Para remover o player e o repositório',
    copy: 'Copiar',
    copied: 'Copiado',
    otherNote: `Outro sistema? Você pode <a href="${LATEST}">baixar o pacote</a> ou <a href="${SOURCE}">compilar do código-fonte</a>.`,
    links: 'Links',
    wikiNote: 'Como cada função funciona',
    issues: 'Issues',
    issuesNote: 'Relatar um problema',
    releases: 'Versões',
    releasesNote: 'O que mudou em cada versão',
    githubNote: 'O código-fonte',
    footer: `Licença Apache 2.0. Desenvolvido com o auxílio do Claude Code. Design inspirado em ${DESIGN} e ${DESIGN2}, de Juxtopposed.`,
  },
  es: {
    heroTitle: 'Tu música, en tu ordenador.',
    heroLead: 'Un reproductor de música local para Linux y Windows, con letras sincronizadas. Sin cuenta, sin streaming y sin telemetría: lo que escuchas se queda contigo.',
    install: 'Instalar',
    sourceCode: 'Código fuente',
    lookInside: 'Por dentro',
    shotHome: 'La página de inicio, con mixes y álbumes recientes',
    shotTrack: 'La página de la canción, con la letra',
    shotEqualizer: 'El ecualizador de diez bandas',
    shotNote: 'Capturas con datos de ejemplo, en portugués. El reproductor sigue el idioma de tu sistema, en siete idiomas.',
    whatItDoes: 'Qué hace',
    feature1: 'Reproduce FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF y WAV, sin pausas entre pistas',
    feature2: 'Biblioteca de álbumes, artistas, géneros y carpetas, actualizada cuando cambian los archivos',
    feature3: 'Letras sincronizadas de <code>.lrc</code>, <code>.srt</code> o de las etiquetas del archivo',
    feature4: 'Favoritos, valoración opcional por estrellas, listas y mixes diarios hechos con tu biblioteca',
    feature5: 'Ecualizador de diez bandas y ReplayGain',
    feature6: 'Modos compacto y minirreproductor, teclas multimedia y applets de sonido del escritorio',
    windowsIntro: 'En Windows 10 (1809 o posterior) o Windows 11, en x64. No pide permisos de administrador.',
    windowsDownload: 'Descargar el instalador',
    windowsNote: 'SmartScreen puede avisar de un editor desconocido, porque el instalador no tiene un certificado de pago. Elige Más información y luego Ejecutar de todas formas.',
    debIntro: 'En Debian 13, Ubuntu 24.04, Mint 22 o posteriores, en amd64. Se actualiza junto con el sistema.',
    fedoraIntro: 'En x86_64, probado en Fedora 45. Se actualiza junto con el sistema. La primera instalación pide aceptar la clave de firma.',
    archIntro: 'Desde el AUR, con tu asistente habitual:',
    removeIntro: 'Para quitar el reproductor y el repositorio',
    copy: 'Copiar',
    copied: 'Copiado',
    otherNote: `¿Otro sistema? Puedes <a href="${LATEST}">descargar el paquete</a> o <a href="${SOURCE}">compilar desde el código fuente</a>.`,
    links: 'Enlaces',
    wikiNote: 'Cómo funciona cada función (en inglés)',
    issues: 'Issues',
    issuesNote: 'Informar de un problema',
    releases: 'Versiones',
    releasesNote: 'Qué cambió en cada versión',
    githubNote: 'El código fuente',
    footer: `Licencia Apache 2.0. Desarrollado con la ayuda de Claude Code. Diseño inspirado en ${DESIGN} y ${DESIGN2}, de Juxtopposed.`,
  },
  fr: {
    heroTitle: 'Votre musique, sur votre ordinateur.',
    heroLead: 'Un lecteur de musique local pour Linux et Windows, avec paroles synchronisées. Sans compte, sans streaming et sans télémétrie : ce que vous écoutez reste chez vous.',
    install: 'Installer',
    sourceCode: 'Code source',
    lookInside: 'Un aperçu',
    shotHome: 'La page d’accueil, avec les mix et les albums récents',
    shotTrack: 'La page du morceau, avec les paroles',
    shotEqualizer: 'L’égaliseur à dix bandes',
    shotNote: 'Captures avec des données d’exemple, en portugais. Le lecteur suit la langue de votre système, en sept langues.',
    whatItDoes: 'Ce qu’il fait',
    feature1: 'Lit FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF et WAV, sans blanc entre les morceaux',
    feature2: 'Bibliothèque d’albums, d’artistes, de genres et de dossiers, à jour quand les fichiers changent',
    feature3: 'Paroles synchronisées depuis <code>.lrc</code>, <code>.srt</code> ou les tags du fichier',
    feature4: 'Favoris, notes par étoiles en option, playlists et mix quotidiens faits à partir de votre bibliothèque',
    feature5: 'Égaliseur à dix bandes et ReplayGain',
    feature6: 'Modes compact et mini-lecteur, touches multimédia et applets de son du bureau',
    windowsIntro: 'Sur Windows 10 (1809 ou plus récent) ou Windows 11, en x64. Aucun droit d’administrateur n’est demandé.',
    windowsDownload: 'Télécharger l’installateur',
    windowsNote: 'SmartScreen peut signaler un éditeur inconnu, car l’installateur n’a pas de certificat payant. Choisissez Informations complémentaires, puis Exécuter quand même.',
    debIntro: 'Sur Debian 13, Ubuntu 24.04, Mint 22 ou plus récents, en amd64. Il se met à jour avec le système.',
    fedoraIntro: 'En x86_64, testé sur Fedora 45. Il se met à jour avec le système. La première installation demande d’accepter la clé de signature.',
    archIntro: 'Depuis l’AUR, avec votre assistant habituel :',
    removeIntro: 'Pour retirer le lecteur et le dépôt',
    copy: 'Copier',
    copied: 'Copié',
    otherNote: `Un autre système ? Vous pouvez <a href="${LATEST}">télécharger le paquet</a> ou <a href="${SOURCE}">compiler depuis le code source</a>.`,
    links: 'Liens',
    wikiNote: 'Comment marche chaque fonction (en anglais)',
    issues: 'Issues',
    issuesNote: 'Signaler un problème',
    releases: 'Versions',
    releasesNote: 'Ce qui a changé à chaque version',
    githubNote: 'Le code source',
    footer: `Licence Apache 2.0. Développé avec l’aide de Claude Code. Design inspiré de ${DESIGN} et ${DESIGN2}, par Juxtopposed.`,
  },
  de: {
    heroTitle: 'Deine Musik, auf deinem Computer.',
    heroLead: 'Ein lokaler Musikplayer für Linux und Windows, mit synchronisierten Liedtexten. Kein Konto, kein Streaming und keine Telemetrie: Was du hörst, bleibt bei dir.',
    install: 'Installieren',
    sourceCode: 'Quellcode',
    lookInside: 'Ein Blick hinein',
    shotHome: 'Die Startseite mit Mixen und neuen Alben',
    shotTrack: 'Die Titelseite mit dem Liedtext',
    shotEqualizer: 'Der Equalizer mit zehn Bändern',
    shotNote: 'Aufnahmen mit Beispieldaten, auf Portugiesisch. Der Player folgt der Sprache deines Systems, in sieben Sprachen.',
    whatItDoes: 'Was er kann',
    feature1: 'Spielt FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF und WAV ohne Pausen zwischen den Titeln',
    feature2: 'Mediathek mit Alben, Künstlern, Genres und Ordnern, die aktuell bleibt, wenn sich Dateien ändern',
    feature3: 'Synchronisierte Liedtexte aus <code>.lrc</code>, <code>.srt</code> oder den Tags der Datei',
    feature4: 'Favoriten, optionale Sternebewertung, Playlists und tägliche Mixe aus deiner Mediathek',
    feature5: 'Equalizer mit zehn Bändern und ReplayGain',
    feature6: 'Kompakt- und Minimodus, Medientasten und Sound-Applets des Desktops',
    windowsIntro: 'Unter Windows 10 (1809 oder neuer) oder Windows 11, auf x64. Es sind keine Administratorrechte nötig.',
    windowsDownload: 'Installationsprogramm laden',
    windowsNote: 'SmartScreen warnt eventuell vor einem unbekannten Herausgeber, weil das Installationsprogramm kein bezahltes Zertifikat hat. Wähle Weitere Informationen und dann Trotzdem ausführen.',
    debIntro: 'Auf Debian 13, Ubuntu 24.04, Mint 22 oder neuer, auf amd64. Er wird zusammen mit dem System aktualisiert.',
    fedoraIntro: 'Auf x86_64, getestet auf Fedora 45. Er wird zusammen mit dem System aktualisiert. Bei der ersten Installation musst du den Signaturschlüssel bestätigen.',
    archIntro: 'Aus dem AUR, mit deinem üblichen Helfer:',
    removeIntro: 'Um den Player und das Repository zu entfernen',
    copy: 'Kopieren',
    copied: 'Kopiert',
    otherNote: `Ein anderes System? Du kannst <a href="${LATEST}">das Paket herunterladen</a> oder <a href="${SOURCE}">aus dem Quellcode bauen</a>.`,
    links: 'Links',
    wikiNote: 'Wie jede Funktion arbeitet (auf Englisch)',
    issues: 'Issues',
    issuesNote: 'Ein Problem melden',
    releases: 'Versionen',
    releasesNote: 'Was sich in jeder Version geändert hat',
    githubNote: 'Der Quellcode',
    footer: `Apache-2.0-Lizenz. Mit Hilfe von Claude Code entwickelt. Design inspiriert von ${DESIGN} und ${DESIGN2}, von Juxtopposed.`,
  },
  ru: {
    heroTitle: 'Ваша музыка на вашем компьютере.',
    heroLead: 'Локальный музыкальный плеер для Linux и Windows с синхронизированными текстами. Без учётной записи, стриминга и телеметрии: то, что вы слушаете, остаётся у вас.',
    install: 'Установить',
    sourceCode: 'Исходный код',
    lookInside: 'Как это выглядит',
    shotHome: 'Главная страница с миксами и новыми альбомами',
    shotTrack: 'Страница трека с текстом',
    shotEqualizer: 'Десятиполосный эквалайзер',
    shotNote: 'Снимки с примерами данных, на португальском. Плеер использует язык вашей системы, доступно семь языков.',
    whatItDoes: 'Что он умеет',
    feature1: 'Воспроизводит FLAC, MP3, OGG, Opus, M4A, AAC, WMA, APE, WavPack, AIFF и WAV без пауз между треками',
    feature2: 'Медиатека альбомов, исполнителей, жанров и папок, которая обновляется при изменении файлов',
    feature3: 'Синхронизированные тексты из <code>.lrc</code>, <code>.srt</code> или тегов файла',
    feature4: 'Избранное, оценки звёздами по желанию, плейлисты и ежедневные миксы из вашей медиатеки',
    feature5: 'Десятиполосный эквалайзер и ReplayGain',
    feature6: 'Компактный режим и мини-плеер, мультимедийные клавиши и звуковые апплеты рабочего стола',
    windowsIntro: 'В Windows 10 (1809 или новее) и Windows 11, на x64. Права администратора не нужны.',
    windowsDownload: 'Скачать установщик',
    windowsNote: 'SmartScreen может предупредить о неизвестном издателе, потому что у установщика нет платного сертификата. Выберите «Подробнее», затем «Выполнить в любом случае».',
    debIntro: 'В Debian 13, Ubuntu 24.04, Mint 22 и новее, на amd64. Обновляется вместе с системой.',
    fedoraIntro: 'На x86_64, проверено в Fedora 45. Обновляется вместе с системой. При первой установке нужно принять ключ подписи.',
    archIntro: 'Из AUR, с помощью вашего обычного помощника:',
    removeIntro: 'Чтобы удалить плеер и репозиторий',
    copy: 'Копировать',
    copied: 'Скопировано',
    otherNote: `Другая система? Можно <a href="${LATEST}">скачать пакет</a> или <a href="${SOURCE}">собрать из исходного кода</a>.`,
    links: 'Ссылки',
    wikiNote: 'Как работает каждая функция (на английском)',
    issues: 'Issues',
    issuesNote: 'Сообщить о проблеме',
    releases: 'Версии',
    releasesNote: 'Что изменилось в каждой версии',
    githubNote: 'Исходный код',
    footer: `Лицензия Apache 2.0. Разработано с помощью Claude Code. Дизайн вдохновлён ${DESIGN} и ${DESIGN2} от Juxtopposed.`,
  },
  zh: {
    heroTitle: '你的音乐，在你的电脑上。',
    heroLead: '一款适用于 Linux 和 Windows 的本地音乐播放器，支持同步歌词。无需账号，没有流媒体，也没有遥测：你听什么只有你知道。',
    install: '安装',
    sourceCode: '源代码',
    lookInside: '界面一览',
    shotHome: '主页，显示混音和最近的专辑',
    shotTrack: '歌曲页面，显示歌词',
    shotEqualizer: '十段均衡器',
    shotNote: '截图使用示例数据，界面为葡萄牙语。播放器跟随系统语言，支持七种语言。',
    whatItDoes: '功能',
    feature1: '播放 FLAC、MP3、OGG、Opus、M4A、AAC、WMA、APE、WavPack、AIFF 和 WAV，曲目之间无间隙',
    feature2: '专辑、艺人、流派和文件夹组成的音乐库，随文件变化自动更新',
    feature3: '来自 <code>.lrc</code>、<code>.srt</code> 或文件标签的同步歌词',
    feature4: '收藏、可选的星级评分、播放列表，以及从你的音乐库生成的每日混音',
    feature5: '十段均衡器和 ReplayGain',
    feature6: '紧凑模式和迷你播放器、媒体键，以及桌面声音小程序',
    windowsIntro: '适用于 Windows 10（1809 或更新版本）或 Windows 11，x64。无需管理员权限。',
    windowsDownload: '下载安装程序',
    windowsNote: '由于安装程序没有付费证书，SmartScreen 可能提示发布者未知。请选择“更多信息”，然后选择“仍要运行”。',
    debIntro: '适用于 Debian 13、Ubuntu 24.04、Mint 22 或更新版本，amd64 架构。随系统一起更新。',
    fedoraIntro: '适用于 x86_64，已在 Fedora 45 上测试。随系统一起更新。首次安装时需要接受签名密钥。',
    archIntro: '从 AUR 安装，使用你常用的助手：',
    removeIntro: '移除播放器和软件源',
    copy: '复制',
    copied: '已复制',
    otherNote: `其他系统？你可以<a href="${LATEST}">下载软件包</a>或<a href="${SOURCE}">从源代码编译</a>。`,
    links: '链接',
    wikiNote: '每项功能的说明（英文）',
    issues: 'Issues',
    issuesNote: '报告问题',
    releases: '版本',
    releasesNote: '每个版本的更改',
    githubNote: '源代码',
    footer: `Apache 2.0 许可证。在 Claude Code 的帮助下开发。设计灵感来自 Juxtopposed 的 ${DESIGN} 和 ${DESIGN2}。`,
  },
};

const KEY = 'psito-player-lang';
const WIKI = 'https://github.com/francisceioseph/psito-player/wiki';
const texts = new Map();
const alts = new Map();
for (const el of document.querySelectorAll('[data-t]')) texts.set(el, el.innerHTML);
for (const el of document.querySelectorAll('[data-t-alt]')) alts.set(el, el.alt);

function saved() {
  try { return localStorage.getItem(KEY); } catch { return null; }
}

function setLang(lang, remember) {
  const strings = STRINGS[lang];
  document.documentElement.lang = lang;
  document.getElementById('lang').value = lang;
  for (const [el, english] of texts) el.innerHTML = strings[el.dataset.t] ?? english;
  for (const [el, english] of alts) el.alt = strings[el.dataset.tAlt] ?? english;
  // A wiki só existe em inglês e em português
  document.getElementById('wiki').href = lang === 'pt' ? `${WIKI}/Inicio` : WIKI;
  if (remember) {
    try { localStorage.setItem(KEY, lang); } catch {}
  }
}

const system = navigator.language.slice(0, 2).toLowerCase();
const start = saved() ?? system;
setLang(start in STRINGS ? start : 'en', false);
document.getElementById('lang').addEventListener('change', (event) => setLang(event.target.value, true));

for (const button of document.querySelectorAll('[data-copy]')) {
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(document.getElementById(button.dataset.copy).textContent);
      button.textContent = STRINGS[document.documentElement.lang].copied;
      setTimeout(() => {
        const strings = STRINGS[document.documentElement.lang];
        button.innerHTML = strings.copy ?? texts.get(button);
      }, 1500);
    } catch {
      // Sem acesso à área de transferência, o texto continua selecionável
    }
  });
}
