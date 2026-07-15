import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_engine/sync_engine.dart';

import 'note.dart';

/// Consumer-owned durable storage. It demonstrates that no internal package
/// imports are necessary to implement [SyncStorage].
class NoteStorage implements SyncStorage {
  NoteStorage(this._preferences);

  static const _key = 'notes.sync.storage.v1';
  final SharedPreferences _preferences;
  final _changes = StreamController<List<Note>>.broadcast();
  final Map<String, _StoredNote> _notes = {};

  @override
  Future<void> initialize() async {
    final encoded = _preferences.getString(_key);
    if (encoded != null) {
      final values = jsonDecode(encoded) as Map<String, dynamic>;
      _notes
        ..clear()
        ..addEntries(
          values.entries.map(
            (entry) => MapEntry(
              entry.key,
              _StoredNote.fromJson(entry.value as Map<String, dynamic>),
            ),
          ),
        );
    }
  }

  @override
  Future<void> save<T>(String id, T entity, VectorClock clock, String nodeId) =>
      saveStored(Note, id, entity as Note, clock, nodeId, const {});

  @override
  Future<T?> load<T>(String id) async {
    final state = _notes[id];
    return state == null || state.deleted ? null : state.note as T;
  }

  @override
  Future<List<T>> loadAll<T>() async => _notes.values
      .where((value) => !value.deleted)
      .map((value) => value.note as T)
      .toList();

  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) =>
      deleteStored(Note, id, clock, nodeId);

  @override
  Stream<List<T>> watch<T>() async* {
    yield await loadAll<T>();
    yield* _changes.stream.map((notes) => notes.cast<T>());
  }

  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async {
    final state = _notes[id];
    if (type != Note || state == null) return null;
    return SyncStoredEntity(
      value: state.deleted ? null : state.note,
      clock: state.clock,
      nodeId: state.nodeId,
      deleted: state.deleted,
      fieldMetadata: state.metadata,
    );
  }

  @override
  Future<void> saveStored(
    Type type,
    String id,
    Object entity,
    VectorClock clock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) async {
    _notes[id] = _StoredNote(
      entity as Note,
      clock,
      nodeId,
      fieldMetadata,
      false,
    );
    await _persist();
  }

  @override
  Future<void> deleteStored(
    Type type,
    String id,
    VectorClock clock,
    String nodeId, [
    Map<String, FieldLwwMetadata> fieldMetadata = const {},
  ]) async {
    final prior = _notes[id];
    _notes[id] = _StoredNote(
      prior?.note ?? Note(id: id, title: ''),
      clock,
      nodeId,
      fieldMetadata,
      true,
    );
    await _persist();
  }

  Future<void> _persist() async {
    await _preferences.setString(
      _key,
      jsonEncode(_notes.map((key, value) => MapEntry(key, value.toJson()))),
    );
    _changes.add(
      _notes.values
          .where((value) => !value.deleted)
          .map((value) => value.note)
          .toList(),
    );
  }

  Future<void> dispose() => _changes.close();
}

class _StoredNote {
  const _StoredNote(
    this.note,
    this.clock,
    this.nodeId,
    this.metadata,
    this.deleted,
  );
  final Note note;
  final VectorClock clock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> metadata;
  final bool deleted;

  factory _StoredNote.fromJson(Map<String, dynamic> json) => _StoredNote(
    const NoteSerializer().fromJson(json['note'] as Map<String, dynamic>),
    VectorClock.fromJson(json['clock'] as Map<String, dynamic>),
    json['nodeId'] as String,
    ((json['metadata'] as Map<String, dynamic>?) ?? const {}).map(
      (key, value) => MapEntry(
        key,
        FieldLwwMetadata.fromJson(value as Map<String, dynamic>),
      ),
    ),
    json['deleted'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'note': const NoteSerializer().toJson(note),
    'clock': clock.toJson(),
    'nodeId': nodeId,
    'metadata': metadata.map((key, value) => MapEntry(key, value.toJson())),
    'deleted': deleted,
  };
}
