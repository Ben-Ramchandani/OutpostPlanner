l = {}

l.LEVEL_DEBUG = 0
l.LEVEL_INFO = 1
l.LEVEL_WARN = 2
l.LEVEL_ERROR = 3

l.printLevel = l.LEVEL_WARN
l.logLevel = l.LEVEL_INFO

function l.print_at_level(str, level)
    if (l.printLevel <= level) then
        game.print("[OutpostPlanner] " .. str)
    end
end

function l.log_at_level(str, level)
    if (l.printLevel <= level) then
        log(str)
    end
end

function l.out_at_level(str, level)
    l.print_at_level(str, level)
    l.log_at_level(str, level)
end

function l.debug(str)
    l.out_at_level("Debug: " .. str, l.LEVEL_DEBUG)
end

function l.info(str)
    l.out_at_level("Info: " .. str, l.LEVEL_INFO)
end

function l.warn(str)
    l.out_at_level("Warn: " .. str, l.LEVEL_WARN)
end
    
function l.error(str)
    l.out_at_level("Error: " .. str, l.LEVEL_ERROR)
end
