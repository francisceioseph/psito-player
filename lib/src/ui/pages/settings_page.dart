// lib/src/ui/pages/settings_page.dart
//
// Os Ajustes: as categorias à esquerda e o painel à direita. Sem largura para os
// dois, as categorias viram uma fileira em cima.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/player_localizations.dart';
import '../../library/library_controller.dart';
import '../../player/engine.dart';
import '../../player/equalizer.dart';
import '../../player/player_shortcuts.dart';
import '../../settings/player_settings.dart';
import '../../third_party.dart';
import '../../version.dart';
import '../atoms/app_icon.dart';
import '../molecules/chip_bar.dart';
import '../molecules/settings_rows.dart';
import '../molecules/shortcut_row.dart';
import '../organisms/equalizer_panel.dart';
import '../templates/page_template.dart';

const issuesUrl = 'https://github.com/francisceioseph/psito-player/issues';
const spotifyDesignUrl =
    'https://www.figma.com/community/file/1376999463181735262/spotify-redesign';
const appleMusicDesignUrl =
    'https://www.figma.com/community/file/1622299389536274468';

enum SettingsCategory {
  playback,
  equalizer,
  library,
  lyrics,
  appearance,
  shortcuts,
  about,
}

class SettingsPage extends StatefulWidget {
  /// A partir daqui, as categorias ficam ao lado.
  static const sideMinWidth = 600.0;

  final PlayerSettings settings;
  final LibraryController library;

  /// Onde a biblioteca fica no disco.
  final String dataDir;
  final VoidCallback onOpenFolders;
  final VoidCallback onOpenDataFolder;
  final ValueChanged<String> onOpenLink;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.library,
    required this.dataDir,
    required this.onOpenFolders,
    required this.onOpenDataFolder,
    required this.onOpenLink,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsCategory _category = SettingsCategory.playback;

  static (IconData, String) _describe(
    SettingsCategory category,
    PlayerLocalizations l,
  ) => switch (category) {
    SettingsCategory.playback => (
      Icons.play_circle_rounded,
      l.settingsPlayback,
    ),
    SettingsCategory.equalizer => (
      Icons.equalizer_rounded,
      l.settingsEqualizer,
    ),
    SettingsCategory.library => (
      Icons.library_music_rounded,
      l.settingsLibrary,
    ),
    SettingsCategory.lyrics => (Icons.lyrics_rounded, l.settingsLyrics),
    SettingsCategory.appearance => (
      Icons.palette_rounded,
      l.settingsAppearance,
    ),
    SettingsCategory.shortcuts => (Icons.keyboard_rounded, l.settingsShortcuts),
    SettingsCategory.about => (Icons.info_rounded, l.settingsAbout),
  };

  List<Widget> _section() => switch (_category) {
    SettingsCategory.playback => _playback(),
    SettingsCategory.equalizer => _equalizer(),
    SettingsCategory.library => _library(),
    SettingsCategory.lyrics => _lyrics(),
    SettingsCategory.appearance => _appearance(),
    SettingsCategory.shortcuts => _shortcuts(),
    SettingsCategory.about => _about(),
  };

