# Patch 054 — Skill Gems Clean Layout Scene

This patch rebuilds `SkillGemsPanel.tscn` into a clean, editable, scene-authored hierarchy.

It uses the sliced Skill Gems UI art under `assets/ui/skill_gems/patch054/` and keeps the existing click/right-click/drag behavior through `SkillGemsPanel.gd`.

Main editing groups:

- `PanelRoot`
  - `FrameArt`
  - `ContentRoot`
    - `HeaderGroup`
    - `BodyGroup`
      - `ActiveColumn`
      - `DetailColumn`
      - `SupportColumn`
    - `BottomGroup`
      - `SpiritSection`
      - `ChoiceSection`
    - `ActionSection`
    - `DragLayer`

Move whole areas by selecting the group nodes above. Individual repeated slots live inside:

- `ActiveColumn/ActiveGemList/ActiveGemRow0..7`
- `DetailColumn/SocketGroup`
- `SupportColumn/SupportGemList/SupportGemCard0..15`
- `BottomGroup/SpiritSection/SpiritGemList/SpiritGemCard0..5`
- `BottomGroup/ChoiceSection/ChoiceButtonGrid/ChoiceButton0..17`

The scene deliberately avoids dumping all controls under one flat node.
