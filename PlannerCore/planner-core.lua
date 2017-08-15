require("on_init")
require("on_load")

PlannerCore = {}
PlannerCore.stage_function_table = {}

-- Load stage functions
require("OB_stages")
require("PB_stages")
require("PB_opt_stages")

-- On tick functions
function PlannerCore.placement_tick(state)
    local namespace = state.stage_namespace
    local stage_name = state.stages[state.stage + 1]
    local stage_function = nil
    if type(stage_name) == "string" then
        stage_function = PlannerCore.stage_function_table[state.stage_namespace][stage_name]
    elseif type(stage_name) == "table" then
        stage_function = PlannerCore.stage_function_table[stage_name[1]][stage_name[2]]
    end
    if not stage_function then
        state.player.print(
            "PlannerCore Error: Bad stage name " ..
                serpent.block(stage_name) .. " in namespace " .. namespace .. ", aborting."
        )
        state.stage = 1000
        return
    end
    local res = stage_function(state)
    if res == true then
        state.stage = state.stage + 1
        state.count = 0
    elseif res then
        state.stage = res
        state.count = 0
    else
        state.count = state.count + 1
    end
end

function PlannerCore.check_state(state)
    if not state and state.stage and state.count and state.player and state.stages and state.stage_namespace then
        game.print("Missing basic property.")
        return false
    end

    if not PlannerCore.stage_function_table[state.stage_namespace] then
        game.print("Bad namespace")
        return false
    end

    for k, v in pairs(state.stages) do
        if type(v) == "string" then
            if not PlannerCore.stage_function_table[state.stage_namespace][v] then
                game.print("Stage not in namespace")
                return false
            end
        elseif type(v) == "table" then
            if not PlannerCore.stage_function_table[v[1]] or not PlannerCore.stage_function_table[v[1]][v[2]] then
                game.print("Bad table stage")
                return false
            end
        else
            game.print("Stage has invalid type")
            return false
        end
    end
    return true
end

function PlannerCore.register(state)
    if not PlannerCore.check_state(state) then
        game.print("PlannerCore Error: Attempt to register bad state, will be ignored:")
        game.print(serpent.block(state))
        return false
    end

    if not global.running_states then
        global.running_states = {state}
    else
        table.insert(global.running_states, state)
    end
    if #global.running_states == 1 then
        script.on_event(defines.events.on_tick, PlannerCore.on_tick)
    end
    return true
end

function PlannerCore.run_immediately(state)
    if not PlannerCore.check_state(state) then
        game.print("PlannerCore Error: Attempt to register bad state, will be ignored:")
        game.print(serpent.block(state))
        return false
    end

    while state.stage < #state.stages do
        PlannerCore.placement_tick(state)
    end
end

function PlannerCore.on_tick(event)
    if #global.running_states == 0 then
        script.on_event(defines.events.on_tick, nil)
    else
        -- Manually loop because we're removing items.
        local i = 1
        while i <= #global.running_states do
            local state = global.running_states[i]
            -- if event.tick % 60 == 0 then
            --     game.print("Handler running")
            --     game.print("In stage " .. state.stage)
            -- end
            if state.count > 10000 then
                game.print("PlannerCore Error: Count exceeds 10000, will abort.")
                game.print("Was in state " .. state.stage .. " (" .. state.stages[state.stage] .. ").")
                table.remove(global.running_states, i)
            else
                if state.stage < #state.stages then
                    PlannerCore.placement_tick(state)
                    i = i + 1
                else
                    table.remove(global.running_states, i)
                end
            end
        end
    end
end

function PlannerCore.on_load()
    if global.running_states and #global.running_states > 0 then
        script.on_event(defines.events.on_tick, PlannerCore.on_tick)
    end
end

table.insert(ON_LOAD, PlannerCore.on_load)

function PlannerCore.clear_running_state()
    global.running_states = {}
end

table.insert(ON_INIT, PlannerCore.clear_running_state)

-- Remote interfaces

remote.add_interface("PlannerCore", {register = PlannerCore.register, run_immediately = PlannerCore.run_immediately})

PlannerCore.remote_invoke = {}

require("PB_invoke")

remote.add_interface("PlannerCoreInvoke", PlannerCore.remote_invoke)
