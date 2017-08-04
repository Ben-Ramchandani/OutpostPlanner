ON_INIT = ON_INIT or {}

function ON_INIT_FUNCTION()
    if ON_INIT then
        for i, f in ipairs(ON_INIT) do
            f()
        end
    end
end

script.on_init(ON_INIT_FUNCTION)
script.on_configuration_changed(ON_INIT_FUNCTION)
