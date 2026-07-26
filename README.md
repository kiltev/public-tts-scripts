# TTS Spawn Engine

A generic, parameter-driven spawner for **Frosthaven – TTS Enhanced (FHE)**
custom classes. One shared engine + a per-class **manifest** replaces
hand-written spawner scripts. Given the right manifest it reproduces existing
class content exactly (Dawnbringer's item pack, Arctic Zephyr's Rimearc pool).

> This is a standalone, reusable dependency — any class (Dawnbringer, Arctic
> Zephyr, …) consumes the same engine. Classes reference `engine.lua` by its
> raw URL: `https://raw.githubusercontent.com/kiltev/public-tts-scripts/main/engine.lua`

## How it works

Each class's attack-modifier **perks table** carries a `[19]` bootstrap entry
(see `inject/`). On load it:

1. holds this class's `MANIFEST` inline,
2. `WebRequest.get`s the shared `engine.lua`,
3. installs `setLuaScript(MANIFEST .. engine)` onto the **envelope** and reloads.

The engine then resolves the class's on-table **anchor** (the character
sheet/figure), waits for it to settle, and spawns every object in the manifest
at its configured offset.

### Why this shape (the load-bearing constraints)

- **One script per object.** TTS objects hold exactly one Lua script, and
  `setLuaScript` **replaces** it wholesale. Injecting a spawner onto the
  envelope is only safe because it happens *after* FHE has already consumed the
  perks table (the 0.5 s delay), so nothing functional is lost.
- **Do not scale with more perk slots.** Multiple `[19]/[20]/…` entries on the
  same object race on `setLuaScript` (last write wins). Scale by **manifest
  rows**, not perk slots. Extra slots are only for a *different* host object —
  and the envelope is effectively the only safe hijack target (the character
  sheet/mat have live scripts you'd destroy).
- **Raw-spawn only.** Objects are spawned self-contained (no dependency on
  FHE's clone pipeline). The single exception is condition *registration*
  (below), which needs one small mod-API call.

## Manifest schema

```lua
MANIFEST = {
  class = "Dawnbringer",      -- optional; else derived from the envelope name
  objects = { <entry>, ... },
}
```

Every entry shares:

| field | type | notes |
|---|---|---|
| `kind` | string | `item_deck` / `modifier_deck` / `token` / `condition` |
| `name` | string | spawned object (or bag) name; used as the spawn-once guard |
| `offset` | `{x,y,z}` | world-space offset from the fixed anchor |
| `respawnable` | bool | `false` = spawn once + guard; `true` = rebuild on every envelope pull (`onObjectLeaveContainer`) |

### `deck` builder — `item_deck`, `modifier_deck`

```lua
deck = {
  face, back,                 -- card-sheet URLs
  width, height, number,      -- grid columns/rows + total cards
  back_is_hidden, unique_back, sideways,   -- bools
  rotation = {0,180,0},       -- default face-down
  scale = {1,1,1},
},
pack = {                      -- OPTIONAL "Open Pack" spread button
  button = { label, width, height, font_size, color, font_color, position },
  columns, stepX, stepZ,      -- grid layout for the spread
  names = { ... },            -- names applied to the spread cards
},
```

- Omit `pack` → a plain `DeckCustom` (e.g. an additional AM deck, drawn by hand).
- `number = 1` yields effectively a single item.

> **Additional attack-modifier decks are physical only.** FHE has *no
> supported scripting API* to register a second drawable AM deck (its docs
> flag this as "not supported through scripting"). This engine spawns the deck
> as an object; it is **not** wired into the mod's draw / advantage / shuffle
> engine.

### `token` builder — `token`, and the physical part of `condition`

```lua
pool = true,                  -- wrap the token in an Infinite_Bag (pull infinitely)
token = {
  nickname,                   -- defaults to entry.name
  image,                      -- transparent PNG URL
  tags = { ... },             -- FHE trait tags, e.g. "Has Health", "Terrain", "Condition"
  scale = {x,y,z},
  thickness = 0.2,
  merge_distance = 15,
  stackable = false,
},
```

### `condition` — register (menu) + optional token(s)

Conditions **must be registered** to appear in a figure's menu (confirmed by
FHE's `condition.adoc`; there is no content-box auto-ingest for conditions).

```lua
{
  kind = "condition",
  offset = {x,y,z},
  register = {                -- REQUIRED: puts it in the menu
    name, image,              -- image URL required
    max,                      -- optional stack limit
    immunity = { image, sharedWith = { "Stun", ... } },  -- optional
  },
  pool = true,                -- optional: also spawn droppable marker(s)
  token = { image, tags = { "Condition" }, scale = {...} },
}
```

Registration marshals to `Global.call("api_condition_registerCondition",
{name, def, __caller, __version})` — a ~10-line shim, not the crash-prone
Overlay bundle.

## Install (per class)

1. The class inject snippet's `ENGINE_URL` already points at this repo's raw
   `engine.lua`. (Override only if you fork/host it elsewhere.)
2. Paste the snippet from `inject/<class>_perk19.lua` as the `[19]` entry of the
   class envelope's perks table.
3. Edit the embedded `MANIFEST` for that class. (The engine repo's
   `manifests/<class>.lua` mirrors it as the test fixture — an automated drift
   check asserts they stay identical.)

## Tests

```
npm install     # once (fengari — a Lua VM for Node)
npm test        # node tests/run.js
```

The harness stubs the TTS runtime (`spawnObject`, `spawnObjectData`,
`getObjects`, `WebRequest`, `Wait`, `Global.call`) and asserts the engine
produces the **exact** data tables of the original scripts (card
count/IDs/names, token tags/scale, condition register args), plus the shipped
inject manifests match their fixtures. Run it before every engine change.

A manual in-TTS pass still confirms visuals/timing the harness can't:
the Open Pack spread layout, and the `onObjectLeaveContainer` rebuild.

## Known limitations / build-time notes

- **FHE API version.** `Engine.FHE_API_VERSION` (`{2,5,3}`) must match the
  installed mod for the condition-registration marshal; bump if the mod updates.
- **Condition timing.** Registration runs after the post-setup envelope hijack;
  verify it still populates the menu. Fallback: call `registerCondition` from
  the perk IIFE (fires during setup) instead.
- **Anchor swap.** Dawnbringer's old GUID anchor is replaced by the standard
  tag+name resolver. Confirm in-game it resolves to the same sheet so the
  existing offset still lands.
