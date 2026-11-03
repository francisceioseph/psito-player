// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class PlayerLocalizationsZh extends PlayerLocalizations {
  PlayerLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '音乐播放器';

  @override
  String get noTrack => '没有曲目';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get progress => '进度';

  @override
  String get volume => '音量';

  @override
  String get home => '主页';

  @override
  String get library => '音乐库';

  @override
  String get playlists => '播放列表';

  @override
  String get folders => '文件夹';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String engineUnavailable(Object error) {
    return '音频引擎不可用：$error';
  }

  @override
  String get openFailed => '无法播放此文件';

  @override
  String get addFolder => '添加文件夹';

  @override
  String get addMusicFolder => '添加音乐文件夹';

  @override
  String get folderNotVisible => '播放器无法访问此文件夹。请选择主目录或外部磁盘中的文件夹。';

  @override
  String get folderAlreadyAdded => '此文件夹已在音乐库中。';

  @override
  String libraryUnavailable(String error) {
    return '无法打开音乐库：$error';
  }

  @override
  String get albums => '专辑';

  @override
  String get unknownArtist => '未知艺人';

  @override
  String playAlbum(String album) {
    return '播放 $album';
  }

  @override
  String get hasLyrics => '有歌词';

  @override
  String get moreOptions => '更多选项';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '添加到队列';

  @override
  String get removeFromQueue => '从队列中移除';

  @override
  String get queue => '队列';

  @override
  String get queueEmpty => '队列为空';

  @override
  String get close => '关闭';

  @override
  String get shuffle => '随机播放';

  @override
  String get previousTrack => '上一首';

  @override
  String get nextTrack => '下一首';

  @override
  String get repeatOff => '重复：关闭';

  @override
  String get repeatAll => '重复：全部';

  @override
  String get repeatOne => '重复：单曲';

  @override
  String get continueListening => '从上次停止的地方继续';

  @override
  String get continuePlaying => '继续';

  @override
  String stoppedAt(String artist, String position, String duration) {
    return '$artist · 停在 $position / $duration';
  }

  @override
  String get shuffleAll => '随机播放全部';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get seeAll => '查看全部';

  @override
  String get mostPlayed => '最常播放';

  @override
  String get emptyTitle => '你的音乐库是空的';

  @override
  String get emptyBody => '请指定音乐所在的文件夹。播放器直接读取你电脑上的文件，不会向外发送任何内容。';

  @override
  String useFolder(String folder) {
    return '使用 $folder';
  }

  @override
  String get acceptedFormats => '支持的格式';

  @override
  String get scanning => '正在读取音乐库';

  @override
  String get scanSubtitle => '正在读取：已找到的内容现在就可以收听';

  @override
  String scanFiles(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString / $totalString 个文件';
  }

  @override
  String get scanLessThanMinute => '剩余不到一分钟';

  @override
  String scanMinutesLeft(int n) {
    return '大约剩余 $n 分钟';
  }

  @override
  String get pauseScan => '暂停';

  @override
  String get resumeScan => '继续';

  @override
  String get cancelScan => '取消';

  @override
  String get scanKeepsGoing => '离开此页面后读取会继续';

  @override
  String get foundSoFar => '目前已找到';

  @override
  String get updateAll => '全部更新';

  @override
  String get updateFolder => '更新文件夹';

  @override
  String get removeFolder => '从音乐库中移除';

  @override
  String get folderMissing => '未找到磁盘';

  @override
  String get notScanned => '尚未读取';

  @override
  String get scannedJustNow => '刚刚更新';

  @override
  String scannedMinutes(int n) {
    return '$n 分钟前更新';
  }

  @override
  String scannedHours(int n) {
    return '$n 小时前更新';
  }

  @override
  String scannedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天前更新',
      one: '昨天更新',
      zero: '今天更新',
    );
    return '$_temp0';
  }

  @override
  String lengthMinutes(int n) {
    return '$n 分钟';
  }

  @override
  String lengthHours(int h, int m) {
    return '$h 小时 $m 分钟';
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
      other: '$nString 张专辑',
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
      other: '$nString 首曲目',
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
      other: '$nString 个文件夹',
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
      other: '找到 $nString 张封面',
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
      other: '跳过 $nString 个文件',
    );
    return '$_temp0';
  }

  @override
  String get back => '返回';

  @override
  String get songs => '歌曲';

  @override
  String get artists => '艺人';

  @override
  String get genres => '流派';

  @override
  String get allFilter => '全部';

  @override
  String get allSongs => '全部';

  @override
  String get favorites => '收藏';

  @override
  String get mineFilter => '我的';

  @override
  String get automaticFilter => '自动';

  @override
  String get addFavorite => '添加到收藏';

  @override
  String get removeFavorite => '从收藏中移除';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortRecent => '最近';

  @override
  String get sortAZ => 'A 到 Z';

  @override
  String get sortArtist => '艺人';

  @override
  String get sortYear => '年份';

  @override
  String get sortMostTracks => '歌曲最多';

  @override
  String get columnTitle => '标题';

  @override
  String get columnAlbum => '专辑';

  @override
  String get columnDuration => '时长';

  @override
  String get columnFormat => '格式';

  @override
  String get viewGrid => '网格';

  @override
  String get viewList => '列表';

  @override
  String get searchHint => '搜索音乐库';

  @override
  String get searchSongsHint => '搜索歌曲';

  @override
  String get searchArtistsHint => '搜索艺人';

  @override
  String get searchGenresHint => '搜索流派';

  @override
  String get searchAlbumsHint => '搜索专辑';

  @override
  String get searchFoldersHint => '搜索文件夹';

  @override
  String get searchAllHint => '歌曲、专辑、艺人或文件夹';

  @override
  String get searchShortcut => 'Ctrl K';

  @override
  String get clearSearch => '清除搜索';

  @override
  String noResults(String query) {
    return '未找到与“$query”相关的内容';
  }

  @override
  String get searchPrompt => '输入内容以搜索音乐库。';

  @override
  String get bestResult => '最佳结果';

  @override
  String get playAll => '全部播放';

  @override
  String get kindArtist => '艺人';

  @override
  String get kindAlbum => '专辑';

  @override
  String get kindSong => '歌曲';

  @override
  String get nothingHere => '这里还没有内容。';

  @override
  String get noGenre => '无流派';

  @override
  String get fileUnavailable => '此文件暂时不可用';

  @override
  String get nothingAvailable => '这些歌曲不可用。磁盘是否已连接？';

  @override
  String get watchFolders => '监视文件夹变化';

  @override
  String get watchFoldersBody => '在播放器打开时检测新增、更改和删除的文件。';

  @override
  String get newPlaylist => '新建播放列表';

  @override
  String get importPlaylist => '导入播放列表';

  @override
  String get exportPlaylist => '导出播放列表';

  @override
  String get smartRuleField => '字段';

  @override
  String get smartRuleCompare => '比较';

  @override
  String get newSmartPlaylist => '智能播放列表';

  @override
  String get editSmartRules => '编辑规则';

  @override
  String get smartSuffix => '智能';

  @override
  String get ruleGenre => '流派';

  @override
  String get ruleYear => '年份';

  @override
  String get ruleRating => '评分';

  @override
  String get ruleIs => '是';

  @override
  String get ruleIsNot => '不是';

  @override
  String get ruleAtLeast => '至少';

  @override
  String get ruleAtMost => '至多';

  @override
  String get matchAllRules => '全部规则';

  @override
  String get matchAnyRule => '任一规则';

  @override
  String get addRule => '添加规则';

  @override
  String get removeRule => '移除规则';

  @override
  String get smartOrder => '排序';

  @override
  String get orderTitle => '标题';

  @override
  String get orderRecent => '最近添加';

  @override
  String get orderRating => '评分最高';

  @override
  String get orderYear => '最新';

  @override
  String get smartLimit => '歌曲上限';

  @override
  String get noLimit => '不限';

  @override
  String get choosePlaylistCover => '选择封面';

  @override
  String get removePlaylistCover => '移除封面';

  @override
  String get coverUnreadable => '无法读取这张图片';

  @override
  String get renamePlaylist => '重命名';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String deletePlaylistBody(String name) {
    return '删除“$name”？音乐文件会保留在原处。';
  }

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get create => '创建';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get addToPlaylist => '添加到播放列表';

  @override
  String get removeFromPlaylist => '从播放列表中移除';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get dragToReorder => '拖动以调整顺序';

  @override
  String get autoFavorites => '收藏';

  @override
  String get autoMostPlayed => '最常播放';

  @override
  String get autoRecent => '最近添加';

  @override
  String get automaticSuffix => '自动';

  @override
  String exportFailed(String error) {
    return '无法写入文件：$error';
  }

  @override
  String importFailed(String error) {
    return '无法读取文件：$error';
  }

  @override
  String lengthDays(int d, int h) {
    return '$d 天 $h 小时';
  }

  @override
  String artistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 位艺人',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 种流派',
    );
    return '$_temp0';
  }

  @override
  String playlistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个播放列表',
    );
    return '$_temp0';
  }

  @override
  String fileCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个文件',
    );
    return '$_temp0';
  }

  @override
  String folderChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 处更改',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已导入 $n 首歌曲',
    );
    return '$_temp0';
  }

  @override
  String importedRemote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已跳过 $n 个网络地址',
    );
    return '$_temp0';
  }

  @override
  String get lyricsTab => '歌词';

  @override
  String get coverTab => '封面';

  @override
  String get noLyrics => '此曲目没有歌词';

  @override
  String get lyricsSynced => '已同步';

  @override
  String get lyricsUnsynced => '未同步';

  @override
  String get lyricsEmbedded => '在标签中';

  @override
  String get lyricsTiming => '调整歌词时间';

  @override
  String get lyricsEarlier => '提前显示歌词';

  @override
  String get lyricsLater => '延后显示歌词';

  @override
  String get lyricsResetTiming => '重置时间';

  @override
  String get withLyrics => '有歌词';

  @override
  String get upNext => '接下来播放';

  @override
  String get clearQueue => '清空';

  @override
  String get saveAsPlaylist => '保存为播放列表';

  @override
  String get detailAlbum => '专辑';

  @override
  String get detailGenre => '流派';

  @override
  String get detailFile => '文件';

  @override
  String get detailCover => '封面';

  @override
  String get detailFolder => '文件夹';

  @override
  String get coverEmbedded => '内嵌';

  @override
  String get coverGenerated => '自动生成';

  @override
  String secondsOffset(String value) {
    return '$value 秒';
  }

  @override
  String playlistSaved(String name) {
    return '已保存为“$name”';
  }

  @override
  String get settingsPlayback => '播放';

  @override
  String get settingsEqualizer => '均衡器';

  @override
  String get equalizerOn => '使用均衡器';

  @override
  String get equalizerHint => '略微降低整体音量，为增强的频段留出空间，避免声音失真。';

  @override
  String get equalizerPresets => '预设';

  @override
  String get equalizerCustom => '自定义';

  @override
  String get equalizerFlat => '平直';

  @override
  String get equalizerRock => '摇滚';

  @override
  String get equalizerPop => '流行';

  @override
  String get equalizerJazz => '爵士';

  @override
  String get equalizerClassical => '古典';

  @override
  String get equalizerElectronic => '电子';

  @override
  String get equalizerBass => '增强低音';

  @override
  String get equalizerTreble => '增强高音';

  @override
  String get equalizerVocal => '人声';

  @override
  String equalizerHz(String value) {
    return '$value Hz';
  }

  @override
  String equalizerKhz(String value) {
    return '$value kHz';
  }

  @override
  String equalizerGain(String value) {
    return '$value dB';
  }

  @override
  String get settingsLibrary => '音乐库';

  @override
  String get settingsLyrics => '歌词';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsShortcuts => '键盘快捷键';

  @override
  String get settingsAbout => '关于';

  @override
  String get rememberSession => '记住上次播放的曲目';

  @override
  String get rememberSessionHint => '重新打开时，队列停在上次的位置并保持暂停。';

  @override
  String get playWholeList => '选择曲目时播放整个列表';

  @override
  String get playWholeListHint => '关闭后，只播放所选曲目。';

  @override
  String get closeNote => '关闭窗口会退出播放器并停止音乐。';

  @override
  String get stopAfterTrack => '播放完此曲目后停止';

  @override
  String get cancelStopAfter => '播放完此曲目后继续';

  @override
  String get showInFiles => '在文件管理器中显示';

  @override
  String get keepAwake => '播放时保持电脑唤醒';

  @override
  String get keepAwakeHint => '屏幕保持开启，电脑不会自动休眠。暂停后恢复正常。';

  @override
  String get keepAwakeReason => '正在播放音乐';

  @override
  String get notifyTrack => '曲目更换时通知';

  @override
  String get notifyTrackHint => '在系统通知中显示标题和艺人。';

  @override
  String get shuffleOrder => '打乱顺序';

  @override
  String get playlistShuffled => '顺序已打乱';

  @override
  String get removeDuplicates => '移除重复项';

  @override
  String duplicatesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已移除 $count 个重复项',
    );
    return '$_temp0';
  }

  @override
  String get undo => '撤销';

  @override
  String get gapless => '曲目之间无间隙播放';

  @override
  String get gaplessHint => '关闭后，声音输出会在曲目之间关闭再打开。';

  @override
  String get crossfade => '淡入淡出';

  @override
  String get crossfadeOff => '关闭';

  @override
  String seconds(int n) {
    return '$n 秒';
  }

  @override
  String get crossfadeHint => '切换时歌曲相互重叠。同一专辑的连续歌曲仍然无缝播放。';

  @override
  String get fadeOnPause => '暂停时渐变';

  @override
  String get fadeOnPauseHint => '暂停和继续时声音逐渐减弱和恢复。';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainOff => '关闭';

  @override
  String get replayGainTrack => '曲目';

  @override
  String get replayGainAlbum => '专辑';

  @override
  String get replayGainHint => '根据文件标签中的数值平衡音量。“专辑”会保留同一专辑内的差异。没有这些标签的文件按原样播放。';

  @override
  String get libraryFolders => '音乐库文件夹';

  @override
  String get watchFoldersSetting => '监视文件夹变化';

  @override
  String get watchFoldersHint => '在播放器打开时显示新增、更改和删除的文件。';

  @override
  String get refreshOnOpen => '打开时更新';

  @override
  String get refreshOnOpenHint => '每次打开播放器时检查文件夹。';

  @override
  String get refreshNow => '立即更新';

  @override
  String get lyricsFiles => '查找 .lrc 和 .srt 文件';

  @override
  String get lyricsFilesHint => '位于音乐旁边，且名称相同。';

  @override
  String get lyricsEmbeddedSetting => '使用内嵌歌词';

  @override
  String get lyricsEmbeddedHint => '没有歌词文件时，从文件标签中读取。';

  @override
  String get themeSetting => '主题';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get dynamicColor => '系统动态颜色';

  @override
  String get dynamicColorHint => '在系统提供时使用壁纸颜色。';

  @override
  String get accentSetting => '强调色';

  @override
  String get accentDefault => '默认';

  @override
  String get accentCoral => '珊瑚色';

  @override
  String get accentAmber => '琥珀色';

  @override
  String get accentGreen => '绿色';

  @override
  String get accentTeal => '青色';

  @override
  String get accentBlue => '蓝色';

  @override
  String get accentPurple => '紫色';

  @override
  String get densitySetting => '列表密度';

  @override
  String get densityComfortable => '舒适';

  @override
  String get densityCompact => '紧凑';

  @override
  String get textSizeSetting => '文字大小';

  @override
  String get reduceMotion => '减少动画';

  @override
  String get reduceMotionHint => '关闭歌词滚动和其他动画。';

  @override
  String get resetShortcuts => '恢复默认';

  @override
  String get mediaKeysNote => '键盘上的媒体键（播放、暂停、下一首、上一首）无需设置即可使用。';

  @override
  String get commandPlayPause => '播放和暂停';

  @override
  String get commandSeekBack => '后退 5 秒';

  @override
  String get commandSeekForward => '前进 5 秒';

  @override
  String get commandPrevious => '上一首';

  @override
  String get commandNext => '下一首';

  @override
  String get commandMute => '静音';

  @override
  String get commandSearch => '搜索';

  @override
  String get commandLyrics => '打开和关闭歌词';

  @override
  String get commandQueue => '打开和关闭队列';

  @override
  String get keySpace => '空格';

  @override
  String changeShortcut(String command) {
    return '更改快捷键：$command';
  }

  @override
  String get pressKeys => '请按新的按键。按 Esc 取消。';

  @override
  String shortcutInUse(String command) {
    return '已被占用：$command';
  }

  @override
  String get aboutDescription => '播放你电脑上的文件。无需账号，没有流媒体，也没有跟踪：你听什么只有你知道。';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get licenseLabel => '许可证：Apache 2.0';

  @override
  String get thirdPartyLicenses => '完整许可证文本';

  @override
  String get builtWithClaude => '在 Claude Code 的帮助下开发。';

  @override
  String get reportIssue => '在 GitHub 上报告问题';

  @override
  String get designInspiration => '设计灵感';

  @override
  String get dartPackagesLabel => '许可证：Dart 软件包';

  @override
  String get systemLibrariesLabel => '许可证：系统库';

  @override
  String get interfaceAssetsLabel => '许可证：图标';

  @override
  String get keepLogs => '写入日志';

  @override
  String get keepLogsHint => '用于调查问题。日志包含歌曲名称和路径，只保存在这台电脑上。';

  @override
  String get aboutSupport => '支持';

  @override
  String get openDataFolder => '打开数据文件夹';

  @override
  String get copySupportInfo => '复制支持信息';

  @override
  String get supportInfoCopied => '已复制';

  @override
  String addedToPlaylist(String name) {
    return '已添加到“$name”';
  }

  @override
  String get addTracks => '添加歌曲';

  @override
  String addTracksConfirm(int n) {
    return '添加 $n 首';
  }

  @override
  String get alreadyInPlaylist => '已在此播放列表中';

  @override
  String get searchTracksHint => '搜索歌曲';

  @override
  String get playlistEmptyHint => '此播放列表为空。使用“添加歌曲”来填充。';

  @override
  String tracksAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已添加 $n 首歌曲',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => '正在播放';

  @override
  String get yourLibrary => '你的音乐库';

  @override
  String get rediscover => '重新发现';

  @override
  String get yourPlaylists => '你的播放列表';

  @override
  String get filterList => '在此列表中搜索';

  @override
  String get recentSearches => '最近搜索';

  @override
  String get clearRecent => '清除';

  @override
  String get removeRecent => '从最近搜索中移除';

  @override
  String get browseGenres => '按流派浏览';

  @override
  String get pin => '固定';

  @override
  String get unpin => '取消固定';

  @override
  String get pinned => '已固定';

  @override
  String get pinnedHeading => '已固定';

  @override
  String get yourMixes => '你的混音';

  @override
  String get dailyMix => '每日混音';

  @override
  String genreMix(String genre) {
    return '$genre混音';
  }

  @override
  String get openTrackPage => '打开歌曲页面';

  @override
  String get trackDetails => '详情';

  @override
  String get overview => '概览';

  @override
  String get singles => '单曲';

  @override
  String singlesHint(String tracks) {
    return '$tracks，在专辑中独此一首';
  }

  @override
  String get expandRail => '显示名称';

  @override
  String get collapseRail => '隐藏名称';

  @override
  String get playerSize => '播放器大小';

  @override
  String get modeFull => '完整';

  @override
  String get modeCompact => '紧凑';

  @override
  String get modeMini => '迷你播放器';

  @override
  String get exitMini => '退出迷你播放器';

  @override
  String get autoTopRated => '最高评分';

  @override
  String get rateTrack => '评分…';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 星',
    );
    return '$_temp0';
  }

  @override
  String get clearRating => '移除评分';

  @override
  String get dynamicMixStart => '开始动态混音';

  @override
  String get dynamicMixStop => '停止动态混音';

  @override
  String get columnRating => '评分';

  @override
  String get useRatings => '使用星级评分';

  @override
  String get useRatingsHint => '在心形图标旁显示星星。关闭后，你的评分仍会保留，一星歌曲也继续不进入混音。';

  @override
  String markAll(int n) {
    return '全选（$n）';
  }

  @override
  String get clearSelection => '清除选择';

  @override
  String createWithTracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '创建（$n 首歌曲）',
    );
    return '$_temp0';
  }
}
