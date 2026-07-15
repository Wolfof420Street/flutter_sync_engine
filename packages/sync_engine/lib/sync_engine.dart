/// Pure-Dart CRDT primitives and offline-first synchronization contracts.
///
/// Applications use [SyncEngine] with a [SyncStorage] and [SyncTransport]
/// supplied by their chosen persistence and backend adapters. Annotated domain
/// models receive generated [SyncAdapter] implementations from
/// `sync_engine_generator`.
///
/// This package does not provide networking, database storage, encryption, or
/// authentication. Those responsibilities belong to adapter packages.
library;

export 'src/annotations.dart';
export 'src/crdt/g_counter.dart';
export 'src/crdt/g_set.dart';
export 'src/crdt/lww_register.dart';
export 'src/sync/adapter.dart';
export 'src/sync/engine.dart';
export 'src/sync/interfaces.dart';
export 'src/sync/operation.dart';
export 'src/sync/outbox.dart';
export 'src/vector_clock.dart';
