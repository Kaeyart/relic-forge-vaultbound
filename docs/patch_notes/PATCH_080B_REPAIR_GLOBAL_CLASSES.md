# Patch 080B Repair — Itemization/crafting global class registration

Repairs missing global classes after the itemization/crafting patch train.

## Fixed
- Rewrites `RVItemizationSystem` with a parse-safe standalone implementation.
- Rewrites `RVCraftingCurrencySystem` with a parse-safe standalone implementation.
- Avoids dependency on `RVCraftingCurrencyDB` during parser registration.
- Keeps crafting verbs, forge potential costs, and item detail normalization functional.
