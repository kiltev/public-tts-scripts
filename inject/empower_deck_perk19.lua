[19]={(function()
    local EMPOWER_CARD_IMAGE_URL = "https://example.com/your-empower-card.png"
    local EMPOWER_CARD_COUNT = 10
    local CARD_BACK_URL = "https://steamusercontent-a.akamaihd.net/ugc/54701802010896866/AB8DD9E90F1F31A1B80E004A35B46F72FCFE25E1/"

    local CLASS_NAME = self.getName()
    local CARD_NAME = "Empower"
    local DECK_NAME = CLASS_NAME .. " Empowers (" .. EMPOWER_CARD_COUNT .. ")"
    local CARD_ID = 100
    local CUSTOM_DECK = {
        ["1"] = {
            FaceURL = EMPOWER_CARD_IMAGE_URL, BackURL = CARD_BACK_URL,
            NumWidth = 1, NumHeight = 1, BackIsHidden = true, UniqueBack = false, Type = 0,
        },
    }
    local ATTACK_MODIFIER_SCALE = { scaleX = 0.6, scaleY = 1, scaleZ = 0.6 }
    local SLOT_BELOW_CHARACTER_BOX = { -0.384, 0.1, 0.912 }
    local FACE_UP_TOWARDS_PLAYER = { 0, 180, 0 }
    local PLAYER_MAT_TAG = "Player Mat"
    local OWNER_TAG_PREFIX = "Owner "
    local REGISTER_DELAY_SECONDS = 0.5

    local function deckExists()
        for _, object in ipairs(getObjects()) do
            if object.getName() == DECK_NAME then return true end
        end
        return false
    end

    local function playerMat(playerNumber)
        for _, object in ipairs(getObjectsWithTag(OWNER_TAG_PREFIX .. playerNumber)) do
            if object.hasTag(PLAYER_MAT_TAG) then return object end
        end
        return nil
    end

    local function cardData()
        return {
            Name = "Card", Nickname = CARD_NAME, CardID = CARD_ID,
            Transform = ATTACK_MODIFIER_SCALE, CustomDeck = CUSTOM_DECK,
        }
    end

    local function deckData()
        local cards, cardIds = {}, {}
        for copy = 1, EMPOWER_CARD_COUNT do
            cards[copy] = cardData()
            cardIds[copy] = CARD_ID
        end
        return {
            Name = "DeckCustom", Transform = ATTACK_MODIFIER_SCALE,
            DeckIDs = cardIds, CustomDeck = CUSTOM_DECK, ContainedObjects = cards,
        }
    end

    local function empowerData()
        local data = EMPOWER_CARD_COUNT == 1 and cardData() or deckData()
        data.Nickname = DECK_NAME
        return data
    end

    local function spawnEmpowers(mat)
        spawnObjectData({
            data = empowerData(),
            position = mat.positionToWorld(SLOT_BELOW_CHARACTER_BOX),
            rotation = FACE_UP_TOWARDS_PLAYER,
        })
    end

    function onCharacterLoad(character, playerNumber)
        if character.class ~= CLASS_NAME or deckExists() then return end
        local mat = playerMat(playerNumber)
        if mat ~= nil then spawnEmpowers(mat) end
    end

    function __callExtension(request)
        return _G[request.event](table.unpack(request.parameters))
    end

    Wait.time(function()
        Global.call("__registerExtensions", { __caller = self.getGUID() })
    end, REGISTER_DELAY_SECONDS)
end)()},
