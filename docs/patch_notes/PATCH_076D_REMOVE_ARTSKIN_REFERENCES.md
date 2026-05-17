# Patch 076D — Remove obsolete MapDeviceArtSkin references

The scene-authored map-device art pass removed `RVMapDeviceArtSkin`, but some panel scripts still referenced the old runtime helper from the temporary 076A bridge patch.

This patch removes those leftover calls from panel scripts and retires `scripts/visuals/MapDeviceArtSkin.gd` if present. Art placement remains scene-authored in `.tscn` files; scripts should only bind state, text, visibility, and dynamic textures.
