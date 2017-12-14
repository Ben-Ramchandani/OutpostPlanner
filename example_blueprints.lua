example_blueprints = {raw = {}}
example_blueprints.standard = {
    belts = {
        {
            direction = 2,
            entity_number = 4,
            name = "transport-belt",
            position = {
                x = 0.5,
                y = 4.5
            }
        },
        {
            direction = 2,
            entity_number = 5,
            name = "transport-belt",
            position = {
                x = 2.5,
                y = 4.5
            }
        },
        {
            direction = 2,
            entity_number = 6,
            name = "transport-belt",
            position = {
                x = 1.5,
                y = 4.5
            }
        }
    },
    fluid_dummies_left = {},
    fluid_dummies_right = {},
    height = 8,
    leaving_belts = {
        {
            direction = 2,
            entity_number = 5,
            name = "transport-belt",
            position = {
                x = 2.5,
                y = 4.5
            }
        }
    },
    leaving_underground_belts = {},
    miner_name = "electric-mining-drill",
    miners = {
        {
            direction = 4,
            entity_number = 3,
            name = "electric-mining-drill",
            position = {
                x = 1.5,
                y = 2.5
            }
        },
        {
            direction = 0,
            entity_number = 7,
            name = "electric-mining-drill",
            position = {
                x = 1.5,
                y = 6.5
            }
        }
    },
    other_entities = {},
    pipes = {},
    pole_name = "medium-electric-pole",
    poles = {
        {
            direction = 0,
            entity_number = 2,
            name = "medium-electric-pole",
            position = {
                x = 1.5,
                y = 0.5
            }
        },
        {
            direction = 0,
            entity_number = 8,
            name = "medium-electric-pole",
            position = {
                x = 1.5,
                y = 8.5
            }
        },
        {
            direction = 0,
            entity_number = 9,
            name = "medium-electric-pole",
            place_only_with_small_poles = true,
            position = {
                x = -0.5,
                y = 4.5
            }
        }
    },
    splitters = {},
    total_entities = 8,
    underground_belts = {},
    width = 3,
    supports_fluid = true
}

example_blueprints.raw.standard = {
    {
        entity_number = 1,
        name = "wooden-chest",
        position = {
            x = -1,
            y = -4
        }
    },
    {
        entity_number = 2,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = -4
        }
    },
    {
        direction = 4,
        entity_number = 3,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = -2
        }
    },
    {
        direction = 2,
        entity_number = 4,
        name = "transport-belt",
        position = {
            x = -1,
            y = 0
        }
    },
    {
        direction = 2,
        entity_number = 5,
        name = "transport-belt",
        position = {
            x = 1,
            y = 0
        }
    },
    {
        direction = 2,
        entity_number = 6,
        name = "transport-belt",
        position = {
            x = 0,
            y = 0
        }
    },
    {
        entity_number = 7,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = 2
        }
    },
    {
        entity_number = 8,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = 4
        }
    }
}

example_blueprints.raw.spread_out = {
    {
        entity_number = 1,
        name = "wooden-chest",
        position = {
            x = -2,
            y = -5
        }
    },
    {
        entity_number = 2,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = -5
        }
    },
    {
        direction = 4,
        entity_number = 3,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = -3
        }
    },
    {
        direction = 2,
        entity_number = 4,
        name = "transport-belt",
        position = {
            x = -2,
            y = -1
        }
    },
    {
        direction = 2,
        entity_number = 5,
        name = "transport-belt",
        position = {
            x = -1,
            y = -1
        }
    },
    {
        direction = 2,
        entity_number = 6,
        name = "transport-belt",
        position = {
            x = 1,
            y = -1
        }
    },
    {
        direction = 2,
        entity_number = 7,
        name = "transport-belt",
        position = {
            x = 0,
            y = -1
        }
    },
    {
        direction = 2,
        entity_number = 8,
        name = "transport-belt",
        position = {
            x = 2,
            y = -1
        }
    },
    {
        entity_number = 9,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = 1
        }
    },
    {
        entity_number = 10,
        name = "wooden-chest",
        position = {
            x = 2,
            y = 3
        }
    },
    {
        entity_number = 11,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = 4
        }
    }
}

example_blueprints.raw.compact = {
    {
        direction = 4,
        entity_number = 1,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = -2
        }
    },
    {
        entity_number = 2,
        name = "medium-electric-pole",
        position = {
            x = -1,
            y = 0
        }
    },
    {
        entity_number = 3,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = 2
        }
    },
    {
        direction = 2,
        entity_number = 4,
        name = "fast-underground-belt",
        position = {
            x = 1,
            y = 0
        },
        type = "input"
    },
    {
        direction = 2,
        entity_number = 5,
        name = "fast-underground-belt",
        position = {
            x = 0,
            y = 0
        },
        type = "output"
    }
}

example_blueprints.raw.robot = {
    {
        entity_number = 1,
        name = "wooden-chest",
        position = {
            x = -1,
            y = -4
        }
    },
    {
        entity_number = 2,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = -4
        }
    },
    {
        direction = 4,
        entity_number = 3,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = -2
        }
    },
    {
        entity_number = 4,
        name = "logistic-chest-passive-provider",
        position = {
            x = 0,
            y = 0
        }
    },
    {
        entity_number = 5,
        name = "electric-mining-drill",
        position = {
            x = 0,
            y = 2
        }
    },
    {
        entity_number = 6,
        name = "medium-electric-pole",
        position = {
            x = 0,
            y = 4
        }
    }
}
