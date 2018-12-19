util = util or {}

function table.contains(array, element)
    for k, e in pairs(array) do
        if e == element then
            return k
        end
    end
    return false
end

function table.array_clone(org)
    return {table.unpack(org)}
end

function table.clone(org)
    local copy = {}
    for k, v in pairs(org) do
        copy[k] = v
    end
    return copy
end

function table.array_concat(arrays)
    local new_array = {}
    for k, arr in ipairs(arrays) do
        for k2, elem in ipairs(arr) do
            table.insert(new_array, elem)
        end
    end
    return new_array
end

function table.deep_clone(org)
    if org then
        local copy = {}
        for k, v in pairs(org) do
            if type(v) == "table" then
                copy[k] = table.deep_clone(v)
            else
                copy[k] = v
            end
        end
        return copy
    else
        return org
    end
end

function table.deep_compare(t1, t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then
        return false
    end
    if ty1 ~= "table" then
        return t1 == t2
    end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not table.deep_compare(v1, v2) then
            return false
        end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not table.deep_compare(v1, v2) then
            return false
        end
    end
    return true
end

function util.dict_to_array(dict)
    local array = {}
    for k, v in pairs(dict) do
        table.insert(array, k)
    end
    return array
end

function math.clamp(x, a, b)
    if x < a then
        return a
    elseif x > b then
        return b
    else
        return x
    end
end

function table.combine(a, b)
    if not a then
        return b
    elseif not b then
        return a
    else
        for k, v in pairs(b) do
            a[k] = v
        end
    end
    return a
end

function table.array_combine(t1, t2)
    for i, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

function id(x)
    return x
end

util.id = id

function table.max_index(t, f)
    if not f then
        f = id
    end
    local current_max = -math.huge
    local max_index = nil
    for i, v in ipairs(t) do
        local val = f(v)
        if val > current_max then
            current_max = val
            max_index = i
        end
    end
    return max_index
end

function table.max(t, f)
    return t[table.max_index(t, f)]
end

function table.min_index(t, f)
    return table.max_index(
        t,
        function(x)
            return -f(x)
        end
    )
end

function table.min(t, f)
    return t[table.min_index(t, f)]
end

function table.map(t, func)
    local new_table = {}
    for i, v in ipairs(t) do
        table.insert(new_table, func(v))
    end
    return new_table
end

function table.apply(t, func)
    for k, v in pairs(t) do
        func(v)
    end
end

function table.all(t, func)
    for k, v in pairs(t) do
        if not func(v) then
            return false
        end
    end
    return true
end

function table.append_modify(t1, t2)
    for i, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

function table.find(t, func)
    if not t then
        return nil
    end
    for i, v in ipairs(t) do
        if func(v) then
            return i
        end
    end
    return nil
end

function table.remove_all(t, func)
    local i = 1
    while i <= #t do
        if func(t[i]) then
            table.remove(t, i)
        else
            i = i + 1
        end
    end
end

function table.filter_remove(t, func)
    local new_table = {}
    local i = 1
    while i <= #t do
        if func(t[i]) then
            table.insert(new_table, t[i])
            table.remove(t, i)
        else
            i = i + 1
        end
    end
    return new_table
end

function table.filter(t, func)
    local new_table = {}
    for k, v in ipairs(t) do
        if func(v) then
            table.insert(new_table, v)
        end
    end
    return new_table
end

function belt_to_splitter(belt)
    return string.gsub(belt, "(.*)transport%-belt", "%1splitter")
end

function splitter_to_belt(belt)
    return string.gsub(belt, "(.*)splitter", "%1transport-belt")
end

function underground_to_belt(underground)
    return string.gsub(underground, "(.*)underground%-belt", "%1transport-belt")
end

function belt_to_underground(belt)
    return string.gsub(belt, "(.*)transport%-belt", "%1underground-belt")
end

function pipe_to_underground(pipe)
    return pipe .. "-to-ground"
end

function util.rotate_box(box, direction)
    if direction == defines.direction.east then
        return {
            left_top = {x = -box.right_bottom.y, y = box.left_top.x},
            right_bottom = {x = -box.left_top.y, y = box.right_bottom.x}
        }
    elseif direction == defines.direction.south then
        return {
            left_top = {x = -box.right_bottom.x, y = -box.right_bottom.y},
            right_bottom = {x = -box.left_top.x, y = -box.left_top.y}
        }
    elseif direction == defines.direction.west then
        return {
            left_top = {x = box.left_top.y, y = -box.right_bottom.x},
            right_bottom = {x = box.right_bottom.y, y = -box.left_top.x}
        }
    else
        return box
    end
end

function util.rotate_position_origin(position, direction)
    direction = direction % 8
    if direction == 0 then
        return table.clone(position)
    elseif direction == 2 then
        return {
            x = -position.y,
            y = position.x
        }
    elseif direction == 4 then
        return {
            x = -position.x,
            y = -position.y
        }
    elseif direction == 6 then
        return {
            x = position.y,
            y = -position.x
        }
    else
        local theta = ((direction % 8) / 8) * 2 * math.pi
        return {
            x = position.x * math.cos(theta) - position.y * math.sin(theta),
            y = position.x * math.sin(theta) + position.y * math.cos(theta)
        }
    end
end

function util.rotate_position(position, direction, around_position)
    position = table.clone(position)
    position.x = position.x - around_position.x
    position.y = position.y - around_position.y
    util.rotate_position_origin(position, direction)
    position.x = position.x + around_position.x
    position.y = position.y + around_position.y
    return position
end

function util.rotate_entity(entity, direction)
    if entity.direction then
        entity.direction = (entity.direction + direction) % 8
    end
    if entity.pickup_position then
        entity.pickup_position = util.rotate_position_origin(entity.pickup_position, direction, entity.position)
    end
    if entity.drop_position then
        entity.drop_position = util.rotate_position_origin(entity.drop_position, direction, entity.position)
    end
    return entity
end

function util.find_blueprint_bounding_box(entities)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge

    for k, entity in pairs(entities) do
        local prototype = game.entity_prototypes[entity.name]
        if prototype.collision_box then
            local collision_box = util.rotate_box(prototype.collision_box, entity.direction)
            top = math.min(top, entity.position.y + collision_box.left_top.y)
            left = math.min(left, entity.position.x + collision_box.left_top.x)
            bottom = math.max(bottom, entity.position.y + collision_box.right_bottom.y)
            right = math.max(right, entity.position.x + collision_box.right_bottom.x)
        else
            top = math.min(top, entity.position.y)
            left = math.min(left, entity.position.x)
            bottom = math.max(bottom, entity.position.y)
            right = math.max(right, entity.position.x)
        end
    end
    return {left_top = {x = left, y = top}, right_bottom = {x = right, y = bottom}}
end

function util.shift_blueprint(entities, shift_x, shift_y)
    table.apply(
        entities,
        function(entity)
            entity.direction = entity.direction or 0
            entity.position.x = entity.position.x + shift_x
            entity.position.y = entity.position.y + shift_y
        end
    )
end

function util.find_blueprint_bounding_box_no_collision(entities)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge

    for k, entity in pairs(entities) do
        top = math.min(top, entity.position.y)
        left = math.min(left, entity.position.x)
        bottom = math.max(bottom, entity.position.y)
        right = math.max(right, entity.position.x)
    end
    return {left_top = {x = left, y = top}, right_bottom = {x = right, y = bottom}}
end

function util.find_collision_bounding_box(entities)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge

    for k, entity in pairs(entities) do
        if entity.valid then
            if entity.bounding_box then
                local collision_box = entity.bounding_box
                top = math.min(top, collision_box.left_top.y)
                left = math.min(left, collision_box.left_top.x)
                bottom = math.max(bottom, collision_box.right_bottom.y)
                right = math.max(right, collision_box.right_bottom.x)
            else
                top = math.min(top, entity.position.y)
                left = math.min(left, entity.position.x)
                bottom = math.max(bottom, entity.position.y)
                right = math.max(right, entity.position.x)
            end
        end
    end
    return {
        left_top = {x = math.floor(left), y = math.floor(top)},
        right_bottom = {x = math.ceil(right), y = math.ceil(bottom)}
    }
end

function util.find_bounding_box_positions(positions)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge

    for k, position in pairs(positions) do
        top = math.min(top, position.y)
        left = math.min(left, position.x)
        bottom = math.max(bottom, position.y)
        right = math.max(right, position.x)
    end
    return {
        left_top = {x = left, y = top},
        right_bottom = {x = right, y = bottom}
    }
end

function util.make_area(left, top, right, bottom)
    return {left_top = {x = left, y = top}, right_bottom = {x = right, y = bottom}}
end

function util.check_belt_entity(name)
    local prototype = game.entity_prototypes[name]
    if not prototype then
        return {"outpost-builder.bad-belt", name}
    else
        local belt_name
        if prototype.type == "transport-belt" then
            belt_name = name
        elseif prototype.type == "underground-belt" then
            belt_name = underground_to_belt(name)
        elseif prototype.type == "splitter" then
            belt_name = splitter_to_belt(name)
        end

        for k, v in ipairs(
            {
                {belt_name, "transport-belt"},
                {belt_to_underground(belt_name), "underground-belt"},
                {belt_to_splitter(belt_name), "splitter"}
            }
        ) do
            if not game.entity_prototypes[v[1]] or game.entity_prototypes[v[1]].type ~= v[2] then
                return {"outpost-builder.bad-belt", name}
            end
        end
    end
    return false
end

function util.add_box_position(box, position)
    return {
        left_top = {x = box.left_top.x + position.x, y = box.left_top.y + position.y},
        right_bottom = {x = box.right_bottom.x + position.x, y = box.right_bottom.y + position.y}
    }
end

function util.strip_entities_of_type(list, type)
    return table.filter_remove(
        list,
        function(entity)
            return game.entity_prototypes[entity.name].type == type
        end
    )
end

function util.strip_entities_of_name(list, name)
    return table.filter_remove(
        list,
        function(entity)
            return entity.name == name
        end
    )
end
