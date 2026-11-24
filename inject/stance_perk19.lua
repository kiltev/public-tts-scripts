[19]={(function()
    local CLASS_NAME = "Frostguard"
    local VANGUARD_ICON_URL = "https://i.imgur.com/RJugn5h.png"
    local REARGUARD_ICON_URL = "https://i.imgur.com/RhTKTDc.png"
    local VANGUARD_COLOR = "#d6efff"
    local REARGUARD_COLOR = "#8b4141"
    local VANGUARD_TEXT_COLOR = "#000000"
    local REARGUARD_TEXT_COLOR = "#FFFFFF"

    local VANGUARD_ICON_NAME = CLASS_NAME .. "-Stance-Vanguard"
    local REARGUARD_ICON_NAME = CLASS_NAME .. "-Stance-Rearguard"
    local FIGURE_TAG = "Character"
    local INFO_OPENING = "info = {"
    local REGISTER_DELAY_SECONDS = 0.5
    local SUCCESS_COLOR = "Green"
    local FAILURE_COLOR = "Red"

    local STANCES_SOURCE = string.format([[info = {
  stances = {
    { label = "Vanguard", color = "%s", textColor = "%s", icon = "%s" },
    { label = "Rearguard", color = "%s", textColor = "%s", icon = "%s" },
  },
  startingStance = 1,]],
        VANGUARD_COLOR, VANGUARD_TEXT_COLOR, VANGUARD_ICON_NAME,
        REARGUARD_COLOR, REARGUARD_TEXT_COLOR, REARGUARD_ICON_NAME)

    local isAdding = false

    local function findFigure()
        for _, object in ipairs(getObjectsWithTag(FIGURE_TAG)) do
            if object.getName() == CLASS_NAME then return object end
        end
    end

    local function isFigureReady()
        local figure = findFigure()
        return figure ~= nil and not figure.spawning and not figure.loading_custom
    end

    local function hasStances(figure)
        return figure.getLuaScript():find(VANGUARD_ICON_NAME, 1, true) ~= nil
    end

    local function withStanceIcons(assets)
        table.insert(assets, { name = VANGUARD_ICON_NAME, url = VANGUARD_ICON_URL })
        table.insert(assets, { name = REARGUARD_ICON_NAME, url = REARGUARD_ICON_URL })
        return assets
    end

    local function rewriteFigure(figure)
        local script, replacements = figure.getLuaScript():gsub(INFO_OPENING, STANCES_SOURCE, 1)
        if replacements == 0 then
            printToAll(CLASS_NAME .. " stance bar: no '" .. INFO_OPENING .. "' in the figure script", FAILURE_COLOR)
            return
        end
        figure.UI.setCustomAssets(withStanceIcons(figure.UI.getCustomAssets() or {}))
        figure.setLuaScript(script)
        figure.reload()
        printToAll(CLASS_NAME .. " stance bar added", SUCCESS_COLOR)
    end

    local function addStances()
        isAdding = false
        local figure = findFigure()
        if hasStances(figure) then return end
        rewriteFigure(figure)
    end

    local function addStancesWhenReady()
        if isAdding then return end
        isAdding = true
        Wait.condition(addStances, isFigureReady)
    end

    function onCharacterLoad(character)
        if character.class ~= CLASS_NAME then return end
        addStancesWhenReady()
    end

    function __callExtension(request)
        return _G[request.event](table.unpack(request.parameters))
    end

    Wait.time(function()
        addStancesWhenReady()
        pcall(Global.call, "__registerExtensions", { __caller = self.getGUID() })
    end, REGISTER_DELAY_SECONDS)
end)()},
