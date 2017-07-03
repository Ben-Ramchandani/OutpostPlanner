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

function belt_to_splitter(belt)
    return string.gsub(belt, "(.*)transport%-belt", "%1splitter")
end

function pipe_to_underground(pipe)
    return pipe .. "-to-ground"
end