  List<Widget> _playback() {
    final l = context.l10n;
    final s = widget.settings;
    return [
      SettingsSwitch(
        title: l.rememberSession,
        hint: l.rememberSessionHint,
        value: s.rememberSession,
        onChanged: (v) => s.rememberSession = v,
      ),
      SettingsSwitch(
        title: l.playWholeList,
        hint: l.playWholeListHint,
        value: s.playWholeList,
        onChanged: (v) => s.playWholeList = v,
      ),
      SettingsSwitch(
        title: l.gapless,
        hint: l.gaplessHint,
        value: s.gapless,
        onChanged: (v) => s.gapless = v,
      ),
      SettingsSwitch(
        title: l.keepAwake,
        hint: l.keepAwakeHint,
        value: s.keepAwake,
        onChanged: (v) => s.keepAwake = v,
      ),
      SettingsSwitch(
        title: l.notifyTrack,
        hint: l.notifyTrackHint,
        value: s.notifyTrack,
        onChanged: (v) => s.notifyTrack = v,
      ),
      SettingsLabel(l.replayGain),
      SegmentedButton<PlayerReplayGain>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: PlayerReplayGain.off,
            label: Text(l.replayGainOff),
          ),
          ButtonSegment(
            value: PlayerReplayGain.track,
            label: Text(l.replayGainTrack),
          ),
          ButtonSegment(
            value: PlayerReplayGain.album,
            label: Text(l.replayGainAlbum),
          ),
        ],
        selected: {s.replayGain},
        onSelectionChanged: (v) => s.replayGain = v.first,
      ),
      SettingsNote(l.replayGainHint),
      SettingsNote(l.closeNote),
    ];
  }

  String _presetName(EqualizerPreset? preset, PlayerLocalizations l) =>
      switch (preset) {
        null => l.equalizerCustom,
        EqualizerPreset.flat => l.equalizerFlat,
        EqualizerPreset.rock => l.equalizerRock,
        EqualizerPreset.pop => l.equalizerPop,
        EqualizerPreset.jazz => l.equalizerJazz,
        EqualizerPreset.classical => l.equalizerClassical,
        EqualizerPreset.electronic => l.equalizerElectronic,
        EqualizerPreset.bass => l.equalizerBass,
        EqualizerPreset.treble => l.equalizerTreble,
        EqualizerPreset.vocal => l.equalizerVocal,
      };

  List<Widget> _equalizer() {
    final l = context.l10n;
    final s = widget.settings;
    final preset = EqualizerPreset.of(s.equalizerGains);
    return [
      SettingsSwitch(
        title: l.equalizerOn,
        hint: l.equalizerHint,
        value: s.equalizerOn,
        onChanged: (v) => s.equalizerOn = v,
      ),
      SettingsLabel(l.equalizerPresets),
      ChipBar<EqualizerPreset?>(
        wrap: true,
        options: [
          for (final option in EqualizerPreset.values)
            (option, _presetName(option, l)),
          if (preset == null) (null, l.equalizerCustom),
        ],
        selected: preset,
        onSelected: s.equalizerOn
            ? (v) {
                if (v != null) s.equalizerGains = v.gains;
              }
            : null,
      ),
      const SizedBox(height: 16),
      EqualizerPanel(
        gains: s.equalizerGains,
        onChanged: s.equalizerOn ? s.setEqualizerBand : null,
      ),
    ];
  }

  List<Widget> _library() {
    final l = context.l10n;
    final s = widget.settings;
    final library = widget.library;
    return [
      SettingsAction(
        icon: Icons.folder_rounded,
        title: l.libraryFolders,
        onTap: widget.onOpenFolders,
      ),
      SettingsSwitch(
        title: l.watchFoldersSetting,
        hint: l.watchFoldersHint,
        value: library.watching,
        onChanged: (v) => unawaited(library.setWatching(v)),
      ),
      SettingsSwitch(
        title: l.useRatings,
        hint: l.useRatingsHint,
        value: s.useRatings,
        onChanged: (v) => s.useRatings = v,
      ),
      SettingsSwitch(
        title: l.refreshOnOpen,
        hint: l.refreshOnOpenHint,
        value: s.refreshOnOpen,
        onChanged: (v) => s.refreshOnOpen = v,
      ),
      SettingsAction(
        icon: Icons.refresh_rounded,
        title: l.refreshNow,
        onTap: () => unawaited(library.checkFolders()),
      ),
    ];
  }

  List<Widget> _lyrics() {
    final l = context.l10n;
    final s = widget.settings;
    return [
      SettingsSwitch(
        title: l.lyricsFiles,
        hint: l.lyricsFilesHint,
        value: s.lyricsFiles,
        onChanged: (v) => s.lyricsFiles = v,
      ),
      SettingsSwitch(
        title: l.lyricsEmbeddedSetting,
        hint: l.lyricsEmbeddedHint,
        value: s.lyricsEmbedded,
        onChanged: (v) => s.lyricsEmbedded = v,
      ),
    ];
  }

  String _accentName(AccentChoice? accent, PlayerLocalizations l) =>
      switch (accent) {
        null => l.accentDefault,
        AccentChoice.coral => l.accentCoral,
        AccentChoice.amber => l.accentAmber,
        AccentChoice.green => l.accentGreen,
        AccentChoice.teal => l.accentTeal,
        AccentChoice.blue => l.accentBlue,
        AccentChoice.purple => l.accentPurple,
      };

  List<Widget> _appearance() {
    final l = context.l10n;
    final s = widget.settings;
    final percent = (s.textScale * 100).round();
    return [
      SettingsLabel(l.themeSetting),
      SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
          ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
          ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
        ],
        selected: {s.themeMode},
        onSelectionChanged: (v) => s.themeMode = v.first,
      ),
      const SizedBox(height: 8),
      SettingsSwitch(
        title: l.dynamicColor,
        hint: l.dynamicColorHint,
        value: false,
        onChanged: null,
      ),
      SettingsLabel(l.accentSetting),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final accent in [null, ...AccentChoice.values])
            _AccentSwatch(
              color: accent?.color,
              name: _accentName(accent, l),
              selected: s.accent == accent,
              onTap: () => s.accent = accent,
            ),
        ],
      ),
      SettingsLabel(l.densitySetting),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: false, label: Text(l.densityComfortable)),
          ButtonSegment(value: true, label: Text(l.densityCompact)),
        ],
        selected: {s.compact},
        onSelectionChanged: (v) => s.compact = v.first,
      ),
      SettingsLabel('${l.textSizeSetting}: $percent%'),
      Semantics(
        label: l.textSizeSetting,
        child: Slider(
          value: s.textScale,
          min: PlayerSettings.minTextScale,
          max: PlayerSettings.maxTextScale,
          divisions: 9,
          label: '$percent%',
          onChanged: (v) => s.textScale = v,
        ),
      ),
      SettingsSwitch(
        title: l.reduceMotion,
        hint: l.reduceMotionHint,
        value: s.reduceMotion,
        onChanged: (v) => s.reduceMotion = v,
      ),
    ];
  }

  Future<void> _editShortcut(PlayerCommand command) async {
    final s = widget.settings;
    final combo = await askShortcut(
      context,
      command: command,
      conflict: (combo) => s.conflict(command, combo),
    );
    if (combo != null) s.setShortcut(command, combo);
  }

  List<Widget> _shortcuts() {
    final l = context.l10n;
    final s = widget.settings;
    return [
      for (final command in PlayerCommand.values)
        ShortcutRow(
          command: command,
          combo: s.shortcuts[command]!,
          onEdit: () => unawaited(_editShortcut(command)),
        ),
      SettingsNote(l.mediaKeysNote),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(l.resetShortcuts),
          onPressed: s.resetShortcuts,
        ),
      ),
    ];
  }

  Future<void> _copySupportInfo() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(
      ClipboardData(
        text: [
          'Psito Player $playerVersion',
          Platform.operatingSystemVersion,
          'Dart ${Platform.version.split(' ').first}',
          widget.dataDir,
        ].join('\n'),
      ),
    );
    messenger?.showSnackBar(SnackBar(content: Text(l.supportInfoCopied)));
  }

  List<Widget> _about() {
    final l = context.l10n;
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          const AppIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Psito Player', style: theme.textTheme.titleLarge),
                Text(l.versionLabel(playerVersion)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(l.aboutDescription),
      const SizedBox(height: 8),
      Text(l.licenseLabel),
      SettingsCallout(
        icon: Icons.auto_awesome_rounded,
        text: l.builtWithClaude,
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.tonalIcon(
          icon: const Icon(Icons.bug_report_rounded, size: 18),
          label: Text(l.reportIssue),
          onPressed: () => widget.onOpenLink(issuesUrl),
        ),
      ),
      SettingsLabel(l.designInspiration),
      SettingsAction(
        icon: Icons.open_in_new_rounded,
        title: 'Spotify Redesign',
        hint: 'Juxtopposed, Figma Community',
        onTap: () => widget.onOpenLink(spotifyDesignUrl),
      ),
      SettingsAction(
        icon: Icons.open_in_new_rounded,
        title: 'Apple Music Redesign',
        hint: 'Juxtopposed, Figma Community',
        onTap: () => widget.onOpenLink(appleMusicDesignUrl),
      ),
      SettingsLabel(l.dartPackagesLabel),
      _licenses(dartPackages),
      SettingsLabel(l.systemLibrariesLabel),
      _licenses(systemLibraries),
      SettingsLabel(l.interfaceAssetsLabel),
      _licenses(interfaceAssets),
      const SizedBox(height: 16),
      SettingsTable(
        children: [
          SettingsTableRow(
            title: l.thirdPartyLicenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Psito Player',
              applicationVersion: playerVersion,
            ),
          ),
        ],
      ),
      SettingsLabel(l.aboutSupport),
      SettingsSwitch(
        title: l.keepLogs,
        hint: l.keepLogsHint,
        value: widget.settings.logs,
        onChanged: (v) => widget.settings.logs = v,
      ),
      SettingsAction(
        icon: Icons.folder_open_rounded,
        title: l.openDataFolder,
        hint: prettyPath(widget.dataDir, Platform.environment['HOME']),
        onTap: widget.onOpenDataFolder,
      ),
      SettingsAction(
        icon: Icons.content_copy_rounded,
        title: l.copySupportInfo,
        onTap: () => unawaited(_copySupportInfo()),
      ),
    ];
  }

  Widget _licenses(List<(String, String)> items) => SettingsTable(
    children: [
      for (final (name, license) in items)
        SettingsTableRow(title: name, value: license),
    ],
  );

  void _select(SettingsCategory category) =>
      setState(() => _category = category);

  Widget _list(List<Widget> children) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: PageTemplate.padding),
    children: children,
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = Padding(
      padding: const EdgeInsets.all(PageTemplate.padding),
      child: Text(l.settings, style: Theme.of(context).textTheme.headlineSmall),
    );
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < SettingsPage.sideMinWidth) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PageTemplate.padding,
                    ),
                    child: ChipBar<SettingsCategory>(
                      options: [
                        for (final category in SettingsCategory.values)
                          (category, _describe(category, l).$2),
                      ],
                      selected: _category,
                      onSelected: _select,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(PageTemplate.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _section(),
                    ),
                  ),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      for (final category in SettingsCategory.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ListTile(
                            mouseCursor: SystemMouseCursors.click,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(_describe(category, l).$1),
                            title: Text(_describe(category, l).$2),
                            selected: category == _category,
                            onTap: () => _select(category),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _list([
                      const SizedBox(height: PageTemplate.padding),
                      Text(
                        _describe(_category, l).$2,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ..._section(),
                      const SizedBox(height: PageTemplate.padding),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  /// Null é a cor do tema de quem abriu o player.
  final Color? color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.primary;
    final mark = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? scheme.surface
        : scheme.scrim;
    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        excludeSemantics: true,
        child: Material(
          color: fill,
          shape: CircleBorder(
            side: selected
                ? BorderSide(color: scheme.onSurface, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 40,
              child: color == null
                  ? Icon(Icons.auto_awesome_rounded, size: 18, color: mark)
                  : selected
                  ? Icon(Icons.check_rounded, size: 20, color: mark)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
