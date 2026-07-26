-- Perk-[19] injection for Arctic Zephyr. Paste this as the [19] entry of the
-- class envelope's perks table (see Algox_Arctic_Zephyr_perks.lua). On load it
-- prepends this class's MANIFEST to the fetched generic engine and installs
-- the combined script onto the envelope (self).
--
-- The embedded MANIFEST is the source of truth that ships; the engine repo's
-- manifests/zephyr.lua is its test-fixture mirror (keep them in sync).

  [19]={ (function()
      local ENGINE_URL = "https://raw.githubusercontent.com/kiltev/public-tts-scripts/main/engine.lua?v=1"

      local MANIFEST_SRC = [==[
MANIFEST = {
  class = "Arctic Zephyr",
  objects = {
    {
      kind = "token",
      name = "Rimearc",
      offset = { 12, 1, -30 },
      respawnable = true,
      pool = true,
      token = {
        nickname = "Rimearc",
        image = "https://raw.githubusercontent.com/kiltev/zephyr/main/resources/icons/rimearc.png",
        tags = { "Has Action", "Has Aid Tokens", "Has Conditions", "Has Health", "Terrain" },
        scale = { 0.35, 0.6, 0.35 },
        thickness = 0.2, merge_distance = 15, stackable = false,
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
