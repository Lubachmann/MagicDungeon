# Asset credits

## Current dungeon and UI

- **DungeonTileset II v1.7**, by 0x72 (Robert), CC0: https://0x72.itch.io/dungeontileset-ii
  - Active dungeon floor/wall tiles, characters, enemies, chests, banners and furnishings. Atlas regions extracted; tall sprites fitted into a 16×16 cell without changing aspect ratio.
- **DungeonUI**, by 0x72, CC0: https://0x72.itch.io/dungeonui
  - Original frame supplies the warm wood theme; a recolored muted-brass version supplies the default Gothic theme. Frames use nine-slice scaling with nearest-neighbor filtering.
- **Pixel Operator**, by Jayvee Enaguas (HarvettFox96), CC0: https://www.dafont.com/pixel-operator.font
  - Active regular text and bold headings, with antialiasing disabled. Font files and complete CC0 license included in assets/fonts/PixelOperator-LICENSE.txt.
- **Kyrise’s Free 16x16 RPG Icon Pack v1.3**, © 2018 Kyrise, CC BY 4.0: https://kyrise.itch.io/kyrises-free-16x16-rpg-icon-pack
  - License: https://creativecommons.org/licenses/by/4.0/
  - Some active elemental, timing, critical and other icons remain from this set. Original 16×16 PNGs copied/renamed; pixels unmodified. File mapping and author readme retained in assets/pixel_icons. Runtime uses nearest-neighbor scaling at integer multiples of 16 and preserves the painted colours. Rarity is shown as a small separate marker.
  - Heart and dagger icons come from 0x72 DungeonTileset II (CC0), extracted into transparent 16×16 cells.
- **Pixelify Sans**, by Stefie Justprince, OFL 1.1: https://github.com/google/fonts/tree/main/ofl/pixelifysans
  - Previous font retained as an unused reference with its OFL license.

The user-supplied Buff Icons.pixaki document was inspected only as a visual reference. Its sprites are not copied or redistributed.

## Creator-supplied icons

Selected original 16×16 PNGs supplied by the game creator are used for equipment, selected stats, the flask, iron, boots, map, book and treasure/relic icons. They were copied without editing to `assets/user_icons/`; `sources.json` records their source attachment names and runtime roles. Their use in this project is authorized by the creator's request; no third-party license is asserted. Other icons retain the credits below.

The following sections document retained original assets as well as active icons/audio. The old Tiny Dungeon scenery and Fantasy UI Borders are retained in the project but replaced by 0x72 art at runtime.


