[19]={(function()
    local VANGUARD_ICON_URL = "https://i.imgur.com/RJugn5h.png"
    local REARGUARD_ICON_URL = "https://i.imgur.com/RhTKTDc.png"
    local VANGUARD_COLOR = "#d6efff"
    local REARGUARD_COLOR = "#8b4141"
    local VANGUARD_TEXT_COLOR = "#000000"
    local REARGUARD_TEXT_COLOR = "#FFFFFF"

    local CLASS_NAME = self.getName()
    local VANGUARD_ICON_NAME = CLASS_NAME .. "-Stance-Vanguard"
    local REARGUARD_ICON_NAME = CLASS_NAME .. "-Stance-Rearguard"
    local FIGURE_TAG = "Character"
    local INFO_OPENING = "info = {"
    local SETTLE_TIMEOUT_SECONDS = 30
    local REGISTER_DELAY_SECONDS = 0.5

    local STANCES_SOURCE = string.format([[info = {
  stances = {
    { label = "Vanguard", color = "%s", textColor = "%s", icon = "%s" },
    { label = "Rearguard", color = "%s", textColor = "%s", icon = "%s" },
  },
  startingStance = 1,]],
        VANGUARD_COLOR, VANGUARD_TEXT_COLOR, VANGUARD_ICON_NAME,
        REARGUARD_COLOR, REARGUARD_TEXT_COLOR, REARGUARD_ICON_NAME)

    local function isClassFigure(object)
        local name = object.getName() or ""
        return name == CLASS_NAME and object ~= self
    end

    local function findFigure()
        for _, object in ipairs(getObjectsWithTag(FIGURE_TAG)) do
            if isClassFigure(object) then return object end
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

    local function addStances(figure)
        if hasStances(figure) then return end
        local script = figure.getLuaScript():gsub(INFO_OPENING, STANCES_SOURCE, 1)
        figure.UI.setCustomAssets(withStanceIcons(figure.UI.getCustomAssets() or {}))
        figure.setLuaScript(script)
        figure.reload()
    end

    local function addStancesWhenReady()
        Wait.condition(function() addStances(findFigure()) end, isFigureReady, SETTLE_TIMEOUT_SECONDS)
    end

    function onCharacterLoad(character)
        if character.class ~= CLASS_NAME then return end
        addStancesWhenReady()
    end

    function __callExtension(request)
        return _G[request.event](table.unpack(request.parameters))
    end

    Wait.time(function()
        Global.call("__registerExtensions", { __caller = self.getGUID() })
        addStancesWhenReady()
    end, REGISTER_DELAY_SECONDS)
end)()},
