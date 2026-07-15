import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// Loads a project-local SQLite binary for sandboxed test environments only.
void configureSqliteForTests() {
  final binary =
      File('${Directory.current.path}/../../.dart_tool/sqlite3/libsqlite3.so');
  if (Platform.isLinux && binary.existsSync()) {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open(binary.path));
  }
}
