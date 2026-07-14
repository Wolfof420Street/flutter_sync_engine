import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  InsertOperation operation([VectorClock? clock]) => InsertOperation(
        entityType: 'task',
        entityId: 'one',
        vectorClock: clock ?? VectorClock({'local': 1}),
        entity: const Task('one', 'title'),
      );

  test('queues and flushes accepted operations', () async {
    final outbox = SyncOutbox();
    final transport = FakeSyncTransport();
    outbox.queue(operation());

    await outbox.flush(transport);

    expect(transport.pushes, hasLength(1));
    expect(outbox.pendingOperations, isEmpty);
  });

  test('retries with exponential backoff then dead-letters', () async {
    final delays = <Duration>[];
    final outbox = SyncOutbox(
      baseBackoff: const Duration(seconds: 2),
      maxBackoff: const Duration(seconds: 3),
      maxAttempts: 3,
      delay: (duration) async => delays.add(duration),
    );
    final transport = FakeSyncTransport(responses: [
      Exception('offline'),
      Exception('offline'),
      Exception('offline')
    ]);
    final queued = operation();
    outbox.queue(queued);

    await outbox.flush(transport);

    expect(delays, [const Duration(seconds: 2), const Duration(seconds: 3)]);
    expect(outbox.deadLetters, [queued]);
    expect(outbox.failures.single.kind, SyncFailureKind.deadLetter);
    expect(outbox.failures.single.attempts, 3);
  });

  test('requeues a conflict with the server vector clock', () async {
    final original = operation();
    final updatedClock = VectorClock({'server': 4, 'local': 1});
    final transport = FakeSyncTransport(responses: [
      SyncResult(results: [
        SyncOperationResult(
            operation: original,
            disposition: SyncDisposition.conflict,
            updatedVectorClock: updatedClock),
      ]),
    ]);
    final outbox = SyncOutbox();
    outbox.queue(original);

    await outbox.flush(transport);

    expect(transport.pushes, hasLength(2));
    expect(transport.pushes.last.single.vectorClock, updatedClock);
    expect(outbox.pendingOperations, isEmpty);
  });
}
