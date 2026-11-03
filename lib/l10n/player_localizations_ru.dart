// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class PlayerLocalizationsRu extends PlayerLocalizations {
  PlayerLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Музыкальный плеер';

  @override
  String get noTrack => 'Нет трека';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get progress => 'Ход воспроизведения';

  @override
  String get volume => 'Громкость';

  @override
  String get home => 'Главная';

  @override
  String get library => 'Медиатека';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get folders => 'Папки';

  @override
  String get search => 'Поиск';

  @override
  String get settings => 'Настройки';

  @override
  String engineUnavailable(Object error) {
    return 'Аудиодвижок недоступен: $error';
  }

  @override
  String get openFailed => 'Не удалось воспроизвести этот файл';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get addMusicFolder => 'Добавить папку с музыкой';

  @override
  String get folderNotVisible =>
      'Плеер не видит эту папку. Выберите папку в домашнем каталоге или на внешнем диске.';

  @override
  String get folderAlreadyAdded => 'Эта папка уже есть в медиатеке.';

  @override
  String libraryUnavailable(String error) {
    return 'Не удалось открыть медиатеку: $error';
  }

  @override
  String get albums => 'Альбомы';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String playAlbum(String album) {
    return 'Воспроизвести $album';
  }

  @override
  String get hasLyrics => 'Есть текст';

  @override
  String get moreOptions => 'Другие действия';

  @override
  String get playNext => 'Воспроизвести следующим';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get removeFromQueue => 'Убрать из очереди';

  @override
  String get queue => 'Очередь';

  @override
  String get queueEmpty => 'Очередь пуста';

  @override
  String get close => 'Закрыть';

  @override
  String get shuffle => 'Случайный порядок';

  @override
  String get previousTrack => 'Предыдущий трек';

  @override
  String get nextTrack => 'Следующий трек';

  @override
  String get repeatOff => 'Повтор: выкл.';

  @override
  String get repeatAll => 'Повтор: все';

  @override
  String get repeatOne => 'Повтор: один';

  @override
  String get continueListening => 'Продолжить с того же места';

  @override
  String get continuePlaying => 'Продолжить';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · остановлено на $position из $duration';
  }

  @override
  String get shuffleAll => 'Перемешать всё';

  @override
  String get recentlyAdded => 'Недавно добавленные';

  @override
  String get seeAll => 'Показать все';

  @override
  String get mostPlayed => 'Часто слушаемые';

  @override
  String get emptyTitle => 'Ваша медиатека пуста';

  @override
  String get emptyBody =>
      'Укажите папку с вашей музыкой. Плеер читает файлы прямо с вашего компьютера и ничего никуда не отправляет.';

  @override
  String useFolder(String folder) {
    return 'Использовать $folder';
  }

  @override
  String get acceptedFormats => 'Поддерживаемые форматы';

  @override
  String get scanning => 'Чтение медиатеки';

  @override
  String get scanSubtitle => 'Идёт чтение: найденное уже можно слушать';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Файлов: $doneString из $totalString';
  }

  @override
  String get scanLessThanMinute => 'осталось меньше минуты';

  @override
  String scanMinutesLeft(int n) {
    return 'осталось около $n мин';
  }

  @override
  String get pauseScan => 'Приостановить';

  @override
  String get resumeScan => 'Возобновить';

  @override
  String get cancelScan => 'Отмена';

  @override
  String get scanKeepsGoing =>
      'Чтение продолжится, если вы уйдёте с этого экрана';

  @override
  String get foundSoFar => 'Найдено на данный момент';

  @override
  String get updateAll => 'Обновить все';

  @override
  String get updateFolder => 'Обновить папку';

  @override
  String get removeFolder => 'Убрать из медиатеки';

  @override
  String get folderMissing => 'Диск не найден';

  @override
  String get notScanned => 'Ещё не прочитано';

  @override
  String get scannedJustNow => 'Обновлено только что';

  @override
  String scannedMinutes(int n) {
    return 'Обновлено $n мин назад';
  }

  @override
  String scannedHours(int n) {
    return 'Обновлено $n ч назад';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Обновлено $n дня назад',
      many: 'Обновлено $n дней назад',
      few: 'Обновлено $n дня назад',
      one: 'Обновлено $n день назад',
      zero: 'Обновлено сегодня',
    );
    return '$_temp0';
  }

  @override
  String lengthMinutes(int n) {
    return '$n мин';
  }

  @override
  String lengthHours(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String albumCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString альбома',
      many: '$nString альбомов',
      few: '$nString альбома',
      one: '$nString альбом',
    );
    return '$_temp0';
  }

  @override
  String trackCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString трека',
      many: '$nString треков',
      few: '$nString трека',
      one: '$nString трек',
    );
    return '$_temp0';
  }

  @override
  String folderCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString папки',
      many: '$nString папок',
      few: '$nString папки',
      one: '$nString папка',
    );
    return '$_temp0';
  }

  @override
  String coversFound(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Найдено $nString обложки',
      many: 'Найдено $nString обложек',
      few: 'Найдено $nString обложки',
      one: 'Найдена $nString обложка',
    );
    return '$_temp0';
  }

  @override
  String filesSkipped(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Пропущено $nString файла',
      many: 'Пропущено $nString файлов',
      few: 'Пропущено $nString файла',
      one: 'Пропущен $nString файл',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Назад';

  @override
  String get songs => 'Треки';

  @override
  String get artists => 'Исполнители';

  @override
  String get genres => 'Жанры';

  @override
  String get allFilter => 'Все';

  @override
  String get allSongs => 'Все';

  @override
  String get favorites => 'Избранное';

  @override
  String get mineFilter => 'Мои';

  @override
  String get automaticFilter => 'Автоматические';

  @override
  String get addFavorite => 'Добавить в избранное';

  @override
  String get removeFavorite => 'Убрать из избранного';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortRecent => 'Недавние';

  @override
  String get sortAZ => 'От А до Я';

  @override
  String get sortArtist => 'Исполнитель';

  @override
  String get sortYear => 'Год';

  @override
  String get sortMostTracks => 'Больше треков';

  @override
  String get columnTitle => 'Название';

  @override
  String get columnAlbum => 'Альбом';

  @override
  String get columnDuration => 'Длительность';

  @override
  String get columnFormat => 'Формат';

  @override
  String get viewGrid => 'Сетка';

  @override
  String get viewList => 'Список';

  @override
  String get searchHint => 'Поиск в медиатеке';

  @override
  String get searchSongsHint => 'Поиск треков';

  @override
  String get searchArtistsHint => 'Поиск исполнителей';

  @override
  String get searchGenresHint => 'Поиск жанров';

  @override
  String get searchAlbumsHint => 'Поиск альбомов';

  @override
  String get searchFoldersHint => 'Поиск папок';

  @override
  String get searchAllHint => 'Треки, альбомы, исполнители или папки';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String noResults(String query) {
    return 'По запросу «$query» ничего не найдено';
  }

  @override
  String get searchPrompt => 'Начните вводить, чтобы искать в медиатеке.';

  @override
  String get bestResult => 'Лучший результат';

  @override
  String get playAll => 'Воспроизвести все';

  @override
  String get kindArtist => 'Исполнитель';

  @override
  String get kindAlbum => 'Альбом';

  @override
  String get kindSong => 'Трек';

  @override
  String get nothingHere => 'Здесь пока ничего нет.';

  @override
  String get noGenre => 'Без жанра';

  @override
  String get fileUnavailable => 'Этот файл сейчас недоступен';

  @override
  String get nothingAvailable => 'Эти треки недоступны. Диск подключён?';

  @override
  String get watchFolders => 'Следить за изменениями в папках';

  @override
  String get watchFoldersBody =>
      'Находит новые, изменённые и удалённые файлы, пока плеер открыт.';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get importPlaylist => 'Импортировать плейлист';

  @override
  String get exportPlaylist => 'Экспортировать плейлист';

  @override
  String get choosePlaylistCover => 'Выбрать обложку';

  @override
  String get removePlaylistCover => 'Убрать обложку';

  @override
  String get coverUnreadable => 'Не удалось прочитать это изображение';

  @override
  String get renamePlaylist => 'Переименовать';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String deletePlaylistBody(String name) {
    return 'Удалить «$name»? Музыкальные файлы останутся на месте.';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get create => 'Создать';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get removeFromPlaylist => 'Убрать из плейлиста';

  @override
  String get moveUp => 'Выше';

  @override
  String get moveDown => 'Ниже';

  @override
  String get dragToReorder => 'Перетащите, чтобы изменить порядок';

  @override
  String get autoFavorites => 'Избранное';

  @override
  String get autoMostPlayed => 'Часто слушаемые';

  @override
  String get autoRecent => 'Недавно добавленные';

  @override
  String get automaticSuffix => 'автоматический';

  @override
  String exportFailed(String error) {
    return 'Не удалось записать файл: $error';
  }

  @override
  String importFailed(String error) {
    return 'Не удалось прочитать файл: $error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d дн $h ч';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n исполнителя',
      many: '$n исполнителей',
      few: '$n исполнителя',
      one: '$n исполнитель',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n жанра',
      many: '$n жанров',
      few: '$n жанра',
      one: '$n жанр',
    );
    return '$_temp0';
  }

  @override
  String playlistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n плейлиста',
      many: '$n плейлистов',
      few: '$n плейлиста',
      one: '$n плейлист',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n файла',
      many: '$n файлов',
      few: '$n файла',
      one: '$n файл',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n изменения',
      many: '$n изменений',
      few: '$n изменения',
      one: '$n изменение',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Импортировано $n трека',
      many: 'Импортировано $n треков',
      few: 'Импортировано $n трека',
      one: 'Импортирован $n трек',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Пропущено $n сетевого адреса',
      many: 'Пропущено $n сетевых адресов',
      few: 'Пропущено $n сетевых адреса',
      one: 'Пропущен $n сетевой адрес',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => 'Текст';

  @override
  String get coverTab => 'Обложка';

  @override
  String get noLyrics => 'У этого трека нет текста';

  @override
  String get lyricsSynced => 'синхронизирован';

  @override
  String get lyricsUnsynced => 'не синхронизирован';

  @override
  String get lyricsEmbedded => 'В тегах';

  @override
  String get lyricsTiming => 'Настроить время текста';

  @override
  String get lyricsEarlier => 'Показывать текст раньше';

  @override
  String get lyricsLater => 'Показывать текст позже';

  @override
  String get lyricsResetTiming => 'Сбросить время';

  @override
  String get withLyrics => 'С текстом';

  @override
  String get upNext => 'Далее';

  @override
  String get clearQueue => 'Очистить';

  @override
  String get saveAsPlaylist => 'Сохранить как плейлист';

  @override
  String get detailAlbum => 'Альбом';

  @override
  String get detailGenre => 'Жанр';

  @override
  String get detailFile => 'Файл';

  @override
  String get detailCover => 'Обложка';

  @override
  String get detailFolder => 'Папка';

  @override
  String get coverEmbedded => 'Встроенная';

  @override
  String get coverGenerated => 'Созданная';

  @override
  String secondsOffset(String value) {
    return '$value с';
  }

  @override
  String playlistSaved(String name) {
    return 'Сохранено как «$name»';
  }

  @override
  String get settingsPlayback => 'Воспроизведение';

  @override
  String get settingsEqualizer => 'Эквалайзер';

  @override
  String get equalizerOn => 'Использовать эквалайзер';

  @override
  String get equalizerHint =>
      'Немного снижает общую громкость, чтобы оставить запас для усиленных полос и звук не искажался.';

  @override
  String get equalizerPresets => 'Предустановки';

  @override
  String get equalizerCustom => 'Своя';

  @override
  String get equalizerFlat => 'Без изменений';

  @override
  String get equalizerRock => 'Рок';

  @override
  String get equalizerPop => 'Поп';

  @override
  String get equalizerJazz => 'Джаз';

  @override
  String get equalizerClassical => 'Классика';

  @override
  String get equalizerElectronic => 'Электроника';

  @override
  String get equalizerBass => 'Больше басов';

  @override
  String get equalizerTreble => 'Больше высоких';

  @override
  String get equalizerVocal => 'Вокал';

  @override
  String equalizerHz(String value) {
    return '$value Гц';
  }

  @override
  String equalizerKhz(String value) {
    return '$value кГц';
  }

  @override
  String equalizerGain(String value) {
    return '$value дБ';
  }

  @override
  String get settingsLibrary => 'Медиатека';

  @override
  String get settingsLyrics => 'Тексты';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsShortcuts => 'Сочетания клавиш';

  @override
  String get settingsAbout => 'О программе';

  @override
  String get rememberSession => 'Запоминать последний трек';

  @override
  String get rememberSessionHint =>
      'Открывает очередь с места остановки, на паузе.';

  @override
  String get playWholeList => 'Воспроизводить весь список при выборе трека';

  @override
  String get playWholeListHint =>
      'Если выключено, играет только выбранный трек.';

  @override
  String get closeNote =>
      'При закрытии окна плеер завершается, и музыка останавливается.';

  @override
  String get stopAfterTrack => 'Остановить после этого трека';

  @override
  String get cancelStopAfter => 'Продолжить после этого трека';

  @override
  String get showInFiles => 'Показать в файловом менеджере';

  @override
  String get keepAwake =>
      'Не давать компьютеру засыпать во время воспроизведения';

  @override
  String get keepAwakeHint =>
      'Экран не гаснет, и компьютер не уходит в сон сам. На паузе всё работает как обычно.';

  @override
  String get keepAwakeReason => 'Воспроизведение музыки';

  @override
  String get notifyTrack => 'Сообщать о смене трека';

  @override
  String get notifyTrackHint =>
      'Показывает название и исполнителя в системном уведомлении.';

  @override
  String get shuffleOrder => 'Перемешать порядок';

  @override
  String get playlistShuffled => 'Порядок перемешан';

  @override
  String get removeDuplicates => 'Убрать дубликаты';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Убрано $count дубликата',
      many: 'Убрано $count дубликатов',
      few: 'Убрано $count дубликата',
      one: 'Убран $count дубликат',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Отменить';

  @override
  String get gapless => 'Воспроизводить без пауз между треками';

  @override
  String get gaplessHint =>
      'Если выключено, вывод звука закрывается и открывается между треками.';

  @override
  String get crossfade => 'Плавный переход';

  @override
  String get crossfadeOff => 'Выключен';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get crossfadeHint =>
      'Композиции накладываются при смене. Идущие подряд с одного альбома играют без паузы.';

  @override
  String get fadeOnPause => 'Плавная пауза';

  @override
  String get fadeOnPauseHint =>
      'Звук плавно стихает при паузе и возвращается при продолжении.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => 'Выкл.';

  @override
  String get replayGainTrack => 'Трек';

  @override
  String get replayGainAlbum => 'Альбом';

  @override
  String get replayGainHint =>
      'Выравнивает громкость по значениям из тегов файла. Режим «Альбом» сохраняет разницу внутри альбома. Файлы без этих тегов играют без изменений.';

  @override
  String get libraryFolders => 'Папки медиатеки';

  @override
  String get watchFoldersSetting => 'Следить за изменениями в папках';

  @override
  String get watchFoldersHint =>
      'Новые, изменённые и удалённые файлы появляются, пока плеер открыт.';

  @override
  String get refreshOnOpen => 'Обновлять при запуске';

  @override
  String get refreshOnOpenHint => 'Проверяет папки при каждом запуске плеера.';

  @override
  String get refreshNow => 'Обновить сейчас';

  @override
  String get lyricsFiles => 'Искать файлы .lrc и .srt';

  @override
  String get lyricsFilesHint => 'Рядом с музыкой, с тем же именем.';

  @override
  String get lyricsEmbeddedSetting => 'Использовать встроенные тексты';

  @override
  String get lyricsEmbeddedHint => 'Из тегов файла, когда нет файла с текстом.';

  @override
  String get themeSetting => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeSystem => 'Системная';

  @override
  String get dynamicColor => 'Динамический цвет системы';

  @override
  String get dynamicColorHint =>
      'Использует цвета обоев, когда система их предоставляет.';

  @override
  String get accentSetting => 'Акцентный цвет';

  @override
  String get accentDefault => 'По умолчанию';

  @override
  String get accentCoral => 'Коралловый';

  @override
  String get accentAmber => 'Янтарный';

  @override
  String get accentGreen => 'Зелёный';

  @override
  String get accentTeal => 'Бирюзовый';

  @override
  String get accentBlue => 'Синий';

  @override
  String get accentPurple => 'Фиолетовый';

  @override
  String get densitySetting => 'Плотность списков';

  @override
  String get densityComfortable => 'Свободная';

  @override
  String get densityCompact => 'Компактная';

  @override
  String get textSizeSetting => 'Размер текста';

  @override
  String get reduceMotion => 'Меньше анимации';

  @override
  String get reduceMotionHint =>
      'Отключает прокрутку текста и другие анимации.';

  @override
  String get resetShortcuts => 'Восстановить по умолчанию';

  @override
  String get mediaKeysNote =>
      'Мультимедийные клавиши (воспроизведение, пауза, следующий, предыдущий) работают без настройки.';

  @override
  String get commandPlayPause => 'Воспроизведение и пауза';

  @override
  String get commandSeekBack => 'Назад на 5 секунд';

  @override
  String get commandSeekForward => 'Вперёд на 5 секунд';

  @override
  String get commandPrevious => 'Предыдущий трек';

  @override
  String get commandNext => 'Следующий трек';

  @override
  String get commandMute => 'Без звука';

  @override
  String get commandSearch => 'Поиск';

  @override
  String get commandLyrics => 'Открыть и закрыть текст';

  @override
  String get commandQueue => 'Открыть и закрыть очередь';

  @override
  String get keySpace => 'Пробел';

  @override
  String changeShortcut(String command) {
    return 'Изменить сочетание: $command';
  }

  @override
  String get pressKeys => 'Нажмите новые клавиши. Esc — отмена.';

  @override
  String shortcutInUse(String command) {
    return 'Уже используется: $command';
  }

  @override
  String get aboutDescription =>
      'Воспроизводит файлы на вашем компьютере. Без учётной записи, стриминга и слежки: то, что вы слушаете, остаётся у вас.';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get licenseLabel => 'Лицензия: Apache 2.0';

  @override
  String get thirdPartyLicenses => 'Полные тексты лицензий';

  @override
  String get builtWithClaude => 'Разработано с помощью Claude Code.';

  @override
  String get reportIssue => 'Сообщить о проблеме на GitHub';

  @override
  String get designInspiration => 'Источники вдохновения для дизайна';

  @override
  String get dartPackagesLabel => 'Лицензии: пакеты Dart';

  @override
  String get systemLibrariesLabel => 'Лицензии: системные библиотеки';

  @override
  String get interfaceAssetsLabel => 'Лицензии: значки';

  @override
  String get keepLogs => 'Вести журналы';

  @override
  String get keepLogsHint =>
      'Для расследования проблем. В них есть названия треков и пути, и они остаются на этом компьютере.';

  @override
  String get aboutSupport => 'Поддержка';

  @override
  String get openDataFolder => 'Открыть папку с данными';

  @override
  String get copySupportInfo => 'Скопировать сведения для поддержки';

  @override
  String get supportInfoCopied => 'Скопировано';

  @override
  String addedToPlaylist(String name) {
    return 'Добавлено в «$name»';
  }

  @override
  String get addTracks => 'Добавить треки';

  @override
  String addTracksConfirm(int n) {
    return 'Добавить: $n';
  }

  @override
  String get alreadyInPlaylist => 'Уже в этом плейлисте';

  @override
  String get searchTracksHint => 'Поиск треков';

  @override
  String get playlistEmptyHint =>
      'Этот плейлист пуст. Нажмите «Добавить треки», чтобы заполнить его.';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Добавлено $n трека',
      many: 'Добавлено $n треков',
      few: 'Добавлено $n трека',
      one: 'Добавлен $n трек',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get yourLibrary => 'Ваша медиатека';

  @override
  String get rediscover => 'Вспомнить';

  @override
  String get yourPlaylists => 'Ваши плейлисты';

  @override
  String get filterList => 'Поиск в этом списке';

  @override
  String get recentSearches => 'Недавние запросы';

  @override
  String get clearRecent => 'Очистить';

  @override
  String get removeRecent => 'Убрать из недавних запросов';

  @override
  String get browseGenres => 'Обзор по жанрам';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get pinned => 'Закреплено';

  @override
  String get pinnedHeading => 'Закреплённые';

  @override
  String get yourMixes => 'Ваши миксы';

  @override
  String get dailyMix => 'Микс дня';

  @override
  String genreMix(String genre) {
    return 'Микс: $genre';
  }

  @override
  String get openTrackPage => 'Открыть страницу трека';

  @override
  String get trackDetails => 'Сведения';

  @override
  String get overview => 'Обзор';

  @override
  String get singles => 'Отдельные треки';

  @override
  String singlesHint(String tracks) {
    return '$tracks, единственные в своём альбоме';
  }

  @override
  String get expandRail => 'Показать названия';

  @override
  String get collapseRail => 'Скрыть названия';

  @override
  String get playerSize => 'Размер плеера';

  @override
  String get modeFull => 'Полный';

  @override
  String get modeCompact => 'Компактный';

  @override
  String get modeMini => 'Мини-плеер';

  @override
  String get exitMini => 'Выйти из мини-плеера';

  @override
  String get autoTopRated => 'С высокой оценкой';

  @override
  String get rateTrack => 'Оценить…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => 'Убрать оценку';

  @override
  String get dynamicMixStart => 'Запустить динамический микс';

  @override
  String get dynamicMixStop => 'Остановить динамический микс';

  @override
  String get columnRating => 'Оценка';

  @override
  String get useRatings => 'Использовать оценки звёздами';

  @override
  String get useRatingsHint =>
      'Показывает звёзды рядом с сердечком. Если выключено, ваши оценки сохраняются, а треки с одной звездой по-прежнему не попадают в миксы.';

  @override
  String markAll(int n) {
    return 'Выбрать все ($n)';
  }

  @override
  String get clearSelection => 'Снять выбор';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Создать: $n трека',
      many: 'Создать: $n треков',
      few: 'Создать: $n трека',
      one: 'Создать: $n трек',
    );
    return '$_temp0';
  }
}
