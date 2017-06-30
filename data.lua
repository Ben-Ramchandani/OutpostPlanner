
data:extend(
  {
    {
      type = "selection-tool",
      name = "outpost-builder",
      icon = "__MinePlanner__/graphics/outpost-builder.png",
      flags = {"goes-to-quickbar"},
      selection_color = {r = 1.0, g = 0.55, b = 0.0, a = 0.2},
      alt_selection_color = {r = 1.0, g = 0.2, b = 0.0, a = 0.2},
      selection_mode = {"any-entity"},
      alt_selection_mode = {"any-entity"},
      selection_cursor_box_type = "not-allowed",
      alt_selection_cursor_box_type = "not-allowed",
      subgroup = "tool",
      order = "c[automated-construction]-d[outpost-builder]",
      stack_size = 1
    },
    {
        type = "recipe",
        name = "outpost-builder",
        enabled = true,
        energy_required = 0.1,
        category = "crafting",
        ingredients = {},
        result = "outpost-builder"
    },
  }
)
