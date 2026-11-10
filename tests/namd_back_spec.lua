local failures = 0

local CLASS_NAME = "Revenant"
local OTHER_CLASS_NAME = "Dawnbringer"
local LOADING_PLAYER = 3
local OTHER_PLAYER = 1
local DECK_KEY = "2001"
local FACE_SHEET_URL = "https://example.com/revenant-perk-reminders.png"
local DEFAULT_BACK_URL = "https://example.com/revenant-perk-reminder-back.png"
local CUSTOM_BACK_URL = NAMD_BACK_SOURCE:match('NAMD_BACK_URL = "(.-)"')
local NAMD_NAME = NAMD_BACK_SOURCE:match('NAMD_CARD_NAME = "(.-)"')
local SIBLING_NAMD_NAME = "Perk Reminder Chosen of Aksut"
local AMD_NAME = "Attack Modifier (+1) (Wound)"

local function check(isTrue, behaviour)
  if isTrue then io.write("  ok:   " .. behaviour .. "\n") return end
  failures = failures + 1
  io.write("  FAIL: " .. behaviour .. "\n")
end

local function isDeepEqual(left, right)
  if type(left) ~= "table" or type(right) ~= "table" then return left == right end
  for key, value in pairs(left) do
    if not isDeepEqual(value, right[key]) then return false end
  end
  for key in pairs(right) do
    if left[key] == nil then return false end
  end
  return true
end

local function cardData(name, playerNumber, backUrl)
  return {
    Name = "Card", Nickname = name, CardID = 200102, Tags = { "Owner " .. playerNumber },
    Transform = { posX = -3.62, posY = 1.76, posZ = -39.2, rotX = 0, rotY = 180, rotZ = 0,
                  scaleX = 0.6, scaleY = 1, scaleZ = 0.6 },
    CustomDeck = { [DECK_KEY] = { FaceURL = FACE_SHEET_URL, BackURL = backUrl, NumWidth = 2, NumHeight = 2,
                                  BackIsHidden = true, UniqueBack = true, Type = 0 } },
  }
end

local function tableCard(name, playerNumber, backUrl)
  local data = cardData(name, playerNumber, backUrl or DEFAULT_BACK_URL)
  return FAKE_OBJECT({ _name = name, _data = data, _tags = data.Tags, type = "Card" })
end

local function placeOnTable(objects)
  local objectsByTag = {}
  for _, object in ipairs(objects) do
    for _, tag in ipairs(object.getTags()) do
      objectsByTag[tag] = objectsByTag[tag] or {}
      table.insert(objectsByTag[tag], object)
    end
  end
  _G.OBJECTS_BY_TAG = objectsByTag
end

local function loadEnvelope()
  resetCapture()
  PENDING_CONDITIONS = {}
  _G.WAIT_RUN = true
  _G.OBJECTS_BY_TAG = {}
  self.setName(CLASS_NAME)
  load("return {" .. NAMD_BACK_SOURCE .. "}")()
end

local function fheLoadsCharacter(className, playerNumber)
  __callExtension({ event = "onCharacterLoad", parameters = { { class = className }, playerNumber } })
end

local function respawnedData()
  for _, spawn in ipairs(CAPTURE.dataSpawned) do
    if spawn.data.Nickname == NAMD_NAME then return spawn.data end
  end
end

local function scenario(behaviour, run)
  loadEnvelope()
  check(run(), behaviour)
end

local function sameCardOnCustomBack(card)
  local expected = cardData(NAMD_NAME, LOADING_PLAYER, CUSTOM_BACK_URL)
  expected.CustomDeck[DECK_KEY].UniqueBack = false
  return card._destroyed == true and isDeepEqual(respawnedData(), expected)
end

io.write("== NAMD back swap [19] ==\n")

check(CUSTOM_BACK_URL ~= nil, "the custom back URL is a constant the spec can read from the script")
check(NAMD_NAME ~= nil, "the NAMD card to restyle is named by a constant the spec can read from the script")

scenario("the envelope registers itself with FHE's extension API so onCharacterLoad reaches it", function()
  local call = CAPTURE.apiCalls[1]
  return call ~= nil and call.fn == "__registerExtensions" and call.params.__caller == self.getGUID()
end)

scenario("a NAMD card in the loading player's area becomes the same card, at the same spot with the same owner, on the custom back", function()
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  placeOnTable({ namd })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return sameCardOnCustomBack(namd)
end)

scenario("the custom back is one whole image, so the card stops cutting its back out of a unique-back sheet", function()
  placeOnTable({ tableCard(NAMD_NAME, LOADING_PLAYER) })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return respawnedData().CustomDeck[DECK_KEY].UniqueBack == false
end)

scenario("the swap waits for NAMD cards FHE places a frame after onCharacterLoad fires", function()
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  placeOnTable({ namd })
  runReadyConditions()
  return sameCardOnCustomBack(namd)
end)

scenario("a NAMD card still spawning or loading its images is left alone until it has fully loaded", function()
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  namd.spawning, namd.loading_custom = true, true
  placeOnTable({ namd })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  namd.spawning = false
  runReadyConditions()
  local untouchedWhileLoading = not namd._destroyed
  namd.loading_custom = false
  runReadyConditions()
  return untouchedWhileLoading and sameCardOnCustomBack(namd)
end)

scenario("only the named NAMD card changes, the player's other reminder cards keep their default back", function()
  local sibling = tableCard(SIBLING_NAMD_NAME, LOADING_PLAYER)
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  placeOnTable({ sibling, namd })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return not sibling._destroyed and sameCardOnCustomBack(namd)
end)

scenario("the swap waits for the named NAMD card even when the player's other reminder cards have already loaded", function()
  placeOnTable({ tableCard(SIBLING_NAMD_NAME, LOADING_PLAYER) })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  placeOnTable({ tableCard(SIBLING_NAMD_NAME, LOADING_PLAYER), namd })
  runReadyConditions()
  return sameCardOnCustomBack(namd)
end)

scenario("another player's NAMD card keeps its default back", function()
  local theirs = tableCard(NAMD_NAME, OTHER_PLAYER)
  placeOnTable({ tableCard(NAMD_NAME, LOADING_PLAYER), theirs })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return not theirs._destroyed
end)

scenario("an attack modifier card in the loading player's area keeps its back", function()
  local modifier = tableCard(AMD_NAME, LOADING_PLAYER)
  placeOnTable({ tableCard(NAMD_NAME, LOADING_PLAYER), modifier })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return not modifier._destroyed
end)

scenario("a NAMD card already on the custom back stays put, so loading again never respawns it", function()
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER, CUSTOM_BACK_URL)
  placeOnTable({ namd })
  fheLoadsCharacter(CLASS_NAME, LOADING_PLAYER)
  return not namd._destroyed and #CAPTURE.dataSpawned == 0
end)

scenario("loading a character of another class leaves every NAMD card alone and waits for nothing", function()
  local namd = tableCard(NAMD_NAME, LOADING_PLAYER)
  placeOnTable({ namd })
  fheLoadsCharacter(OTHER_CLASS_NAME, LOADING_PLAYER)
  return not namd._destroyed and #PENDING_CONDITIONS == 0
end)

io.write("\n")
if failures == 0 then io.write("ALL PASS\n") else io.write(failures .. " FAILURE(S)\n") end
return failures
