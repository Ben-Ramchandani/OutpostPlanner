function config(new_conf) -- Override the configuration file on a per save basis.
    if not global.AM_CONF then
        global.AM_CONF = table.clone(AM_CONF)
    end
    if new_conf and type(new_conf) == "table" then
        for k, v in pairs(new_conf) do
            global.AM_CONF[k] = v
        end
    end
end

function reset_all()
    global.AM_CONF = table.clone(AM_CONF)
    global.AM_states = {}
end

remote.add_interface("OutpostBuilder", {config = config, reset = reset_all})