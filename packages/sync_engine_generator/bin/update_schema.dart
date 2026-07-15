import 'dart:convert';
import 'dart:io';

/// Updates a reviewed schema baseline after an additive field change.
///
/// The command rejects a missing type or a field removal. It deliberately
/// never runs as a build step: callers review and commit the changed manifest.
///
/// Example:
/// `dart run sync_engine_generator:update_schema lib/sync_engine_schema.json Task id,title,tags`
void main(List<String> args) {
  if (args.length != 3) {
    stderr
        .writeln('Usage: update_schema <output.json> <Type> <field,field,...>');
    exitCode = 64;
    return;
  }

  final output = File(args[0]);
  if (!output.existsSync()) {
    stderr.writeln(
        'Schema manifest ${output.path} does not exist. Run bootstrap_schema first.');
    exitCode = 66;
    return;
  }

  final manifest =
      jsonDecode(output.readAsStringSync()) as Map<String, dynamic>;
  final type = args[1];
  final previous = (manifest[type] as List<dynamic>?)?.cast<String>();
  if (previous == null) {
    stderr.writeln(
        'Manifest has no baseline for $type. Run bootstrap_schema first.');
    exitCode = 66;
    return;
  }

  final current =
      args[2].split(',').where((field) => field.isNotEmpty).toList();
  final removed = previous.toSet().difference(current.toSet());
  if (removed.isNotEmpty) {
    stderr.writeln(
      'Additive-only Drift migration rejected for $type: removed or renamed field(s) ${removed.join(', ')}.',
    );
    exitCode = 65;
    return;
  }

  manifest[type] = current;
  output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
}
