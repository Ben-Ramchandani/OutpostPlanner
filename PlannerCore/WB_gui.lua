WB_GUI = {}

function WB_GUI.add_button(gui)
    gui.add({type = "button", name = "WallBuilderBlueprintRead", caption = "WB", style = "blueprint_button_style"})
end

local function find_wall(entities, bounding_box)
    local wall_positions = {}
    local wall_name = nil
    for i, entity in pairs(entities) do
        if game.entity_prototypes[entity.name].type == "wall" then
            wall_positions[entity.position.x] = wall_positions[entity.position.x] or {}
            wall_positions[entity.position.x][entity.position.y] = true
            wall_name = entity.name
        end
    end
    if not wall_name then
        return 0, 0, nil
    end

    local wall_outer_row = nil
    local wall_thickness = 0
    for y = bounding_box.left_top.y, math.floor(bounding_box.right_bottom.y) do
        local is_wall = true
        for x = bounding_box.left_top.x, bounding_box.right_bottom.x do
            if not wall_positions[x] or not wall_positions[x][y] then
                is_wall = false
                break
            end
        end

        if is_wall then
            wall_outer_row = wall_outer_row or y
            wall_thickness = wall_thickness + 1
        elseif wall_thickness > 0 then
            break
        end
    end

    return wall_thickness, wall_outer_row, wall_name
end

local function read_section(entities, conf)
    local entities = table.deep_clone(entities)
    local bounding_box = util.find_blueprint_bounding_box_no_collision(entities)
    local wall_thickness, wall_outer_row, wall_name = find_wall(entities, bounding_box)
    bounding_box = util.find_blueprint_bounding_box(entities)
    local shift_x = math.ceil((-bounding_box.left_top.x) - 0.5) + 0.5
    local shift_y = math.ceil((-bounding_box.left_top.y) - 0.5) + 0.5
    util.strip_entities_of_name(entities, conf.dummy_spacing_entitiy)
    util.shift_blueprint(entities, shift_x, shift_y)

    if wall_outer_row then
        wall_outer_row = math.floor(wall_outer_row + shift_y)
    else
        wall_outer_row = 0
    end
    local width = math.ceil(bounding_box.right_bottom.x - bounding_box.left_top.x)
    local height = math.ceil(bounding_box.right_bottom.y - bounding_box.left_top.y)

    -- TODO: Check if there are power poles

    return {
        wall_thickness = wall_thickness,
        wall_outer_row = wall_outer_row,
        entities = entities,
        width = width,
        height = height,
        wall_name = wall_name,
        pole = nil
    }
end


-- TODO this is broken
local function generate_corner(section_data)
    local corner_entities = {}
    local size = section_data.height - 1
    for depth = 0, section_data.wall_thickness do
        for x = (depth + 0), size do
            table.insert(
                corner_entities,
                {
                    entity_number = x + 1,
                    name = section_data.wall_name,
                    position = {
                        x = x + 0.5,
                        y = depth + section_data.wall_outer_row + 0.5
                    }
                }
            )
        end
        for y = (depth + 1), size do
            table.insert(
                corner_entities,
                {
                    entity_number = section_data.height + y,
                    name = section_data.wall_name,
                    position = {
                        x = depth + section_data.wall_outer_row + 0.5,
                        y = y + 0.5
                    }
                }
            )
        end
    end
    if section_data.pole then
    -- TODO put pole in corner
    end
    return corner_entities
end

local function read_blueprint(item, conf, player)
    local section_data = read_section(item.get_blueprint_entities(), conf)
    local corner_entities = generate_corner(section_data)
    local crossing_entities
    if section_data.wall_thickness > 0 then
        crossing_entities = table.deep_clone(WB_CONF_DEFAULT.crossing_entities)
        table.apply(
            crossing_entities,
            function(e)
                e.position.y = e.position.y + section_data.wall_outer_row
            end
        )
    else
        crossing_entities = {}
    end

    -- TODO Set up filler blueprint, called filler_entities

    local new_config = {
        section_entities = section_data.entities,
        corner_entities = corner_entities,
        crossing_entities = crossing_entities,
        crossing_width = 2,
        wall_thickness = section_data.wall_thickness,
        wall_outer_row = section_data.wall_outer_row,
        section_width = section_data.width,
        section_height = section_data.height,
        wall_name = section_data.wall_name,
        pole = section_data.pole
    }

    --game.write_file("wall_conf.lua", serpent.block(new_config))

    return new_config
end

function WB_GUI.on_button_press(event, conf)
    local player = game.players[event.element.player_index]
    local item_stack = player.cursor_stack
    if
        item_stack and item_stack.valid and item_stack.valid_for_read and item_stack.name == "blueprint" and
            item_stack.is_blueprint_setup()
     then
        return read_blueprint(item_stack, conf, player)
    end
end

PlannerCore.remote_invoke.WB_on_button_press = WB_GUI.on_button_press

