-- Dawnbringer content manifest (consumed by the generic spawn engine).
-- Reproduces today's items_script.lua behaviour purely as configuration.
return {
  -- class name is derived from the envelope; override only if it can't be inferred.
  class = "Dawnbringer",
  objects = {
    {
      kind = "item_deck",                 -- alias -> deck builder
      name = "Dawnbringer Items Deck",
      offset = { -1.5, 1.2, 10.5 },
      respawnable = false,
      deck = {
        face = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-front.png",
        back = "https://raw.githubusercontent.com/kiltev/Dawnbringer/main/items/items-back.png",
        width = 3,
        height = 3,
        number = 9,
        back_is_hidden = true,
        unique_back = true,
        sideways = false,
        rotation = { 0, 180, 0 },
        scale = { 0.9, 1, 0.9 },
      },
      pack = {
        button = {
          label = "Open Pack",
          width = 1400, height = 400, font_size = 220,
          color = { 0, 0, 0, 0.9 }, font_color = { 1, 1, 1, 1 },
          position = { 0, 0.5, 0 },
        },
        columns = 5,
        stepX = 2.5,
        stepZ = 3.5,
        names = {
          "Concussive Quarrel", "Corrosive Darts", "Silver Bolts",
          "Smoke Bomb", "Unstable Flask", "Jagged Caltrops",
          "Harpoon Tether", "Ancient Technology", "Mutagen Syringe",
        },
      },
    },
  },
}
