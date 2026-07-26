-- Perk-[19] injection for Dawnbringer. Paste this as the [19] entry of the
-- class envelope's perks table (see Human_Dawnbringer__perks.lua). On load it
-- prepends this class's MANIFEST to the fetched generic engine and installs
-- the combined script onto the envelope (self).
--
-- The embedded MANIFEST is the source of truth that ships; the engine repo's
-- manifests/dawnbringer.lua is its test-fixture mirror (keep them in sync).

  [19]={ (function()
      local ENGINE_URL = "https://raw.githubusercontent.com/kiltev/public-tts-scripts/main/engine.lua?v=1"

      local MANIFEST_SRC = [==[
MANIFEST = {
  class = "Dawnbringer",
  objects = {
    {
      kind = "item_deck",
      name = "Dawnbringer Items Deck",
      offset = { -1.5, 1.2, 10.5 },
      respawnable = false,
      deck = {
        face = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-front.png",
        back = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-back.png",
        width = 3, height = 3, number = 9,
        back_is_hidden = true, unique_back = true, sideways = false,
        rotation = { 0, 180, 0 }, scale = { 0.9, 1, 0.9 },
      },
      pack = {
        button = { label = "Open Pack", width = 1400, height = 400, font_size = 220,
                   color = { 0, 0, 0, 0.9 }, font_color = { 1, 1, 1, 1 }, position = { 0, 0.5, 0 } },
        columns = 5, stepX = 2.5, stepZ = 3.5,
        names = { "Concussive Quarrel", "Corrosive Darts", "Silver Bolts",
                  "Smoke Bomb", "Unstable Flask", "Jagged Caltrops",
                  "Harpoon Tether", "Ancient Technology", "Mutagen Syringe" },
      },
    },
  },
}
]==]

      Wait.time(function()
          WebRequest.get(ENGINE_URL, function(r)
              if r.text and not r.is_error then
                  self.setLuaScript(MANIFEST_SRC .. "\n" .. r.text)
                  self.reload()
              end
          end)
      end, 0.5)

      return "Active"
  end)() },
