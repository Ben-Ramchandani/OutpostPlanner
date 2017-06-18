function contains(array, element)
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
