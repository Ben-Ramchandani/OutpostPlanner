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

function dict_to_array(dict)
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

function id(x)
    return x
end

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

function belt_to_splitter(belt)
    return string.gsub(belt, "(.*)transport%-belt", "%1splitter")
end

function underground_to_belt(underground)
    return string.gsub(underground, "(.*)underground%-belt", "%1transport-belt")
end

function pipe_to_underground(pipe)
    return pipe .. "-to-ground"
end

function rotate_box(box, direction)
    if direction == defines.direction.east then
        return {left_top = {x = - box.right_bottom.y, y = box.left_top.x}, right_bottom = {x = - box.left_top.y, y = box.right_bottom.x}}
    elseif direction == defines.direction.south then
        return {left_top = {x = - box.right_bottom.x, y = - box.right_bottom.y}, right_bottom = {x = - box.left_top.x, y = - box.left_top.y}}
    elseif direction == defines.direction.west then
        return {left_top = {x = box.left_top.y, y = - box.right_bottom.x}, right_bottom = {x = box.right_bottom.y, y = - box.left_top.x}}
    else
        return box
    end
end

function find_blueprint_bounding_box(entities)
    local top = math.huge
    local left = math.huge
    local right = -math.huge
    local bottom = -math.huge
    
    for k, entity in pairs(entities) do
        local prototype = game.entity_prototypes[entity.name]
        if prototype.collision_box then
            local collision_box = rotate_box(prototype.collision_box, entity.direction)
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

function find_leaving_belt(entities, width)
    for k, entity in pairs(entities) do
        if game.entity_prototypes[entity.name].type == "transport-belt" then
            if entity.direction == defines.direction.east and entity.position.x > width - 1 then
                return entity
            end
        end
    end
    for k, entity in pairs(entities) do
        if game.entity_prototypes[entity.name].type == "underground-belt" then
            if entity.direction == defines.direction.east and entity.type == "input" then
                return entity
            end
        end
    end
    return nil
end

