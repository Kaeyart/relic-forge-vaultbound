# Patch 051 — Scene-Authored Skill Gems Panel

This patch fixes the Skill Gems panel workflow problem.

Previous problem:
- The panel was being rebuilt by `SkillGemsPanel.gd` using runtime-created containers/buttons.
- That made it hard to edit the scene by hand, unlike the inventory scene.

This patch:
- Slices the 4 cleaned Skill Gems UI sheets into 71 PNG assets.
- Installs those assets under `assets/ui/skill_gems/patch051/`.
- Replaces `SkillGemsPanel.tscn` with an editable scene-authored layout.
- Replaces `SkillGemsPanel.gd` with a binding script that does not create UI layout nodes.
- Keeps mouse-first functionality: click, right-click uncut gems, drag support gems onto active/spirit gems, socket/unsocket, enable spirit, add sockets, close.

Editable scene nodes:
- `ActivePanel/ActiveGemButton0..7`
- `SupportPanel/SupportGemButton0..15`
- `SpiritPanel/SpiritGemButton0..5`
- `DetailPanel/SocketButton0..5`
- `ChoicePanel/ChoiceButton0..17`
- `Actions/EquipButton`
- `Actions/AddSkillSocketButton`
- `Actions/AddSpiritSocketButton`
- `Actions/EnableSpiritButton`
- `Actions/UnsocketButton`
- `Actions/CloseButton`

Open:

```text
res://scenes/ui/panels/SkillGemsPanel.tscn
```

Move the panels/buttons/art manually in the Godot editor. The script looks for named nodes and updates them, instead of constructing the layout in code.

Important:
- Do not rename the functional buttons unless you also update `SkillGemsPanel.gd`.
- You can move, resize, restyle, and reorder the nodes freely.
- You can swap texture art on `TextureRect` nodes without changing code.