Dungeon and pixel UI art by Kenney (https://kenney.nl), licensed under Creative Commons Zero (CC0).

- Tiny Dungeon 1.0: https://kenney.nl/assets/tiny-dungeon
  - Download mirror: https://opengameart.org/content/tiny-dungeon
  - Original scenery pack, retained for reference; replaced at runtime by DungeonTileset II.
  - Selected individual tiles renamed for clarity; pixels unmodified.
- 1-Bit Pack 1.1: https://kenney.nl/assets/1-bit-pack
  - Download mirror: https://opengameart.org/content/1-bit-pack
  - Used for stat and equipment icons. Cropped from the monochrome transparent atlas; tinted at runtime.

Original licenses are preserved in each asset folder. No attribution is required by CC0; these credits are included to document provenance.

## Boots icon

Boots by Lorc, from https://game-icons.net/1x1/lorc/boots.html
Licensed under Creative Commons Attribution 3.0: https://creativecommons.org/licenses/by/3.0/
Author: https://lorcblog.blogspot.com/
Adaptation: reduced to a 16×16 monochrome pixel silhouette and tinted in game.
This credit must accompany redistributions of the Boots icon.

## Downloaded sound effects

Kenney RPG Audio and Interface Sounds, licensed CC0.

- https://kenney.nl/assets/rpg-audio
- https://kenney.nl/assets/interface-sounds
- Download mirrors: https://opengameart.org/node/21999 and https://opengameart.org/content/interface-sounds

Event → original file:

- `step_a.ogg` → RPG Audio / `footstep00.ogg`
- `step_b.ogg` → RPG Audio / `footstep01.ogg`
- `swing.ogg` → RPG Audio / `knifeSlice.ogg`
- `hurt.ogg` → RPG Audio / `chop.ogg`
- `block.ogg` → RPG Audio / `metalClick.ogg`
- `door.ogg` → RPG Audio / `doorOpen_1.ogg`
- `pickup.ogg` → RPG Audio / `handleCoins.ogg`
- `equip.ogg` → RPG Audio / `drawKnife1.ogg`
- `break.ogg` → RPG Audio / `metalPot1.ogg`
- `heal.ogg` → Interface Sounds / `glass_001.ogg`
- `blessing.ogg` → Interface Sounds / `confirmation_001.ogg`
- `relic.ogg` → Interface Sounds / `confirmation_002.ogg`
- `victory.ogg` → Interface Sounds / `confirmation_004.ogg`
- `death.ogg` → Interface Sounds / `close_004.ogg`
- `click.ogg` → Interface Sounds / `click_001.ogg`
- `error.ogg` → Interface Sounds / `error_001.ogg`

Audio files are unmodified; playback volume and pitch are adjusted at runtime. Original licenses are in assets/audio.

## Equipment-window icons

Icons by Lorc, available on https://game-icons.net, under CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/). Previous SVG equipment icons, retained as unused references; replaced at runtime by Kyrise pixel sprites.

- weapon: https://game-icons.net/1x1/lorc/broadsword.html
- shield: https://game-icons.net/1x1/lorc/checked-shield.html
- armor: https://game-icons.net/1x1/lorc/breastplate.html
- helmet: https://game-icons.net/1x1/lorc/crested-helmet.html
- amulet: https://game-icons.net/1x1/lorc/gem-necklace.html

Opened chest art is an additional unmodified tile from Kenney Tiny Dungeon (CC0).

## Fantasy UI Borders

Kenney Fantasy UI Borders 1.0, CC0.
Source: https://kenney.nl/assets/fantasy-ui-borders
Download mirror: https://opengameart.org/content/fantasy-ui-borders
Previous border sprites 000, 002, and 015 remain in the project for reference. Frames are tinted at runtime. Original license: assets/ui/LICENSE.txt.

## Release foundation animation and ambience

Four-frame player idle/run and enemy idle animations: DungeonTileset II v1.7 by 0x72 (Robert), CC0, https://0x72.itch.io/dungeontileset-ii. Frames fitted to transparent 16×16 cells with preserved aspect ratio and nearest-neighbor sampling. License recorded in assets/animations/LICENSE.txt.

The three 24-second ambient WAV loops are original procedural synthesis made for this project, with no sampled third-party recordings. The reproducible generator is tools/generate_ambience.py. They use sine harmonics and periodic bell envelopes. They are included as prototype ambience, not claimed as a commissioned soundtrack.

## 0.3 timing and exploration glyphs

The attack-speed icon is Kenney's original 16×16 hourglass from the CC0 1-Bit Pack (atlas cell 40,12): https://kenney.nl/assets/1-bit-pack. Boots continue to mean traversal. Copper key, candle/brazier, Sun/Moon gems and reliquary crystal are additional unmodified Kyrise 16×16 sprites under CC BY 4.0; see the source mapping in assets/pixel_icons/sources.json and the existing Kyrise attribution.

0.6 combat cues reuse the credited audio with pitch/gain variations; floor enemies reuse the credited sprites with runtime tint and icon composition. No additional external assets.

## 0.13 enemy roster

Eleven additional four-frame animation sets from 0x72 DungeonTileset II v1.7 (CC0): orc warrior, wogol, chort, masked orc, doc, big zombie, ogre, necromancer, big demon, angel and male knight. Official source: https://0x72.itch.io/dungeontileset-ii . Original frames are preserved; rendering fits them without stretching. Full mappings: assets/animations/enemy-sources.json.

## Dungeon and Hearth music

- “Whispers in the Fog” by Ruhinre, CC0 1.0: https://opengameart.org/content/whispers-in-the-fog
- “Dungeon Themes” (dungeon, dungeonfire, dungeonmystic) by FazeDevWater, CC0 1.0: https://opengameart.org/content/dungeon-themes

Original files, download names, hashes and CC0 license text are documented in `assets/music/README.md` and `assets/music/CC0-1.0.txt`. Used unmodified; volume and looping are controlled at playback.
