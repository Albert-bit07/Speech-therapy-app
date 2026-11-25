# Local reward and purchase persistence

Local balances, achievement history and purchased item IDs are saved together in
one versioned UserDefaults snapshot. Store entries use stable IDs; repeat purchases
are rejected without another charge. Achievement identity is its type, so restoring
history preserves identity and prevents threshold bonuses from repeating.

Legacy counters are imported on first load. Earlier versions never saved achievement
history and used random purchase IDs; those missing mappings cannot be reconstructed.
Existing legacy purchase strings are retained, but cannot identify the new catalog
entries. A corrupt snapshot is preserved and blocks replacement writes, with a
message on the dashboard. UserDefaults is local demo storage, not a cloud account or
a power-loss durability guarantee. Local win streaks are still distinct from the
backend's UTC-day practice streak; calendar-based local rewards need separate work.
