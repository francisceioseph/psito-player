// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'src/logging.dart';
import 'src/player/single_instance.dart';
import 'standalone_app.dart';

Future<void> main(List<String> args) async {
  silenceLogsInRelease();
  final paths = openedFiles(args);
  final instance = await SingleInstance.acquire(paths);
  // Outro player já recebeu os arquivos. Sem o exit, o runner em GTK ficaria
  // aberto, sem janela
  if (instance == null) exit(0);
  runApp(StandaloneApp(initialPaths: paths, openRequests: instance.opens));
}
