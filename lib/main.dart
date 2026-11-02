// lib/main.dart
import 'package:flutter/material.dart';

import 'standalone_app.dart';

void main(List<String> args) =>
    runApp(StandaloneApp(initialPaths: openedFiles(args)));
