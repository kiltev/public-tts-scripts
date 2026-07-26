-- Parity + unit spec for the spawn engine. Expected values are transcribed
-- directly from the ORIGINAL hand-written scripts (items_script.lua,
-- rimearc_spawner.lua), so this is a real regression net, not a mirror of the
-- engine. Returns the number of failures (run.js turns that into an exit code).

local failures = 0
local function fail(msg) failures = failures + 1; io.write("  FAIL: " .. msg .. "\n") end
local function ok(msg) io.write("  ok:   " .. msg .. "\n") end

local function deepEq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
  for k, v in pairs(b) do if not deepEq(v, a[k]) then return false end end
  return true
end

local function check(cond, msg) if cond then ok(msg) else fail(msg) end end
local function eq(a, b, msg) if deepEq(a, b) then ok(msg) else
    fail(msg .. "  (got " .. tostring(Engine.serialize(a)) .. ")") end end

local function contains(hay, needle) return hay:find(needle, 1, true) ~= nil end

local dawnEntry = DAWNBRINGER.objects[1]
local zephEntry = ZEPHYR.objects[1]

io.write("== kind aliases ==\n")
check(Engine.builderFor("item_deck") == "deck", "item_deck -> deck")
check(Engine.builderFor("modifier_deck") == "deck", "modifier_deck -> deck")
check(Engine.builderFor("token") == "token", "token -> token")
check(Engine.builderFor("condition") == "condition", "condition -> condition(+token)")

io.write("== anchor / class name ==\n")
check(Engine.classNameFromEnvelope("Dawnbringer Class Envelope") == "Dawnbringer",
  "class name stripped from envelope")
check(Engine.classNameFromEnvelope("Arctic Zephyr Class Envelope") == "Arctic Zephyr",
  "multi-word class name stripped")

io.write("== deck builder (Dawnbringer parity) ==\n")
-- setCustomObject in items_script.lua: face,back,width=3,height=3,number=9,back_is_hidden=true,unique_back=true
eq(Engine.deckCustomObject(dawnEntry), {
  face = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-front.png",
  back = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-back.png",
  width = 3, height = 3, number = 9,
  back_is_hidden = true, unique_back = true, sideways = false,
}, "deck custom-object matches original setCustomObject")

-- items_script.lua spawn: rotation {0,180,0}, scale {0.9,1,0.9}, sound=false; pos = anchor + offset
local dsp = Engine.deckSpawnParams(dawnEntry, { x = 100, y = 5, z = 200 })
check(dsp.type == "DeckCustom", "deck type DeckCustom")
eq(dsp.position, { 100 + -1.5, 5 + 1.2, 200 + 10.5 }, "deck position = anchor + offset")
eq(dsp.rotation, { 0, 180, 0 }, "deck rotation {0,180,0}")
eq(dsp.scale, { 0.9, 1, 0.9 }, "deck scale {0.9,1,0.9}")
check(dsp.sound == false, "deck sound=false")

