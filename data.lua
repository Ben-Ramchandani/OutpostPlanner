
data:extend(
  {
    {
      type = "selection-tool",
      name = "outpost-builder",
      icon = "__OutpostPlanner__/graphics/outpost-builder.png",
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
    {
      type = "sprite",
      name = "miner-blueprint",
      filename = "__OutpostPlanner__/graphics/miner-blueprint.png",
      width = 32,
      height = 32
    }
  }
)

function table.deep_clone(org)
    local copy = {}
    for k, v in pairs(org) do
        if type(v) == "table" then
            copy[k] = table.deep_clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- data.raw["electric-pole"]["substation-2"] = table.deep_clone(data.raw["electric-pole"]["substation"])
-- data.raw["electric-pole"]["substation-2"].name = "substation-2"
-- --data.raw["electric-pole"]["substation-2"].order = "[logistics][b]"


-- data.raw["electric-pole"]["substation"].fast_replaceable_group = "substation"

-- data.raw["electric-pole"]["substation-2"].fast_replaceable_group = "substation"

-- data.raw["item"]["substation-2"] = table.deep_clone(data.raw["item"]["substation"])
-- data.raw["item"]["substation-2"].name = "substation-2"
-- data.raw["item"]["substation-2"].place_result = "substation-2"


-- data.raw["electric-pole"]["substation-2"].collision_box = {{-1.9, -1.9}, {1.9, 1.9}}
