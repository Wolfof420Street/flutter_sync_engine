import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sync_engine/sync_engine.dart';

/// Emits model, adapter, serializer, and registry wiring for `@Syncable`.
class SyncableGenerator extends GeneratorForAnnotation<Syncable> {
  SyncableGenerator({
    this.generateDriftTable = false,
    required this.schemaManifest,
    this.bootstrapSchema = false,
  });

  final bool generateDriftTable;
  final String schemaManifest;
  final bool bootstrapSchema;
  static final _idChecker =
      TypeChecker.typeNamed(Id, inPackage: 'sync_engine');
  static final _strategyChecker =
      TypeChecker.typeNamed(ConflictStrategy, inPackage: 'sync_engine');

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@Syncable can only annotate a class.',
          element: element);
    }
    final fields = element.fields.where((field) => !field.isStatic).toList();
    if (generateDriftTable) {
      await _validateSchemaManifest(
          buildStep, element.displayName, fields.map((field) => field.displayName).toSet());
    }
    final idFields =
        fields.where((field) => _idChecker.hasAnnotationOf(field)).toList();
    if (idFields.length != 1) {
      throw InvalidGenerationSourceError(
        '@Syncable class ${element.displayName} must declare exactly one @Id() field; found ${idFields.length}.',
        element: element,
      );
    }
    final idField = idFields.single;
    if (_typeName(idField) != 'String') {
      throw InvalidGenerationSourceError(
        '@Id() field ${element.displayName}.${idField.displayName} must have type String.',
        element: idField,
      );
    }

    final type = element.displayName;
    final model = '${type}SyncModel';
    final adapter = '${type}SyncAdapter';
    final serializer = '${type}Serializer';
    final fieldDeclarations = fields
        .map((field) => '  final ${_typeName(field)} ${field.displayName};')
        .join('\n');
    final constructorParameters =
        fields.map((field) => 'required this.${field.displayName}').join(', ');
    final fromEntity =
        fields.map((field) => '${field.displayName}: entity.${field.displayName}').join(', ');
    final modelJson = fields
        .map((field) => "'${field.displayName}': ${_jsonValue(field)}")
        .join(', ');
    final fromJson =
        fields.map((field) => '${field.displayName}: ${_fromJson(field)}').join(', ');
    final lwwFields = fields
        .where((field) => _strategy(field) == ConflictType.lastWriteWins)
        .toList();
    final customFields = fields
        .where((field) => _strategy(field) == ConflictType.custom)
        .toList();
    if (customFields.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '@Syncable class ${element.displayName} uses ConflictType.custom on '
        '${customFields.map((field) => field.displayName).join(', ')}. '
        'Custom merge must be implemented explicitly before generation.',
        element: customFields.first,
      );
    }
    final mergedFields = fields.map(_mergedField).join(',\n      ');
    final localMetadata = lwwFields
        .map((field) =>
            "'${field.displayName}': previous == null || previous.${field.displayName} != entity.${field.displayName} ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId) : previousMetadata['${field.displayName}']!")
        .join(', ');
    final winnerDeclarations = lwwFields
        .map((field) =>
            "final ${field.displayName}Winner = FieldLwwMetadata.winner(local.fieldMetadata['${field.displayName}']!, remote.fieldMetadata['${field.displayName}']!);")
        .join('\n    ');
    final mergedMetadata = lwwFields
        .map((field) => "'${field.displayName}': ${field.displayName}Winner")
        .join(', ');
    final driftTable = generateDriftTable ? _driftTable(type) : '';

    return '''
class $model {
  const $model({required this.vectorClock, required this.nodeId, required this.fieldMetadata, $constructorParameters});

  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
$fieldDeclarations
}

class $serializer {
  const $serializer();

  Map<String, dynamic> toJson($type entity) => <String, dynamic>{${modelJson.isEmpty ? '' : '\n    $modelJson,\n  '}};

  /// Envelope form used by transports that persist field-local LWW metadata.
  Map<String, dynamic> toSyncJson($type entity,
          Map<String, FieldLwwMetadata> fieldMetadata) =>
      <String, dynamic>{
        ...toJson(entity),
        '_fieldMetadata': fieldMetadata.map(
            (key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, FieldLwwMetadata> fieldMetadataFromJson(
          Map<String, dynamic> json) =>
      ((json['_fieldMetadata'] as Map<String, dynamic>?) ?? const {})
          .map((key, value) => MapEntry(
              key, FieldLwwMetadata.fromJson(value as Map<String, dynamic>)));

  $type fromJson(Map<String, dynamic> json) => $type($fromJson);
}

class $adapter implements SyncAdapter<$type> {
  const $adapter();

  @override
  Type get modelType => $type;

  @override
  String get entityType => '${_snakeCase(type)}';

  @override
  String idOf($type entity) => entity.${idField.displayName};

  @override
  Map<String, dynamic> toJson($type entity) => const $serializer().toJson(entity);

  @override
  $type fromJson(Map<String, dynamic> json) => const $serializer().fromJson(json);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite($type entity, $type? previous,
      Map<String, FieldLwwMetadata> previousMetadata, VectorClock clock, String nodeId) =>
      <String, FieldLwwMetadata>{$localMetadata};

  @override
  SyncMergeResult<$type> merge($type local, $type remote, VectorClock localClock,
      VectorClock remoteClock, String localNodeId, String remoteNodeId,
      Map<String, FieldLwwMetadata> localFieldMetadata,
      Map<String, FieldLwwMetadata> remoteFieldMetadata) {
    final merged = mergeModels(
      toModel(local, localClock, localNodeId, localFieldMetadata),
      toModel(remote, remoteClock, remoteNodeId, remoteFieldMetadata),
    );
    return SyncMergeResult($type(${fields.map((field) => '${field.displayName}: merged.${field.displayName}').join(', ')}), merged.fieldMetadata);
  }

  $model toModel($type entity, VectorClock vectorClock, String nodeId,
      Map<String, FieldLwwMetadata> fieldMetadata) =>
      $model(vectorClock: vectorClock, nodeId: nodeId, fieldMetadata: fieldMetadata, $fromEntity);

  $model mergeModels($model local, $model remote) {
    $winnerDeclarations
    return $model(
      $mergedFields,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      fieldMetadata: <String, FieldLwwMetadata>{$mergedMetadata},
    );
  }
}

void register${type}SyncAdapter(SyncEngine engine) {
  engine.register<$type>(const $adapter());
}
$driftTable
''';
  }

  Future<void> _validateSchemaManifest(
      BuildStep step, String type, Set<String> currentFields) async {
    final manifestId = AssetId(step.inputId.package, schemaManifest);
    if (!await step.canRead(manifestId)) {
      if (bootstrapSchema) return;
      throw InvalidGenerationSourceError(
        'Drift generation for $type requires the checked-in schema manifest $schemaManifest. '
        'For a first build, set bootstrap_schema: true and run '
        '`dart run sync_engine_generator:bootstrap_schema $schemaManifest $type <comma-separated-fields>`, then commit it.',
      );
    }
    final decoded =
        jsonDecode(await step.readAsString(manifestId)) as Map<String, dynamic>;
    final previous =
        (decoded[type] as List<dynamic>? ?? const []).cast<String>().toSet();
    final removed = previous.difference(currentFields);
    if (removed.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Additive-only Drift migration rejected for $type: removed or renamed field(s) ${removed.join(', ')}.',
      );
    }
  }

  String _driftTable(String type) {
    final table = '${type}SyncTable';
    return '''
@DataClassName('${type}SyncRow')
class $table extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get vectorClock => text().named('vector_clock')();
  TextColumn get fieldMetadata => text().named('field_metadata')();
  TextColumn get nodeId => text().named('node_id')();
  IntColumn get deleted => integer().withDefault(const Constant(0))();
  IntColumn get lastModified => integer().named('last_modified').withDefault(const CustomExpression<int>("strftime('%s','now')"))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
''';
  }

  String _mergedField(FieldElement field) {
    final name = field.displayName;
    final strategy = _strategy(field);
    return switch (strategy) {
      ConflictType.growOnlyCounter => '$name: local.$name.merge(remote.$name)',
      ConflictType.growOnlySet =>
        '$name: GSet(local.$name).merge(GSet(remote.$name)).value',
      ConflictType.lastWriteWins =>
        '$name: ${name}Winner == local.fieldMetadata[\'$name\'] ? local.$name : remote.$name',
      ConflictType.custom =>
        throw StateError('custom merge fields are rejected during generation'),
    };
  }

  ConflictType _strategy(FieldElement field) {
    final annotation = _strategyChecker.firstAnnotationOf(field);
    if (annotation == null) return ConflictType.lastWriteWins;
    final value = ConstantReader(annotation).read('type').revive().accessor;
    return ConflictType.values.byName(value.split('.').last);
  }

  String _typeName(FieldElement field) => field.type.getDisplayString();

  String _jsonValue(FieldElement field) {
    final name = field.displayName;
    if (_typeName(field).startsWith('Set<')) return 'entity.$name.toList()';
    return 'entity.$name';
  }

  String _fromJson(FieldElement field) {
    final type = _typeName(field);
    final name = field.displayName;
    if (type.startsWith('Set<') && type.endsWith('>')) {
      final elementType = type.substring(4, type.length - 1);
      return '((json[\'$name\'] as List?) ?? const <dynamic>[]).cast<$elementType>().toSet()';
    }
    if (type == 'bool') return '(json[\'$name\'] as bool?) ?? false';
    if (type == 'int') return '(json[\'$name\'] as int?) ?? 0';
    if (type == 'double') return '(json[\'$name\'] as num?)?.toDouble() ?? 0.0';
    if (type == 'String') return '(json[\'$name\'] as String?) ?? \'\'';
    return 'json[\'$name\'] as $type';
  }

  String _snakeCase(String value) => value.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) =>
            '${match.start == 0 ? '' : '_'}${match.group(0)!.toLowerCase()}',
      );
}
