/// Builders for `sync_engine` annotated domain types.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/syncable_generator.dart';

Builder syncableBuilder(BuilderOptions options) => PartBuilder([
      SyncableGenerator(
        generateDriftTable: options.config['generate_drift_table'] == true,
        schemaManifest: options.config['schema_manifest'] as String? ??
            'lib/sync_engine_schema.json',
        bootstrapSchema: options.config['bootstrap_schema'] == true,
      ),
    ], '.sync.dart');
