# Sync merge decisions

## Concurrent update versus tombstone

For the MVP, a tombstone wins when a delete and an update are causally
concurrent. The entity remains deleted and the clocks are merged so later
operations retain both causal histories.

A causally later update may resurrect a tombstone, and a causally later delete
removes an update. An alternative policy is concurrent-update resurrection,
but delete-wins avoids surprising restoration of data a user explicitly
deleted and gives the MVP a simpler mental model.
