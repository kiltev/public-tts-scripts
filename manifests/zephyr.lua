-- Arctic Zephyr content manifest (consumed by the generic spawn engine).
-- Reproduces today's rimearc_spawner.lua behaviour purely as configuration.
return {
  class = "Arctic Zephyr",
  objects = {
    {
      kind = "token",                     -- alias -> token builder
      name = "Rimearc",                   -- Infinite_Bag (pool) name
      offset = { 12, 1, -30 },
      respawnable = true,                 -- rebuild on envelope onObjectLeaveContainer
      pool = true,                        -- wrap the token in an Infinite_Bag
      token = {
        nickname = "Rimearc",
        image = "https://raw.githubusercontent.com/kiltev/zephyr/main/resources/icons/rimearc.png",
        tags = { "Has Action", "Has Aid Tokens", "Has Conditions", "Has Health", "Terrain" },
        scale = { 0.35, 0.6, 0.35 },
        thickness = 0.2,
        merge_distance = 15,
        stackable = false,
      },
    },
  },
}
