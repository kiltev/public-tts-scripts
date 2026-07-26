--[[ =========================================================================
  Generic, parameter-driven spawn engine for Frosthaven-Enhanced custom
  classes. Injected onto a class ENVELOPE (self = envelope) via the perk-[19]
  bootstrap, with a class MANIFEST prepended ahead of this source.

  It reproduces the behaviour of hand-written class spawners (Dawnbringer's
  item pack, Zephyr's Rimearc pool) from configuration alone. Two primitive
  builders cover every content kind:

    kind          builder     notes
    ------------  ----------  ----------------------------------------------
    item_deck     deck        DeckCustom (+ optional "pack" spread button)
    modifier_deck deck        physical additional AM deck (drawn by hand)
    token         token       Custom_Token, optionally in an Infinite_Bag
    condition     token+API   ConditionApi.registerCondition + optional token

  Design decisions live in the README. Raw-spawn only; the single mod-API
  exception is condition registration (a thin Global.call marshal).
============================================================================ ]]

local Engine = {}

-- Must match the installed FHE mod's API version for the marshaled Global.call
-- (mirrors the mod's Resource.Version). See README "Condition registration".
Engine.FHE_API_VERSION = { 2, 5, 3 }

Engine.POLL_INTERVAL = 0.5
Engine.STABLE_FRAMES = 3
Engine.MAX_TRIES = 240
Engine.ANCHOR_TAGS = { "Character Sheet", "Character" }

-- ---- kind aliases -----------------------------------------------------

local DECK_ALIASES = { item_deck = true, modifier_deck = true, deck = true }
local TOKEN_ALIASES = { token = true }
local COND_ALIASES = { condition = true }

function Engine.builderFor(kind)
  if DECK_ALIASES[kind] then return "deck" end
  if TOKEN_ALIASES[kind] then return "token" end
  if COND_ALIASES[kind] then return "condition" end
  return nil
end

-- ---- serialization (for embedding config in generated object scripts) --

local function serialize(v)
  local t = type(v)
  if t == "string" then
    return string.format("%q", v)
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "table" then
    local parts = {}
    if #v > 0 then
      for _, item in ipairs(v) do parts[#parts + 1] = serialize(item) end
    else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      for _, k in ipairs(keys) do
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
          key = k
        else
          key = "[" .. serialize(k) .. "]"
        end
        parts[#parts + 1] = key .. "=" .. serialize(v[k])
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end
Engine.serialize = serialize

-- ---- anchor resolution (fixed strategy; not class-configurable) --------

function Engine.classNameFromEnvelope(name)
  name = name or ""
  name = name:gsub("%s*[Cc]lass%s*[Ee]nvelope%s*$", "")
  name = name:gsub("%s*[Ee]nvelope%s*$", "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  return name
end

function Engine.resolveAnchor(className)
  className = className or ""
  for _, tag in ipairs(Engine.ANCHOR_TAGS) do
    for _, o in ipairs(getObjectsWithTag(tag)) do
      local n = o.getName() or ""
      if o ~= self
          and (className == "" or n:find(className, 1, true))
          and not n:find("envelope", 1, true)
          and not n:find("Envelope", 1, true) then
        return o, tag
      end
    end
  end
  return nil
end

function Engine.offsetPos(anchorPos, offset)
  return {
    x = anchorPos.x + offset[1],
    y = anchorPos.y + offset[2],
    z = anchorPos.z + offset[3],
  }
end

-- ---- deck builder (pure) ----------------------------------------------

function Engine.deckSpawnParams(entry, anchorPos)
  local d = entry.deck
  local p = Engine.offsetPos(anchorPos, entry.offset)
  return {
    type = "DeckCustom",
    position = { p.x, p.y, p.z },
    rotation = d.rotation or { 0, 180, 0 },
    scale = d.scale or { 1, 1, 1 },
    sound = false,
  }
end

function Engine.deckCustomObject(entry)
  local d = entry.deck
  return {
    face = d.face,
    back = d.back,
    width = d.width,
    height = d.height,
    number = d.number,
    back_is_hidden = d.back_is_hidden and true or false,
    unique_back = d.unique_back and true or false,
    sideways = d.sideways and true or false,
  }
end

function Engine.packConfig(entry)
  local pk = entry.pack
  if not pk then return nil end
  return {
    button = pk.button,
    columns = pk.columns or 5,
    stepX = pk.stepX or 2.5,
    stepZ = pk.stepZ or 3.5,
    names = pk.names or {},
  }
end

Engine.PACK_TEMPLATE = [[
function onLoad()
  local b = CFG.button
  self.createButton({click_function="triggerSplit",function_owner=self,label=b.label,position=b.position,width=b.width,height=b.height,font_size=b.font_size,color=b.color,font_color=b.font_color})
end
function triggerSplit()
  self.clearButtons()
  local cards = self.spread(1)
  local p = self.getPosition()
  local cols, stepX, stepZ = CFG.columns, CFG.stepX, CFG.stepZ
  local names = CFG.names
  Wait.frames(function()
    for i=1, #names do
      local row, col = math.floor((i-1)/cols), (i-1)%cols
      local pos = {p.x + col*stepX, p.y + 1, p.z - row*stepZ}
      if cards[i] then
        cards[i].setName(names[i])
        cards[i].setPositionSmooth(pos, false, false)
      end
    end
  end, 2)
end]]

function Engine.packScript(entry)
  local cfg = Engine.packConfig(entry)
  if not cfg then return nil end
  return "local CFG = " .. serialize(cfg) .. "\n" .. Engine.PACK_TEMPLATE
end

-- ---- token builder (pure) ---------------------------------------------

-- Full object data so the token spawns FULLY FORMED (no "Custom Token" popup,
-- image baked into the bag's stored template).
function Engine.tokenData(entry, pos)
  local t = entry.token
  local s = t.scale or { 1, 1, 1 }
  return {
    Name = "Custom_Token",
    Transform = {
      posX = pos.x, posY = pos.y, posZ = pos.z,
      rotX = 0, rotY = 0, rotZ = 0,
      scaleX = s[1], scaleY = s[2], scaleZ = s[3],
    },
    Nickname = t.nickname or entry.name,
    Tags = t.tags or {},
    CustomImage = {
      ImageURL = t.image,
      ImageSecondaryURL = "",
      CustomToken = {
        Thickness = t.thickness or 0.2,
        MergeDistance = t.merge_distance or 15,
        Stackable = t.stackable and true or false,
      },
    },
  }
end

-- ---- condition registration (the one mod-API exception) ---------------

function Engine.conditionDef(entry)
  local r = entry.register
  if not r then return nil end
  local def = { image = r.image }
  if r.max then def.max = r.max end
  if r.immunity then def.immunity = r.immunity end
  return r.name, def
end

function Engine.apiParams(...)
  local params = table.pack(...)
  params.__caller = self.getGUID()
  params.__version = Engine.FHE_API_VERSION
  return params
end

function Engine.registerCondition(name, def)
  return Global.call("api_condition_registerCondition", Engine.apiParams(name, def))
end

-- ---- side-effecting spawn -------------------------------------------------

function Engine.spawnDeck(entry, anchorPos)
  local params = Engine.deckSpawnParams(entry, anchorPos)
  local custom = Engine.deckCustomObject(entry)
  local name = entry.name
  local script = Engine.packScript(entry)
  params.callback_function = function(deck)
    deck.setCustomObject(custom)
    deck.setName(name)
    if script then deck.setLuaScript(script) end
    deck.reload()
  end
  spawnObject(params)
end

function Engine.spawnTokenPool(entry, anchorPos)
  local pos = Engine.offsetPos(anchorPos, entry.offset)
  if entry.pool then
    spawnObject({
      type = "Infinite_Bag",
      position = { pos.x, pos.y, pos.z },
      sound = false,
      callback_function = function(bag)
        bag.setName(entry.name)
        spawnObjectData({
          data = Engine.tokenData(entry, { x = pos.x, y = pos.y + 3, z = pos.z }),
          callback_function = function(tok)
            Wait.condition(
              function() pcall(function() bag.putObject(tok) end) end,
              function() return not tok.spawning and not tok.loading_custom end,
              8)
          end,
        })
      end,
    })
  else
    spawnObjectData({
      data = Engine.tokenData(entry, pos),
      position = { pos.x, pos.y, pos.z },
    })
  end
end

function Engine.spawnEntry(entry, anchorObj)
  local builder = Engine.builderFor(entry.kind)
  local anchorPos = anchorObj.getPosition()
  if builder == "deck" then
    Engine.spawnDeck(entry, anchorPos)
  elseif builder == "token" then
    Engine.spawnTokenPool(entry, anchorPos)
  elseif builder == "condition" then
    if entry.register then
      local n, d = Engine.conditionDef(entry)
      Engine.registerCondition(n, d)
    end
    if entry.token then
      Engine.spawnTokenPool(entry, anchorPos)
    end
  end
end

-- ---- orchestration --------------------------------------------------------

function Engine.exists(name)
  for _, o in ipairs(getObjects()) do
    if o.getName and o.getName() == name then return true end
  end
  return false
end

-- respawnable=false entries are guarded (spawn once); respawnable=true always
-- (re)build, since they're torn down/recreated per envelope pull.
function Engine.spawnGroup(anchor, wantRespawnable)
  for _, entry in ipairs(Engine.manifest.objects) do
    local resp = entry.respawnable and true or false
    if resp == wantRespawnable then
      if wantRespawnable or not Engine.exists(entry.name) then
        Engine.spawnEntry(entry, anchor)
      end
    end
  end
end

-- Poll until the anchor exists and holds still, then fire onStable(anchor).
function Engine.watchAnchor(onStable)
  local last, stable, tries = nil, 0, 0
  local function tick()
    tries = tries + 1
    local anchor = Engine.resolveAnchor(Engine.className)
    if anchor then
      local ap = anchor.getPosition()
      if last and math.abs(ap.x - last.x) < 0.05 and math.abs(ap.y - last.y) < 0.05
          and math.abs(ap.z - last.z) < 0.05 then
        stable = stable + 1
      else
        stable = 0
      end
      last = { x = ap.x, y = ap.y, z = ap.z }
      if stable >= Engine.STABLE_FRAMES then onStable(anchor); return end
    end
    if tries < Engine.MAX_TRIES then Wait.time(tick, Engine.POLL_INTERVAL) end
  end
  tick()
end

function Engine.run(manifest)
  Engine.manifest = manifest
  Engine.className = manifest.class or Engine.classNameFromEnvelope(self.getName())

  function onLoad()
    Engine.watchAnchor(function(anchor) Engine.spawnGroup(anchor, false) end)
  end

  -- Rebuild respawnable content each time something is pulled from the envelope.
  function onObjectLeaveContainer(container, _leaving)
    if container ~= self then return end
    Engine.watchAnchor(function(anchor) Engine.spawnGroup(anchor, true) end)
  end
end

-- When injected in-game, a MANIFEST global is prepended ahead of this source.
-- In tests, MANIFEST is nil and specs drive Engine.* directly.
if MANIFEST then Engine.run(MANIFEST) end

return Engine
