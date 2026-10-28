[19]={(function()
    local EMPOWER_CARD_IMAGE_URL = "https://example.com/your-empower-card.png"
    local EMPOWER_CARD_COUNT = 12
    local SOLO_ITEM_FRONT_URL = "https://example.com/your-solo-item-front.png"
    local SOLO_ITEM_BACK_URL = "https://example.com/your-solo-item-back.png"
    local CONDITION_NAME = "Your Condition"
    local RUPTURE_IMAGE_URL = "https://steamusercontent-a.akamaihd.net/ugc/1912358305604702725/9BE1B7F00534E8A3C9BC2C07C13B840A6ADF6ECD/"
    local CONDITION_MAX_STACK = 1
    local CARD_BACK_URL = "https://steamusercontent-a.akamaihd.net/ugc/54701802010896866/AB8DD9E90F1F31A1B80E004A35B46F72FCFE25E1/"

    local CLASS_NAME = self.getName()
    local EMPOWER_CARD_NAME = "Empower"
    local EMPOWER_DECK_NAME = CLASS_NAME .. " Empowers (" .. EMPOWER_CARD_COUNT .. ")"
    local SOLO_ITEM_NAME = CLASS_NAME .. " Solo Scenario Item"
    local CARD_ID = 100
    local ATTACK_MODIFIER_SCALE = { scaleX = 0.6, scaleY = 1, scaleZ = 0.6 }
    local ITEM_CARD_SCALE = { scaleX = 0.93, scaleY = 1, scaleZ = 0.93 }
    local SLOT_RIGHT_OF_LOCKED_MODIFIERS = { -0.192, 0.1, 0.912 }
    local SLOT_BELOW_CHARACTER_BOX = { -0.384, 0.1, 0.912 }
    local FACE_UP_TOWARDS_PLAYER = { 0, 180, 0 }
    local PLAYER_MAT_TAG = "Player Mat"
    local OWNER_TAG_PREFIX = "Owner "
    local CONDITION_REGISTER_API = "api_condition_registerCondition"
    local REGISTER_DELAY_SECONDS = 0.5

    local function singleImageDeck(faceUrl, backUrl, hasUniqueBack)
        return {
            ["1"] = {
                FaceURL = faceUrl, BackURL = backUrl,
                NumWidth = 1, NumHeight = 1, BackIsHidden = true, UniqueBack = hasUniqueBack, Type = 0,
            },
        }
    end

    local EMPOWER_DECK_ART = singleImageDeck(EMPOWER_CARD_IMAGE_URL, CARD_BACK_URL, false)
    local SOLO_ITEM_ART = singleImageDeck(SOLO_ITEM_FRONT_URL, SOLO_ITEM_BACK_URL, true)

    local function exists(name)
        for _, object in ipairs(getObjects()) do
            if object.getName() == name then return true end
        end
        return false
    end

    local function playerMat(playerNumber)
        for _, object in ipairs(getObjectsWithTag(OWNER_TAG_PREFIX .. playerNumber)) do
            if object.hasTag(PLAYER_MAT_TAG) then return object end
        end
        return nil
    end

    local function cardData(name, art, scale)
        return { Name = "Card", Nickname = name, CardID = CARD_ID, Transform = scale, CustomDeck = art }
    end

    local function empowerDeckData()
        local cards, cardIds = {}, {}
        for copy = 1, EMPOWER_CARD_COUNT do
            cards[copy] = cardData(EMPOWER_CARD_NAME, EMPOWER_DECK_ART, ATTACK_MODIFIER_SCALE)
            cardIds[copy] = CARD_ID
        end
        return {
            Name = "DeckCustom", Nickname = EMPOWER_DECK_NAME, Transform = ATTACK_MODIFIER_SCALE,
            DeckIDs = cardIds, CustomDeck = EMPOWER_DECK_ART, ContainedObjects = cards,
        }
    end

    local function empowerData()
        if EMPOWER_CARD_COUNT == 1 then
            return cardData(EMPOWER_DECK_NAME, EMPOWER_DECK_ART, ATTACK_MODIFIER_SCALE)
        end
        return empowerDeckData()
    end

    local function spawnOnMat(mat, data, slot)
        spawnObjectData({ data = data, position = mat.positionToWorld(slot), rotation = FACE_UP_TOWARDS_PLAYER })
    end

    local function spawnMissing(mat)
        if not exists(EMPOWER_DECK_NAME) then
            spawnOnMat(mat, empowerData(), SLOT_RIGHT_OF_LOCKED_MODIFIERS)
        end
        if not exists(SOLO_ITEM_NAME) then
            spawnOnMat(mat, cardData(SOLO_ITEM_NAME, SOLO_ITEM_ART, ITEM_CARD_SCALE), SLOT_BELOW_CHARACTER_BOX)
        end
    end

    local function registerCondition()
        Global.call(CONDITION_REGISTER_API, { CONDITION_NAME, { image = RUPTURE_IMAGE_URL, max = CONDITION_MAX_STACK } })
    end

    function onCharacterLoad(character, playerNumber)
        if character.class ~= CLASS_NAME then return end
        local mat = playerMat(playerNumber)
        if mat ~= nil then spawnMissing(mat) end
    end

    function __callExtension(request)
        return _G[request.event](table.unpack(request.parameters))
    end

    Wait.time(function()
        Global.call("__registerExtensions", { __caller = self.getGUID() })
        registerCondition()
    end, REGISTER_DELAY_SECONDS)
end)()},
