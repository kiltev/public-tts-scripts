[19]={(function()
    local NAMD_CARD_NAME = "Perk Reminder Your Reminder Name"
    local NAMD_BACK_URL = "https://example.com/your-perk-reminder-back.png"

    local CLASS_NAME = self.getName()
    local OWNER_TAG_PREFIX = "Owner "
    local CARD_OBJECT_TYPE = "Card"
    local SETTLE_TIMEOUT_SECONDS = 30
    local REGISTER_DELAY_SECONDS = 0.5

    local function isNamdCard(object)
        return object.type == CARD_OBJECT_TYPE and object.getName() == NAMD_CARD_NAME
    end

    local function ownedNamdCards(playerNumber)
        local cards = {}
        for _, object in ipairs(getObjectsWithTag(OWNER_TAG_PREFIX .. playerNumber)) do
            if isNamdCard(object) then table.insert(cards, object) end
        end
        return cards
    end

    local function isSettled(card)
        return not card.spawning and not card.loading_custom
    end

    local function allSettled(cards)
        if #cards == 0 then return false end
        for _, card in ipairs(cards) do
            if not isSettled(card) then return false end
        end
        return true
    end

    local function hasCustomBack(data)
        for _, deck in pairs(data.CustomDeck or {}) do
            if deck.BackURL ~= NAMD_BACK_URL then return false end
        end
        return true
    end

    local function withCustomBack(data)
        for _, deck in pairs(data.CustomDeck) do
            deck.BackURL = NAMD_BACK_URL
            deck.UniqueBack = false
        end
        return data
    end

    local function replaceBack(card)
        local data = card.getData()
        if hasCustomBack(data) then return end
        card.destruct()
        spawnObjectData({ data = withCustomBack(data) })
    end

    local function replaceBacks(playerNumber)
        for _, card in ipairs(ownedNamdCards(playerNumber)) do replaceBack(card) end
    end

    function onCharacterLoad(character, playerNumber)
        if character.class ~= CLASS_NAME then return end
        Wait.condition(
            function() replaceBacks(playerNumber) end,
            function() return allSettled(ownedNamdCards(playerNumber)) end,
            SETTLE_TIMEOUT_SECONDS)
    end

    function __callExtension(request)
        return _G[request.event](table.unpack(request.parameters))
    end

    Wait.time(function()
        Global.call("__registerExtensions", { __caller = self.getGUID() })
    end, REGISTER_DELAY_SECONDS)
end)()},
