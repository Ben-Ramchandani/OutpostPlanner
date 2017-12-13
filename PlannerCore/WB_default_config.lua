WB_CONF_DEFAULT = {
    dummy_spacing_entitiy = "wooden-chest",
    iterations_per_tick = 100,
    water_tiles = {"water", "deepwater", "water-green", "deepwater-green", "out-of-map"},
    clearance_tiles = 1,
    run_over_multiple_ticks = true,
    pole = nil,
    corner_entities = {
        {
            entity_number = 1,
            name = "stone-wall",
            position = {
                x = 0.5,
                y = 0.5
            }
        },
        {
            entity_number = 2,
            name = "stone-wall",
            position = {
                x = 1.5,
                y = 0.5
            }
        },
        {
            entity_number = 3,
            name = "stone-wall",
            position = {
                x = 2.5,
                y = 0.5
            }
        },
        {
            entity_number = 4,
            name = "stone-wall",
            position = {
                x = 0.5,
                y = 1.5
            }
        },
        {
            entity_number = 5,
            name = "stone-wall",
            position = {
                x = 0.5,
                y = 2.5
            }
        }
    },
    crossing_entities = {
        {
            entity_number = 1,
            name = "gate",
            position = {
                x = 0.5,
                y = 0.5
            },
            direction = 2
        },
        {
            entity_number = 2,
            name = "gate",
            position = {
                x = 1.5,
                y = 0.5
            },
            direction = 2
        }
    },
    crossing_width = 2,
    section_entities = {
        {
            direction = 0,
            entity_number = 1,
            name = "stone-wall",
            position = {
                x = 0.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 2,
            name = "stone-wall",
            position = {
                x = 2.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 3,
            name = "stone-wall",
            position = {
                x = 1.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 4,
            name = "gun-turret",
            position = {
                x = 4,
                y = 2
            }
        },
        {
            direction = 0,
            entity_number = 5,
            name = "stone-wall",
            position = {
                x = 4.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 6,
            name = "stone-wall",
            position = {
                x = 3.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 7,
            name = "stone-wall",
            position = {
                x = 6.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 8,
            name = "stone-wall",
            position = {
                x = 5.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 9,
            name = "stone-wall",
            position = {
                x = 7.5,
                y = 0.5
            }
        }
    },
    filler_entities = {
        {
            direction = 0,
            entity_number = 1,
            name = "stone-wall",
            position = {
                x = 0.5,
                y = 0.5
            }
        }
    },
    section_height = 3,
    section_width = 8,
    corner_width = 3,
    filler_width = 1, -- Include in generation TODO
    wall_name = "stone-wall",
    wall_outer_row = 0,
    wall_thickness = 1
}

PlannerCore.remote_invoke.WB_default_config = function()
    return WB_CONF_DEFAULT
end