io.write("== pack behaviour (Open Pack spread) ==\n")
local pc = Engine.packConfig(dawnEntry)
check(#pc.names == 9, "9 card names")
check(pc.names[1] == "Concussive Quarrel", "first name = Concussive Quarrel")
check(pc.names[9] == "Mutagen Syringe", "last name = Mutagen Syringe")
check(pc.columns == 5, "5 columns")
check(pc.stepX == 2.5 and pc.stepZ == 3.5, "grid steps 2.5/3.5")
check(pc.button.label == "Open Pack", "button label 'Open Pack'")
check(pc.button.width == 1400 and pc.button.font_size == 220, "button width/font match original")

local script = Engine.packScript(dawnEntry)
check(contains(script, "Open Pack"), "pack script embeds label")
check(contains(script, "Mutagen Syringe"), "pack script embeds names")
check(contains(script, "triggerSplit"), "pack script defines triggerSplit")
-- must be valid Lua
local chunk, err = load(script)
check(chunk ~= nil, "pack script is valid Lua" .. (err and (": " .. err) or ""))

io.write("== token builder (Zephyr Rimearc parity) ==\n")
local td = Engine.tokenData(zephEntry, { x = 10, y = 2, z = 3 })
check(td.Name == "Custom_Token", "token Name=Custom_Token")
check(td.Nickname == "Rimearc", "token Nickname=Rimearc")
eq(td.Tags, { "Has Action", "Has Aid Tokens", "Has Conditions", "Has Health", "Terrain" },
  "token tags match original (5)")
check(td.Transform.scaleX == 0.35 and td.Transform.scaleY == 0.6 and td.Transform.scaleZ == 0.35,
  "token scale {0.35,0.6,0.35}")
eq({ td.Transform.posX, td.Transform.posY, td.Transform.posZ }, { 10, 2, 3 }, "token transform pos")
check(td.CustomImage.ImageURL == "https://raw.githubusercontent.com/kiltev/zephyr/main/resources/icons/rimearc.png",
  "token image URL")
check(td.CustomImage.CustomToken.Thickness == 0.2, "token thickness 0.2")
check(td.CustomImage.CustomToken.MergeDistance == 15, "token merge distance 15")
check(td.CustomImage.CustomToken.Stackable == false, "token not stackable")

io.write("== condition registration marshaling ==\n")
resetCapture()
local condEntry = {
  kind = "condition", offset = { 0, 0, 0 },
  register = { name = "Frostbite", image = "http://img", max = 3,
    immunity = { image = "http://imm", sharedWith = { "Stun" } } },
}
Engine.spawnEntry(condEntry, FAKE_OBJECT({ _pos = { x = 0, y = 0, z = 0 } }))
check(#CAPTURE.apiCalls == 1, "one Global.call issued")
local call = CAPTURE.apiCalls[1]
check(call and call.fn == "api_condition_registerCondition", "marshals to api_condition_registerCondition")
check(call and call.params[1] == "Frostbite", "condition name is first arg")
check(call and call.params[2].image == "http://img" and call.params[2].max == 3, "condition def carries image+max")
check(call and call.params.__caller ~= nil and call.params.__version ~= nil, "marshal adds __caller + __version")

io.write("== integration: Dawnbringer deck spawn ==\n")
resetCapture()
_G.WAIT_RUN = true
_G.ALL_OBJECTS = {}
self.setName("Dawnbringer Class Envelope")
local dawnSheet = FAKE_OBJECT({ _name = "Dawnbringer", _guid = "sheet1", _pos = { x = 0, y = 0, z = 0 }, _tags = { "Character Sheet" } })
_G.OBJECTS_BY_TAG = { ["Character Sheet"] = { dawnSheet } }
Engine.run(DAWNBRINGER)
onLoad()
check(#CAPTURE.spawned >= 1, "deck spawned via onLoad")
local deckSpawn = CAPTURE.spawned[1]
check(deckSpawn and deckSpawn.params.type == "DeckCustom", "spawned a DeckCustom")
check(deckSpawn and deckSpawn.obj.getName() == "Dawnbringer Items Deck", "deck named 'Dawnbringer Items Deck'")
check(deckSpawn and deckSpawn.obj.getCustomObject() ~= nil, "deck got setCustomObject")
check(deckSpawn and deckSpawn.obj.getLuaScript() ~= nil, "deck got pack script attached")

io.write("== integration: Zephyr rimearc pool on envelope pull ==\n")
resetCapture()
self.setName("Arctic Zephyr Class Envelope")
local zephSheet = FAKE_OBJECT({ _name = "Arctic Zephyr", _guid = "sheet2", _pos = { x = 0, y = 0, z = 0 }, _tags = { "Character Sheet" } })
_G.OBJECTS_BY_TAG = { ["Character Sheet"] = { zephSheet } }
Engine.run(ZEPHYR)
onObjectLeaveContainer(self, FAKE_OBJECT({}))
local bag = nil
for _, s in ipairs(CAPTURE.spawned) do if s.params.type == "Infinite_Bag" then bag = s end end
check(bag ~= nil, "Infinite_Bag spawned")
check(bag and bag.obj.getName() == "Rimearc", "bag named 'Rimearc'")
check(#CAPTURE.dataSpawned >= 1, "token spawned via spawnObjectData")
local tok = CAPTURE.dataSpawned[1]
check(tok and #tok.data.Tags == 5, "token has 5 FHE tags")
check(#CAPTURE.puts >= 1, "token put into the bag")

io.write("== inject snippet drift (shipped manifest == fixture) ==\n")
eq(INJ_DAWN, DAWNBRINGER, "Dawnbringer perk-[19] manifest matches fixture")
eq(INJ_ZEPH, ZEPHYR, "Zephyr perk-[19] manifest matches fixture")

io.write("\n")
if failures == 0 then
  io.write("ALL PASS\n")
else
  io.write(failures .. " FAILURE(S)\n")
end
return failures
