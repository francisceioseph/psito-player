// lib/src/third_party.dart
//
// O que o player usa, e a licença de cada um. O THIRD_PARTY_LICENSES.md diz o mesmo,
// e os textos completos vêm do Flutter, que junta os do que foi compilado.
const dartPackages = <(String, String)>[
  ('Flutter', 'BSD-3-Clause'),
  ('audio_metadata_reader', 'MIT'),
  ('dbus', 'MPL-2.0'),
  ('ffi', 'BSD-3-Clause'),
  ('file_selector', 'BSD-3-Clause'),
  ('image', 'MIT'),
  ('intl', 'BSD-3-Clause'),
  ('media_kit', 'MIT'),
  ('media_kit_libs_linux', 'MIT'),
  ('path', 'BSD-3-Clause'),
  ('sqlite3', 'MIT'),
];

/// Vêm do sistema, fora do pacote do player.
const systemLibraries = <(String, String)>[
  ('libmpv', 'GPL-2+ / LGPL-2.1+'),
  ('FFmpeg', 'LGPL-2.1+'),
  ('SQLite', 'Public domain'),
  ('GTK 3', 'LGPL-2.1+'),
];

const interfaceAssets = <(String, String)>[('Material Icons', 'Apache-2.0')];
