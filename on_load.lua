ON_LOAD = ON_LOAD or {}

function ON_LOAD_FUNCTION()
    if ON_LOAD then
        for i, f in ipairs(ON_LOAD) do
            f()
        end
    end
end

script.on_load(ON_LOAD_FUNCTION)

