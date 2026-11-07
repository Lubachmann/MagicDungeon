# MagicDungeon icon checklist

This is a production art checklist for the current game, not a claim that each item is missing. The prototype already has many of these icons; replace them when you want a consistent original set. Start with gameplay-critical icons, then equipment and skills. One clear base icon with a color or border variation is usually better than drawing a separate icon for every number or rarity.

## Suggested visual specifications

- Dark fantasy pixel art, top-down or lightly angled view, thick readable silhouette, limited muted palette and selective bright accents.
- Individual transparent PNGs. Use a common native canvas such as 32×32 pixels for UI icons, with a consistent 1–2 pixel margin. The current project contains many 16×16 pixel sprites; match their pixel scale or replace them as a consistent set.
- No letters or numbers baked into the icons. UI text supplies names and values. Use nearest-neighbor scaling.
- Use different shapes as well as colors: Fire, Frost, Acid and Poison must remain distinguishable in grayscale. Draw several sizes only if the smallest HUD version loses readability.
- Keep each source file, license or tool terms, creation date and any artist attribution. Do not reuse someone else's copyrighted character or copy a recognizable game's icons.

## 1. Core HUD and combat — highest priority

| Icon | Suggested silhouette / use |
|---|---|
| Attack / physical damage | Sword strike or weapon impact; distinct from the sword item icon |
| Attack interval | Hourglass, clock or weapon with motion marks; avoid a shoe |
| Armor / physical defense | Shield or breastplate with a distinct outline |
| Health / healing | Heart; HP itself can also be text and a bar |
| XP / level | Text and progress bar are sufficient; optional upward spark for level-up |
| Critical chance | Target or crosshair with a star |
| Critical damage | Cracked target or starburst; different from chance |
| Critical chance limit | Crosshair with a small raised ceiling marker |
| Evade | Ghostly silhouette or curved dodge arrow |
| Vampirism | Fang with a red droplet |
| Fire | Flame, warm orange |
| Frost | Snowflake, pale blue |
| Acid | Corroded droplet, yellow-green |
| Poison | Skull droplet, purple-green |
| Shield / barrier | Glowing shield, distinguish from armor |
| Damage per second | Blade and clock, or an existing attack icon with text |
| Attack timing indicator | UI-drawn circular bar; separate sprite optional |
| Flask | Bottle with red liquid |
| Bomb | Round bomb with fuse |
| Ember | Glowing coal, not a gold coin |
| Iron / upgrade material | Iron ingot or metal fragments |

## 2. Equipment and items

| Icon | Use |
|---|---|
| Sword | One-handed balanced weapon |
| Dagger | Fast weapon |
| Axe | Slow heavy weapon |
| Greatblade | Heavy two-handed sword |
| Ember blade | Fire-themed weapon, distinct from the Fire stat icon |
| Shield | Equipped shield slot |
| Light armor | Light cuirass or leather vest |
| Heavy armor | Heavy plate cuirass |
| Helmet | Head slot |
| Amulet | Necklace / charm slot |
| Iron fragments | Optional separate fragment icon; can reuse iron ingot |
| Key | Copper dungeon key |
| Stonebreaker | Hammer or pick for cracked walls |
| Tidewalk Boots | Traversal boots for water |
| Common / Rare / Very rare | Prefer one frame or border with neutral / blue / purple colors; do not rely on color alone |
| Equipped / protected | Small check mark and lock badges for inventory items |

## 3. Dungeon, map and routes

- Closed chest, open chest, and guardian-sealed chest; rarity can use the shared border or chest markers.
- Room door, floor stairs, locked door, cracked wall and water crossing.
- Enemy / guardian marker and boss marker.
- Forge, rest-site campfire, fountain, urn, healing flask and iron pickup.
- Cinder shrine / health-for-power bargain; separate from the ordinary rest site.
- Side-passage marker, weapon armory, defensive armory, elemental chamber, dangerous vault and restful passage.
- Sun candle, Moon candle, reliquary / rune puzzle, Copper key and supply stash.
- Hearth discovery, rescued person, elemental manuscript and Warden flame fragment. Manuscripts can share one page shape with element badges.
- Map, current location, visited / unexplored room and flooded connection. These can be simple UI glyphs, not detailed inventory-style illustrations.

