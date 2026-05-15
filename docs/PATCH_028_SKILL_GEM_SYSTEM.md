# Patch 028 — Skill Gem System Rework

Adds a first real skill gem system:

- Active Skill Gems grant active skills.
- Support Gems socket into active gems and modify damage, cost, cooldown, radius, or behavior flags.
- Spirit Gems reserve spirit for passive effects.
- Supports can also socket into Spirit Gems, increasing reservation through their `spirit_more` modifier.
- Active and Spirit gems start with 2 support sockets and can scale up to 6 with Socket Prisms.
- Gems can drop as room rewards.
- Skill Gems panel is now clickable and scene-authored.

## Current Controls

In the Skill Gems panel:

- Click active/support/spirit gems to select.
- Equip / Unequip Active toggles an active gem on the skill bar.
- Socket Support sockets the selected support into the selected active gem.
- Support Spirit sockets the selected support into the selected spirit gem.
- Remove Support removes the last support from the selected active gem.
- Add Socket consumes one Socket Prism and adds one active gem support socket.
- Toggle Spirit enables/disables the selected spirit gem.

Keyboard fallback:

- W/S selects active gem.
- A/D selects support gem.
- Enter/E sockets selected support into selected active gem.
- X/Backspace removes last active support.
- R toggles selected spirit gem.
- F adds socket to selected active gem.
