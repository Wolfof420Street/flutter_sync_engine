import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Synthetic, in-memory REST server for the demo. Never use it for user data.
/// State remains available while this process runs, including while clients
/// toggle their simulated network offline and back online.
Future<void> main() async {
  final tasks = <String, Map<String, dynamic>>{};
  final random = Random(7);
  final server = await shelf_io.serve(
    (request) async {
      if (request.method == 'GET' && request.url.path == 'sync') {
        return Response.ok(
          jsonEncode({
            'token': DateTime.now().millisecondsSinceEpoch.toString(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method != 'POST' || request.url.path != 'sync') {
        return Response.notFound('Not found');
      }
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final operations = (body['operations'] as List<dynamic>? ?? const []);
      final results = <Map<String, String>>[];
      for (final raw in operations.cast<Map<String, dynamic>>()) {
        // A deterministic small rejection rate makes rollback visible in demos.
        if (random.nextInt(8) == 0) {
          results.add({
            'disposition': 'rejected',
            'reason': 'Synthetic demo rejection',
          });
          continue;
        }
        final id = raw['entityId'] as String;
        if (raw['kind'] == 'delete') {
          tasks.remove(id);
        } else {
          tasks[id] = (raw['entity'] as Map).cast<String, dynamic>();
        }
        results.add({'disposition': 'accepted'});
      }
      return Response.ok(
        jsonEncode({'results': results, 'tasks': tasks.values.toList()}),
        headers: {'content-type': 'application/json'},
      );
    },
    InternetAddress.loopbackIPv4,
    8080,
  );
  stdout.writeln(
    'Synthetic task server listening on http://${server.address.host}:${server.port}',
  );
  // Keep the standalone demo server alive until the user terminates it.
  await Completer<void>().future;
}
