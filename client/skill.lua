local Config = Config or {}

local function GetSkillcheckSystem()
    local system = Config.Skillcheck.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('ps-ui') ~= 'missing' then return 'ps-ui/ps_lib'
        elseif GetResourceState('bl_ui') ~= 'missing' then return 'bl_ui'
        end
    end
    return system
end

function Skillcheck(difficulty, inputs, callback)
    local system = GetSkillcheckSystem()
    
    if system == 'bl_ui' then
        if GetResourceState('bl_ui') ~= 'missing' then
            exports['bl_ui']:CircleProgress(difficulty, inputs, function(success)
                if callback then callback(success) end
            end)
        end
        
    elseif system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.skillCheck then
            local success = lib.skillCheck(difficulty, inputs)
            if callback then callback(success) end
        end
        
    elseif system == 'ps-ui/ps_lib' then
        if GetResourceState('ps-ui') ~= 'missing' then
            exports['ps-ui']:Circle(function(success)
                if callback then callback(success) end
            end, difficulty, inputs)
        end
    end
end

exports('Skillcheck', Skillcheck)
