import 'dart:async';

import 'interfaces.dart';
import 'operation.dart';

enum SyncFailureKind { rejected, deadLetter }

/// A permanent failure that applications can surface to their users.
class SyncFailure {
  const SyncFailure({
    required this.operation,
    required this.kind,
    required this.reason,
    required this.attempts,
  });

  final SyncOperation operation;
  final SyncFailureKind kind;
  final String reason;
  final int attempts;
}

/// In-memory outbox with configurable retry and dead-letter handling.
class SyncOutbox {
  SyncOutbox({
    this.baseBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(seconds: 60),
    this.maxAttempts = 8,
    Future<void> Function(Duration duration)? delay,
  })  : _delay = delay ?? Future<void>.delayed,
        assert(!baseBackoff.isNegative),
        assert(!maxBackoff.isNegative),
        assert(maxAttempts > 0);

  final Duration baseBackoff;
  final Duration maxBackoff;
  final int maxAttempts;
  final Future<void> Function(Duration duration) _delay;
  final List<SyncOperation> _pending = [];
  final List<SyncOperation> _deadLetters = [];
  final List<SyncFailure> _failures = [];
  final Map<SyncOperation, int> _attempts = {};
  final _pendingController = StreamController<SyncOperation>.broadcast();
  final _deadLetterController = StreamController<SyncOperation>.broadcast();
  final _errorController = StreamController<SyncFailure>.broadcast();

  Stream<SyncOperation> get pending => _pendingController.stream;
  Stream<SyncOperation> get deadLetter => _deadLetterController.stream;
  Stream<SyncFailure> get errors => _errorController.stream;
  List<SyncOperation> get pendingOperations => List.unmodifiable(_pending);
  List<SyncOperation> get deadLetters => List.unmodifiable(_deadLetters);
  List<SyncFailure> get failures => List.unmodifiable(_failures);

  void queue(SyncOperation operation) {
    _pending.add(operation);
    _pendingController.add(operation);
  }

  /// Flushes the current queue. Transient transport exceptions are retried with
  /// exponential backoff; permanent rejection is surfaced immediately.
  Future<void> flush(SyncTransport transport) async {
    while (_pending.isNotEmpty) {
      final operation = _pending.first;
      try {
        final result = await transport.push([operation]);
        final operationResult = result.results.isEmpty
            ? SyncOperationResult(
                operation: operation, disposition: SyncDisposition.accepted)
            : result.results.single;
        _pending.removeAt(0);
        _attempts.remove(operation);
        switch (operationResult.disposition) {
          case SyncDisposition.accepted:
            break;
          case SyncDisposition.conflict:
            final clock =
                operationResult.updatedVectorClock ?? operation.vectorClock;
            queue(operation.withVectorClock(clock));
            break;
          case SyncDisposition.rejected:
            _recordFailure(operation, SyncFailureKind.rejected,
                operationResult.reason ?? 'Server rejected operation', 1);
            break;
        }
      } catch (error) {
        final attempts = (_attempts[operation] ?? 0) + 1;
        _attempts[operation] = attempts;
        if (attempts >= maxAttempts) {
          _pending.removeAt(0);
          _attempts.remove(operation);
          _deadLetters.add(operation);
          _deadLetterController.add(operation);
          _recordFailure(operation, SyncFailureKind.deadLetter,
              error.toString(), attempts);
          continue;
        }
        final multiplier = 1 << (attempts - 1);
        final delay = baseBackoff * multiplier;
        await _delay(delay > maxBackoff ? maxBackoff : delay);
      }
    }
  }

  void _recordFailure(SyncOperation operation, SyncFailureKind kind,
      String reason, int attempts) {
    final failure = SyncFailure(
        operation: operation, kind: kind, reason: reason, attempts: attempts);
    _failures.add(failure);
    _errorController.add(failure);
  }

  Future<void> dispose() async {
    await _pendingController.close();
    await _deadLetterController.close();
    await _errorController.close();
  }
}
