// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SyncEntityTableTable extends SyncEntityTable
    with TableInfo<$SyncEntityTableTable, SyncEntityTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncEntityTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vectorClockMeta =
      const VerificationMeta('vectorClock');
  @override
  late final GeneratedColumn<String> vectorClock = GeneratedColumn<String>(
      'vector_clock', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<int> deleted = GeneratedColumn<int>(
      'deleted', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<int> lastModified = GeneratedColumn<int>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression<int>("strftime('%s','now')"));
  @override
  List<GeneratedColumn> get $columns =>
      [entityType, id, payload, vectorClock, deleted, lastModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_entity_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<SyncEntityTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('vector_clock')) {
      context.handle(
          _vectorClockMeta,
          vectorClock.isAcceptableOrUnknown(
              data['vector_clock']!, _vectorClockMeta));
    } else if (isInserting) {
      context.missing(_vectorClockMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, id};
  @override
  SyncEntityTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncEntityTableData(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      vectorClock: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vector_clock'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted'])!,
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $SyncEntityTableTable createAlias(String alias) {
    return $SyncEntityTableTable(attachedDatabase, alias);
  }
}

class SyncEntityTableData extends DataClass
    implements Insertable<SyncEntityTableData> {
  final String entityType;
  final String id;
  final String payload;
  final String vectorClock;
  final int deleted;
  final int lastModified;
  const SyncEntityTableData(
      {required this.entityType,
      required this.id,
      required this.payload,
      required this.vectorClock,
      required this.deleted,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['vector_clock'] = Variable<String>(vectorClock);
    map['deleted'] = Variable<int>(deleted);
    map['last_modified'] = Variable<int>(lastModified);
    return map;
  }

  SyncEntityTableCompanion toCompanion(bool nullToAbsent) {
    return SyncEntityTableCompanion(
      entityType: Value(entityType),
      id: Value(id),
      payload: Value(payload),
      vectorClock: Value(vectorClock),
      deleted: Value(deleted),
      lastModified: Value(lastModified),
    );
  }

  factory SyncEntityTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncEntityTableData(
      entityType: serializer.fromJson<String>(json['entityType']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      vectorClock: serializer.fromJson<String>(json['vectorClock']),
      deleted: serializer.fromJson<int>(json['deleted']),
      lastModified: serializer.fromJson<int>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'vectorClock': serializer.toJson<String>(vectorClock),
      'deleted': serializer.toJson<int>(deleted),
      'lastModified': serializer.toJson<int>(lastModified),
    };
  }

  SyncEntityTableData copyWith(
          {String? entityType,
          String? id,
          String? payload,
          String? vectorClock,
          int? deleted,
          int? lastModified}) =>
      SyncEntityTableData(
        entityType: entityType ?? this.entityType,
        id: id ?? this.id,
        payload: payload ?? this.payload,
        vectorClock: vectorClock ?? this.vectorClock,
        deleted: deleted ?? this.deleted,
        lastModified: lastModified ?? this.lastModified,
      );
  SyncEntityTableData copyWithCompanion(SyncEntityTableCompanion data) {
    return SyncEntityTableData(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      vectorClock:
          data.vectorClock.present ? data.vectorClock.value : this.vectorClock,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncEntityTableData(')
          ..write('entityType: $entityType, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('deleted: $deleted, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entityType, id, payload, vectorClock, deleted, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncEntityTableData &&
          other.entityType == this.entityType &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.vectorClock == this.vectorClock &&
          other.deleted == this.deleted &&
          other.lastModified == this.lastModified);
}

class SyncEntityTableCompanion extends UpdateCompanion<SyncEntityTableData> {
  final Value<String> entityType;
  final Value<String> id;
  final Value<String> payload;
  final Value<String> vectorClock;
  final Value<int> deleted;
  final Value<int> lastModified;
  final Value<int> rowid;
  const SyncEntityTableCompanion({
    this.entityType = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.vectorClock = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncEntityTableCompanion.insert({
    required String entityType,
    required String id,
    required String payload,
    required String vectorClock,
    this.deleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        id = Value(id),
        payload = Value(payload),
        vectorClock = Value(vectorClock);
  static Insertable<SyncEntityTableData> custom({
    Expression<String>? entityType,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<String>? vectorClock,
    Expression<int>? deleted,
    Expression<int>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (deleted != null) 'deleted': deleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncEntityTableCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? id,
      Value<String>? payload,
      Value<String>? vectorClock,
      Value<int>? deleted,
      Value<int>? lastModified,
      Value<int>? rowid}) {
    return SyncEntityTableCompanion(
      entityType: entityType ?? this.entityType,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      vectorClock: vectorClock ?? this.vectorClock,
      deleted: deleted ?? this.deleted,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(vectorClock.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<int>(deleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<int>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncEntityTableCompanion(')
          ..write('entityType: $entityType, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('deleted: $deleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReplicaAcknowledgementsTable extends ReplicaAcknowledgements
    with TableInfo<$ReplicaAcknowledgementsTable, ReplicaAcknowledgementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReplicaAcknowledgementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
      'node_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _acknowledgedClockMeta =
      const VerificationMeta('acknowledgedClock');
  @override
  late final GeneratedColumn<String> acknowledgedClock =
      GeneratedColumn<String>('acknowledged_clock', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [entityType, entityId, nodeId, acknowledgedClock];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'replica_acknowledgements';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReplicaAcknowledgementRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(_nodeIdMeta,
          nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta));
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('acknowledged_clock')) {
      context.handle(
          _acknowledgedClockMeta,
          acknowledgedClock.isAcceptableOrUnknown(
              data['acknowledged_clock']!, _acknowledgedClockMeta));
    } else if (isInserting) {
      context.missing(_acknowledgedClockMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId, nodeId};
  @override
  ReplicaAcknowledgementRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaAcknowledgementRow(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id'])!,
      acknowledgedClock: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}acknowledged_clock'])!,
    );
  }

  @override
  $ReplicaAcknowledgementsTable createAlias(String alias) {
    return $ReplicaAcknowledgementsTable(attachedDatabase, alias);
  }
}

class ReplicaAcknowledgementRow extends DataClass
    implements Insertable<ReplicaAcknowledgementRow> {
  final String entityType;
  final String entityId;
  final String nodeId;
  final String acknowledgedClock;
  const ReplicaAcknowledgementRow(
      {required this.entityType,
      required this.entityId,
      required this.nodeId,
      required this.acknowledgedClock});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['node_id'] = Variable<String>(nodeId);
    map['acknowledged_clock'] = Variable<String>(acknowledgedClock);
    return map;
  }

  ReplicaAcknowledgementsCompanion toCompanion(bool nullToAbsent) {
    return ReplicaAcknowledgementsCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      nodeId: Value(nodeId),
      acknowledgedClock: Value(acknowledgedClock),
    );
  }

  factory ReplicaAcknowledgementRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaAcknowledgementRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      acknowledgedClock: serializer.fromJson<String>(json['acknowledgedClock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'nodeId': serializer.toJson<String>(nodeId),
      'acknowledgedClock': serializer.toJson<String>(acknowledgedClock),
    };
  }

  ReplicaAcknowledgementRow copyWith(
          {String? entityType,
          String? entityId,
          String? nodeId,
          String? acknowledgedClock}) =>
      ReplicaAcknowledgementRow(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        nodeId: nodeId ?? this.nodeId,
        acknowledgedClock: acknowledgedClock ?? this.acknowledgedClock,
      );
  ReplicaAcknowledgementRow copyWithCompanion(
      ReplicaAcknowledgementsCompanion data) {
    return ReplicaAcknowledgementRow(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      acknowledgedClock: data.acknowledgedClock.present
          ? data.acknowledgedClock.value
          : this.acknowledgedClock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaAcknowledgementRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('nodeId: $nodeId, ')
          ..write('acknowledgedClock: $acknowledgedClock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entityType, entityId, nodeId, acknowledgedClock);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaAcknowledgementRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.nodeId == this.nodeId &&
          other.acknowledgedClock == this.acknowledgedClock);
}

class ReplicaAcknowledgementsCompanion
    extends UpdateCompanion<ReplicaAcknowledgementRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> nodeId;
  final Value<String> acknowledgedClock;
  final Value<int> rowid;
  const ReplicaAcknowledgementsCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.acknowledgedClock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReplicaAcknowledgementsCompanion.insert({
    required String entityType,
    required String entityId,
    required String nodeId,
    required String acknowledgedClock,
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        nodeId = Value(nodeId),
        acknowledgedClock = Value(acknowledgedClock);
  static Insertable<ReplicaAcknowledgementRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? nodeId,
    Expression<String>? acknowledgedClock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (nodeId != null) 'node_id': nodeId,
      if (acknowledgedClock != null) 'acknowledged_clock': acknowledgedClock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReplicaAcknowledgementsCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? nodeId,
      Value<String>? acknowledgedClock,
      Value<int>? rowid}) {
    return ReplicaAcknowledgementsCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      nodeId: nodeId ?? this.nodeId,
      acknowledgedClock: acknowledgedClock ?? this.acknowledgedClock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (acknowledgedClock.present) {
      map['acknowledged_clock'] = Variable<String>(acknowledgedClock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaAcknowledgementsCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('nodeId: $nodeId, ')
          ..write('acknowledgedClock: $acknowledgedClock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LwwFrontierEntriesTable extends LwwFrontierEntries
    with TableInfo<$LwwFrontierEntriesTable, LwwFrontierEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LwwFrontierEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
      'node_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [entityType, entityId, nodeId, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lww_frontier_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LwwFrontierEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(_nodeIdMeta,
          nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta));
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId, nodeId};
  @override
  LwwFrontierEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LwwFrontierEntry(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $LwwFrontierEntriesTable createAlias(String alias) {
    return $LwwFrontierEntriesTable(attachedDatabase, alias);
  }
}

class LwwFrontierEntry extends DataClass
    implements Insertable<LwwFrontierEntry> {
  final String entityType;
  final String entityId;
  final String nodeId;
  final String timestamp;
  const LwwFrontierEntry(
      {required this.entityType,
      required this.entityId,
      required this.nodeId,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['node_id'] = Variable<String>(nodeId);
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  LwwFrontierEntriesCompanion toCompanion(bool nullToAbsent) {
    return LwwFrontierEntriesCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      nodeId: Value(nodeId),
      timestamp: Value(timestamp),
    );
  }

  factory LwwFrontierEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LwwFrontierEntry(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'nodeId': serializer.toJson<String>(nodeId),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  LwwFrontierEntry copyWith(
          {String? entityType,
          String? entityId,
          String? nodeId,
          String? timestamp}) =>
      LwwFrontierEntry(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        nodeId: nodeId ?? this.nodeId,
        timestamp: timestamp ?? this.timestamp,
      );
  LwwFrontierEntry copyWithCompanion(LwwFrontierEntriesCompanion data) {
    return LwwFrontierEntry(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LwwFrontierEntry(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('nodeId: $nodeId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, nodeId, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LwwFrontierEntry &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.nodeId == this.nodeId &&
          other.timestamp == this.timestamp);
}

class LwwFrontierEntriesCompanion extends UpdateCompanion<LwwFrontierEntry> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> nodeId;
  final Value<String> timestamp;
  final Value<int> rowid;
  const LwwFrontierEntriesCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LwwFrontierEntriesCompanion.insert({
    required String entityType,
    required String entityId,
    required String nodeId,
    required String timestamp,
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        nodeId = Value(nodeId),
        timestamp = Value(timestamp);
  static Insertable<LwwFrontierEntry> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? nodeId,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (nodeId != null) 'node_id': nodeId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LwwFrontierEntriesCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? nodeId,
      Value<String>? timestamp,
      Value<int>? rowid}) {
    return LwwFrontierEntriesCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      nodeId: nodeId ?? this.nodeId,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LwwFrontierEntriesCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('nodeId: $nodeId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncDriftDatabase extends GeneratedDatabase {
  _$SyncDriftDatabase(QueryExecutor e) : super(e);
  $SyncDriftDatabaseManager get managers => $SyncDriftDatabaseManager(this);
  late final $SyncEntityTableTable syncEntityTable =
      $SyncEntityTableTable(this);
  late final $ReplicaAcknowledgementsTable replicaAcknowledgements =
      $ReplicaAcknowledgementsTable(this);
  late final $LwwFrontierEntriesTable lwwFrontierEntries =
      $LwwFrontierEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [syncEntityTable, replicaAcknowledgements, lwwFrontierEntries];
}

typedef $$SyncEntityTableTableCreateCompanionBuilder = SyncEntityTableCompanion
    Function({
  required String entityType,
  required String id,
  required String payload,
  required String vectorClock,
  Value<int> deleted,
  Value<int> lastModified,
  Value<int> rowid,
});
typedef $$SyncEntityTableTableUpdateCompanionBuilder = SyncEntityTableCompanion
    Function({
  Value<String> entityType,
  Value<String> id,
  Value<String> payload,
  Value<String> vectorClock,
  Value<int> deleted,
  Value<int> lastModified,
  Value<int> rowid,
});

class $$SyncEntityTableTableFilterComposer
    extends Composer<_$SyncDriftDatabase, $SyncEntityTableTable> {
  $$SyncEntityTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vectorClock => $composableBuilder(
      column: $table.vectorClock, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));
}

class $$SyncEntityTableTableOrderingComposer
    extends Composer<_$SyncDriftDatabase, $SyncEntityTableTable> {
  $$SyncEntityTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vectorClock => $composableBuilder(
      column: $table.vectorClock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncEntityTableTableAnnotationComposer
    extends Composer<_$SyncDriftDatabase, $SyncEntityTableTable> {
  $$SyncEntityTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get vectorClock => $composableBuilder(
      column: $table.vectorClock, builder: (column) => column);

  GeneratedColumn<int> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$SyncEntityTableTableTableManager extends RootTableManager<
    _$SyncDriftDatabase,
    $SyncEntityTableTable,
    SyncEntityTableData,
    $$SyncEntityTableTableFilterComposer,
    $$SyncEntityTableTableOrderingComposer,
    $$SyncEntityTableTableAnnotationComposer,
    $$SyncEntityTableTableCreateCompanionBuilder,
    $$SyncEntityTableTableUpdateCompanionBuilder,
    (
      SyncEntityTableData,
      BaseReferences<_$SyncDriftDatabase, $SyncEntityTableTable,
          SyncEntityTableData>
    ),
    SyncEntityTableData,
    PrefetchHooks Function()> {
  $$SyncEntityTableTableTableManager(
      _$SyncDriftDatabase db, $SyncEntityTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncEntityTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncEntityTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncEntityTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> vectorClock = const Value.absent(),
            Value<int> deleted = const Value.absent(),
            Value<int> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncEntityTableCompanion(
            entityType: entityType,
            id: id,
            payload: payload,
            vectorClock: vectorClock,
            deleted: deleted,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String id,
            required String payload,
            required String vectorClock,
            Value<int> deleted = const Value.absent(),
            Value<int> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncEntityTableCompanion.insert(
            entityType: entityType,
            id: id,
            payload: payload,
            vectorClock: vectorClock,
            deleted: deleted,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncEntityTableTableProcessedTableManager = ProcessedTableManager<
    _$SyncDriftDatabase,
    $SyncEntityTableTable,
    SyncEntityTableData,
    $$SyncEntityTableTableFilterComposer,
    $$SyncEntityTableTableOrderingComposer,
    $$SyncEntityTableTableAnnotationComposer,
    $$SyncEntityTableTableCreateCompanionBuilder,
    $$SyncEntityTableTableUpdateCompanionBuilder,
    (
      SyncEntityTableData,
      BaseReferences<_$SyncDriftDatabase, $SyncEntityTableTable,
          SyncEntityTableData>
    ),
    SyncEntityTableData,
    PrefetchHooks Function()>;
typedef $$ReplicaAcknowledgementsTableCreateCompanionBuilder
    = ReplicaAcknowledgementsCompanion Function({
  required String entityType,
  required String entityId,
  required String nodeId,
  required String acknowledgedClock,
  Value<int> rowid,
});
typedef $$ReplicaAcknowledgementsTableUpdateCompanionBuilder
    = ReplicaAcknowledgementsCompanion Function({
  Value<String> entityType,
  Value<String> entityId,
  Value<String> nodeId,
  Value<String> acknowledgedClock,
  Value<int> rowid,
});

class $$ReplicaAcknowledgementsTableFilterComposer
    extends Composer<_$SyncDriftDatabase, $ReplicaAcknowledgementsTable> {
  $$ReplicaAcknowledgementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acknowledgedClock => $composableBuilder(
      column: $table.acknowledgedClock,
      builder: (column) => ColumnFilters(column));
}

class $$ReplicaAcknowledgementsTableOrderingComposer
    extends Composer<_$SyncDriftDatabase, $ReplicaAcknowledgementsTable> {
  $$ReplicaAcknowledgementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acknowledgedClock => $composableBuilder(
      column: $table.acknowledgedClock,
      builder: (column) => ColumnOrderings(column));
}

class $$ReplicaAcknowledgementsTableAnnotationComposer
    extends Composer<_$SyncDriftDatabase, $ReplicaAcknowledgementsTable> {
  $$ReplicaAcknowledgementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get acknowledgedClock => $composableBuilder(
      column: $table.acknowledgedClock, builder: (column) => column);
}

class $$ReplicaAcknowledgementsTableTableManager extends RootTableManager<
    _$SyncDriftDatabase,
    $ReplicaAcknowledgementsTable,
    ReplicaAcknowledgementRow,
    $$ReplicaAcknowledgementsTableFilterComposer,
    $$ReplicaAcknowledgementsTableOrderingComposer,
    $$ReplicaAcknowledgementsTableAnnotationComposer,
    $$ReplicaAcknowledgementsTableCreateCompanionBuilder,
    $$ReplicaAcknowledgementsTableUpdateCompanionBuilder,
    (
      ReplicaAcknowledgementRow,
      BaseReferences<_$SyncDriftDatabase, $ReplicaAcknowledgementsTable,
          ReplicaAcknowledgementRow>
    ),
    ReplicaAcknowledgementRow,
    PrefetchHooks Function()> {
  $$ReplicaAcknowledgementsTableTableManager(
      _$SyncDriftDatabase db, $ReplicaAcknowledgementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReplicaAcknowledgementsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ReplicaAcknowledgementsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReplicaAcknowledgementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> nodeId = const Value.absent(),
            Value<String> acknowledgedClock = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReplicaAcknowledgementsCompanion(
            entityType: entityType,
            entityId: entityId,
            nodeId: nodeId,
            acknowledgedClock: acknowledgedClock,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String entityId,
            required String nodeId,
            required String acknowledgedClock,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReplicaAcknowledgementsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            nodeId: nodeId,
            acknowledgedClock: acknowledgedClock,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReplicaAcknowledgementsTableProcessedTableManager
    = ProcessedTableManager<
        _$SyncDriftDatabase,
        $ReplicaAcknowledgementsTable,
        ReplicaAcknowledgementRow,
        $$ReplicaAcknowledgementsTableFilterComposer,
        $$ReplicaAcknowledgementsTableOrderingComposer,
        $$ReplicaAcknowledgementsTableAnnotationComposer,
        $$ReplicaAcknowledgementsTableCreateCompanionBuilder,
        $$ReplicaAcknowledgementsTableUpdateCompanionBuilder,
        (
          ReplicaAcknowledgementRow,
          BaseReferences<_$SyncDriftDatabase, $ReplicaAcknowledgementsTable,
              ReplicaAcknowledgementRow>
        ),
        ReplicaAcknowledgementRow,
        PrefetchHooks Function()>;
typedef $$LwwFrontierEntriesTableCreateCompanionBuilder
    = LwwFrontierEntriesCompanion Function({
  required String entityType,
  required String entityId,
  required String nodeId,
  required String timestamp,
  Value<int> rowid,
});
typedef $$LwwFrontierEntriesTableUpdateCompanionBuilder
    = LwwFrontierEntriesCompanion Function({
  Value<String> entityType,
  Value<String> entityId,
  Value<String> nodeId,
  Value<String> timestamp,
  Value<int> rowid,
});

class $$LwwFrontierEntriesTableFilterComposer
    extends Composer<_$SyncDriftDatabase, $LwwFrontierEntriesTable> {
  $$LwwFrontierEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$LwwFrontierEntriesTableOrderingComposer
    extends Composer<_$SyncDriftDatabase, $LwwFrontierEntriesTable> {
  $$LwwFrontierEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$LwwFrontierEntriesTableAnnotationComposer
    extends Composer<_$SyncDriftDatabase, $LwwFrontierEntriesTable> {
  $$LwwFrontierEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$LwwFrontierEntriesTableTableManager extends RootTableManager<
    _$SyncDriftDatabase,
    $LwwFrontierEntriesTable,
    LwwFrontierEntry,
    $$LwwFrontierEntriesTableFilterComposer,
    $$LwwFrontierEntriesTableOrderingComposer,
    $$LwwFrontierEntriesTableAnnotationComposer,
    $$LwwFrontierEntriesTableCreateCompanionBuilder,
    $$LwwFrontierEntriesTableUpdateCompanionBuilder,
    (
      LwwFrontierEntry,
      BaseReferences<_$SyncDriftDatabase, $LwwFrontierEntriesTable,
          LwwFrontierEntry>
    ),
    LwwFrontierEntry,
    PrefetchHooks Function()> {
  $$LwwFrontierEntriesTableTableManager(
      _$SyncDriftDatabase db, $LwwFrontierEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LwwFrontierEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LwwFrontierEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LwwFrontierEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> nodeId = const Value.absent(),
            Value<String> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LwwFrontierEntriesCompanion(
            entityType: entityType,
            entityId: entityId,
            nodeId: nodeId,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String entityId,
            required String nodeId,
            required String timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              LwwFrontierEntriesCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            nodeId: nodeId,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LwwFrontierEntriesTableProcessedTableManager = ProcessedTableManager<
    _$SyncDriftDatabase,
    $LwwFrontierEntriesTable,
    LwwFrontierEntry,
    $$LwwFrontierEntriesTableFilterComposer,
    $$LwwFrontierEntriesTableOrderingComposer,
    $$LwwFrontierEntriesTableAnnotationComposer,
    $$LwwFrontierEntriesTableCreateCompanionBuilder,
    $$LwwFrontierEntriesTableUpdateCompanionBuilder,
    (
      LwwFrontierEntry,
      BaseReferences<_$SyncDriftDatabase, $LwwFrontierEntriesTable,
          LwwFrontierEntry>
    ),
    LwwFrontierEntry,
    PrefetchHooks Function()>;

class $SyncDriftDatabaseManager {
  final _$SyncDriftDatabase _db;
  $SyncDriftDatabaseManager(this._db);
  $$SyncEntityTableTableTableManager get syncEntityTable =>
      $$SyncEntityTableTableTableManager(_db, _db.syncEntityTable);
  $$ReplicaAcknowledgementsTableTableManager get replicaAcknowledgements =>
      $$ReplicaAcknowledgementsTableTableManager(
          _db, _db.replicaAcknowledgements);
  $$LwwFrontierEntriesTableTableManager get lwwFrontierEntries =>
      $$LwwFrontierEntriesTableTableManager(_db, _db.lwwFrontierEntries);
}