## 4. Level-up skills

Distinct icons for every skill are optional, but each choice should have a recognizable icon and text label. These are the current skill concepts to cover:

- General: Glass needle, Grave bloom, First spark, Blood thread, Ash ward, Quick hands, Quickdraw, Heavy momentum, Hawk eye, Ruin prism, Critical horizon and Unbound aim.
- Single element: Cinder crown, Frost prism, Alchemist fang, Venom veil, Wildfire seed, Winter bell, Vitriol shell and Plague vessel.
- Mixed elements: Steamglass, Caustic flame, Black ice, Toxic spark, Corrosive embers and Toxic glacier.
- Weapon and conditional skills: Glacial crusher, Venom edge, Frozen precision, Blood harvest, Armor crusher, Warded blade, Ashen charge, Breakthrough and Frost shatter.
- Advanced discoveries: Combustion, Toxic harvest and Exposed core.

For a first pass, use shared Fire / Frost / Acid / Poison icons with small secondary badges for weapon type, shield, heal, critical, burst or mixed-element pairing. Give especially important build-defining skills their own silhouettes after playtesting.

## 5. Progression and interface

- Hearth / sanctuary, flame fragment, manuscript / chronicle, rescued smith, rescued cartographer and final-heart / ending choice.
- Ember Tree, four tree branches (Vitality, Arsenal, Fortune, Runes), owned / available / locked node and prerequisite connector.
- Inventory / backpack, Your Build, skills, map, settings, audio, music, pause, resume, back, close cross, confirm, next / previous, help and information.
- Victory, death, boss defeated, run history, achievements / discoveries and optional difficulty vows.
- Keyboard/controller keycaps can be drawn by the UI with text so they reflect the player's bindings.

## 6. Enemy abilities and status effects

- Regeneration / healing, lifesteal, armor piercing, shield / guard, armor break, armor plates, interrupt / stagger, dodge / phase and heavy strike.
- Burning, Frost / freeze, Acid / corrosion and Poison. Reuse the four element silhouettes with a small status badge where possible.
- Boss cues: returning guard, tidal double strike, necromancer healing, furnace heat and eclipse seal. These should be visually distinctive at combat size and supported by clear text.
- Optional enemy-family markers: Marauder armor-piercing thrust, Revenant drain, Fiend fire resistance, Skullguard plates and Cultist phase.

## AI tools and release notes

- [PixelLab](https://www.pixellab.ai/) is specialized for pixel-art game assets and offers a free trial. Its [terms](https://www.pixellab.ai/termsofservice) allow commercial and non-commercial use of creations; verify current free-tier limits and terms when generating.
- [Adobe Firefly](https://www.adobe.com/products/firefly/features/pixel-art-generator.html) has free daily generations with an account. Adobe says outputs from its own Firefly Image models can be used commercially; partner models may have different terms. See [Adobe's commercial-use explanation](https://www.adobe.com/products/firefly/features/ai-art-generator.html).
- AI can produce inconsistent pixel grids or illegible small silhouettes. Use a pixel editor to clean up, align and test icons at their actual in-game size.
- If AI-generated artwork, narrative or other player-facing content ships with the game, check Steam's [Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey) and disclose pre-generated AI content where required. Track the model, date and source of shipped assets.

Example prompt: `Single 32x32 pixel-art icon of a corroded metal droplet for an acid armor-breaking effect, dark fantasy RPG, thick clear silhouette, muted olive green with one bright highlight, one-pixel dark outline, transparent background, no text, no border, no UI, consistent pixel grid.`
