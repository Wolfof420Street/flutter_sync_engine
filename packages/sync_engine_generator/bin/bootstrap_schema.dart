import 'dart:convert';
import 'dart:io';

/// Writes a reviewed, source-controlled additive-migration baseline.
///
/// Example:
/// `dart run sync_engine_generator:bootstrap_schema lib/sync_engine_schema.json Task id,title,tags`
void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
        'Usage: bootstrap_schema <output.json> <Type> <field,field,...>');
    exitCode = 64;
    return;
  }
  final output = File(args[0]);
  final manifest = output.existsSync()
      ? jsonDecode(output.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  if (manifest.containsKey(args[1])) {
    stderr.writeln('Manifest already contains a baseline for ${args[1]}.');
    exitCode = 65;
    return;
  }
  output.parent.createSync(recursive: true);
  manifest[args[1]] =
      args[2].split(',').where((field) => field.isNotEmpty).toList();
  output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
}
