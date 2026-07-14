// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sync_engine/sync_engine.dart';

/// Emits model, adapter, serializer, and registry wiring for `@Syncable`.
class SyncableGenerator extends GeneratorForAnnotation<Syncable> {
  static final _idChecker = TypeChecker.fromRuntime(Id);
  static final _strategyChecker = TypeChecker.fromRuntime(ConflictStrategy);

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@Syncable can only annotate a class.',
          element: element);
    }
    final fields = element.fields.where((field) => !field.isStatic).toList();
    final idFields =
        fields.where((field) => _idChecker.hasAnnotationOf(field)).toList();
    if (idFields.length != 1) {
      throw InvalidGenerationSourceError(
        '@Syncable class ${element.name} must declare exactly one @Id() field; found ${idFields.length}.',
        element: element,
      );
    }
    final idField = idFields.single;
    if (_typeName(idField) != 'String') {
      throw InvalidGenerationSourceError(
        '@Id() field ${element.name}.${idField.name} must have type String.',
        element: idField,
      );
    }

    final type = element.name;
    final model = '${type}SyncModel';
    final adapter = '${type}SyncAdapter';
    final serializer = '${type}Serializer';
    final fieldDeclarations = fields
        .map((field) => '  final ${_typeName(field)} ${field.name};')
        .join('\n');
    final constructorParameters =
        fields.map((field) => 'required this.${field.name}').join(', ');
    final fromEntity =
        fields.map((field) => '${field.name}: entity.${field.name}').join(', ');
    final modelJson = fields
        .map((field) => "'${field.name}': ${_jsonValue(field)}")
        .join(', ');
    final fromJson =
        fields.map((field) => '${field.name}: ${_fromJson(field)}').join(', ');
    final mergedFields = fields.map(_mergedField).join(',\n      ');

    return '''
class $model {
  const $model({required this.vectorClock, required this.nodeId, $constructorParameters});

  final VectorClock vectorClock;
  final String nodeId;
$fieldDeclarations
}

class $serializer {
  const $serializer();

  Map<String, dynamic> toJson($type entity) => <String, dynamic>{${modelJson.isEmpty ? '' : '\n    $modelJson,\n  '}};

  $type fromJson(Map<String, dynamic> json) => $type($fromJson);
}

class $adapter implements SyncAdapter<$type> {
  const $adapter();

  @override
  String get entityType => '${_snakeCase(type)}';

  @override
  String idOf($type entity) => entity.${idField.name};

  $model toModel($type entity, VectorClock vectorClock, String nodeId) =>
      $model(vectorClock: vectorClock, nodeId: nodeId, $fromEntity);

  $model mergeModels($model local, $model remote) => $model(
      $mergedFields,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: local.nodeId.compareTo(remote.nodeId) < 0 ? remote.nodeId : local.nodeId,
    );
}

void register${type}SyncAdapter(SyncEngine engine) {
  engine.register<$type>(const $adapter());
}
''';
  }

  String _mergedField(FieldElement field) {
    final name = field.name;
    final strategy = _strategy(field);
    return switch (strategy) {
      ConflictType.growOnlyCounter => '$name: local.$name.merge(remote.$name)',
      ConflictType.growOnlySet =>
        '$name: GSet(local.$name).merge(GSet(remote.$name)).value',
      ConflictType.custom =>
        '$name: throw UnsupportedError(\'TODO: implement custom merge for $name\')',
      ConflictType.lastWriteWins =>
        '$name: LWWRegister(value: local.$name, timestamp: local.vectorClock, nodeId: local.nodeId).merge(LWWRegister(value: remote.$name, timestamp: remote.vectorClock, nodeId: remote.nodeId)).value',
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
    final name = field.name;
    if (_typeName(field).startsWith('Set<')) return 'entity.$name.toList()';
    return 'entity.$name';
  }

  String _fromJson(FieldElement field) {
    final type = _typeName(field);
    final name = field.name;
    if (type.startsWith('Set<') && type.endsWith('>')) {
      final elementType = type.substring(4, type.length - 1);
      return '(json[\'$name\'] as List).cast<$elementType>().toSet()';
    }
    return 'json[\'$name\'] as $type';
  }

  String _snakeCase(String value) => value.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) =>
            '${match.start == 0 ? '' : '_'}${match.group(0)!.toLowerCase()}',
      );
}
