# Patch 085D — Passive DB Alias Repair

Adds the passive database compatibility functions expected by the new passive tree system:

- `node_by_id()`
- `connected_ids()`
- `node_count()`

The patch keeps older `ClassAscendancySystem` calls compatible with the newer passive tree UI/system contract.
