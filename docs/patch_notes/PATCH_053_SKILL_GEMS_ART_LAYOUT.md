# Patch 053 — Skill Gems Art Layout Scene

This patch rebuilds the Skill Gems panel as a scene-authored, editable, art-backed UI.

It uses the cleaned Skill Gems UI sheets supplied by the user, installs the sliced assets under:

```text
res://assets/ui/skill_gems/patch053/
```

and replaces:

```text
res://scenes/ui/panels/SkillGemsPanel.tscn
res://scripts/ui/panels/SkillGemsPanel.gd
```

The scene is organized into practical editable groups:

```text
SkillGemsPanel
  BackdropLayer
  ArtRoot
  ContentRoot
    HeaderGroup
    BodyGroup
      ActiveColumn
        ActiveGemList
      DetailColumn
        FeaturedGemGroup
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

Move whole layout regions by selecting:

```text
ActiveColumn
DetailColumn
SupportColumn
SpiritSection
ChoiceSection
ActionSection
```

Move individual clickable controls inside:

```text
ActiveGemList
SupportGemList
SpiritGemList
SocketGroup
ChoiceButtonGrid
```

The script does not create the UI layout at runtime. It binds to scene-authored controls and updates text, state, socket icons, choices, and drag/drop behavior.

Test:

1. Press K to open Skill Gems.
2. Click active/support/spirit gems.
3. Right-click Uncut Skill Gem and choose a skill.
4. Right-click Uncut Spirit Gem and choose a spirit skill.
5. Right-click Uncut Support Gem, choose a target, then choose support effect.
6. Drag support gems onto active/spirit gems or sockets.
7. Check that sockets and detail panel update.
