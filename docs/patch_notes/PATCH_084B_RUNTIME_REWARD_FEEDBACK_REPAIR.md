# Patch 084B — Runtime Reward / Feedback Repair

Fixes two runtime regressions from the 084A tuning pass:

- `RVProgressionRewardSystem` no longer uses fragile `int(value)` conversions on arbitrary patch-era Variant values.
- `CombatFeedbackSystem` guards dynamic `set_script(load(...))` calls so a missing/invalid helper script does not spam runtime errors during hit/death feedback.

No gameplay balance changes.
