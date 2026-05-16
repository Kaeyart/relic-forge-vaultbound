# Patch 052 — Organized Scene-Authored Skill Gems Panel

This patch reorganizes the Skill Gems panel into a proper editable scene hierarchy.

It does not add new gameplay systems. It makes the scene practical to edit in Godot.

## Main changes

- Replaces `SkillGemsPanel.tscn` with an organized hierarchy.
- Replaces `SkillGemsPanel.gd` with a scene-binding script.
- Removes runtime-created layout roots.
- Keeps mouse click, right-click uncut gem choices, support target/effect choices, support socketing, spirit toggling, and basic support drag-to-target behavior.
- Keeps the sliced skill gem art assets under the existing `assets/ui/skill_gems/patch051/slices/` path.

## Editable groups

Open:

```text
res://scenes/ui/panels/SkillGemsPanel.tscn
```

The scene is organized as:

```text
SkillGemsPanel
  BackdropLayer
  ArtRoot
    BackgroundArt
    HeaderArt
    ColumnFrames
    BottomFrames
    Decor
  ContentRoot
    HeaderGroup
    BodyGroup
      ActiveColumn
        ActiveGemList
      DetailColumn
        FeaturedGemGroup
        DetailTextGroup
        SocketGroup
      SupportColumn
        SupportGemList
    BottomGroup
      SpiritSection
        SpiritGemList
      ChoiceSection
        ChoiceButtonGrid
      ActionSection
    DragLayer
```

Move whole columns by selecting:

```text
ActiveColumn
DetailColumn
SupportColumn
SpiritSection
ChoiceSection
ActionSection
```

Move individual buttons by selecting their button nodes under the relevant list.

## Important

This patch intentionally keeps scene-authored layout. Scripts update text, states, and actions only.
