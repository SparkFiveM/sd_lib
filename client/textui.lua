local Config = Config or {}

local isNativeActive = false

local function nativeTextUI(message)
    CreateThread(function()
        while isNativeActive do
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.35, 0.35)
            SetTextCentre(true)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0,0,0,0,255)
            SetTextEdge(1,0,0,0,255)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(message)
            EndTextCommandDisplayText(0.5, 0.9)
            Wait(0)
        end
    end)
end

local function GetTextUISystem()
    local system = Config.TextUI.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('esx_textui') ~= 'missing' then return 'esx'
        elseif GetResourceState('qb-core') ~= 'missing' then return 'qb-core'
        elseif GetResourceState('okokTextUI') ~= 'missing' then return 'okok'
        else return 'native' end
    end
    return system
end

function ShowTextUI(message, option, extra)
    local system = GetTextUISystem()
    
    if system == 'esx' then
        if GetResourceState('esx_textui') ~= 'missing' then
            exports['esx_textui']:TextUI(message, 'info')
        end
        
    elseif system == 'native' then
        if not isNativeActive then
            isNativeActive = true
            nativeTextUI(message)
        else
            isNativeActive = false
            Wait(10)
            isNativeActive = true
            nativeTextUI(message)
        end
        
    elseif system == 'okok' then
        if GetResourceState('okokTextUI') ~= 'missing' then
            local type = option
            local color = 'lightblue'
            if type == 'success' then color = 'lightgreen'
            elseif type == 'error' then color = 'lightred'
            elseif type == 'warning' then color = 'lightred'
            elseif type == 'info' then color = 'lightblue'
            end
            
            exports['okokTextUI']:Open('[E] ' .. message, color, 'center', false)
        end
        
    elseif system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.showTextUI then
            local position = extra or option or Config.TextUI.DefaultPosition
            if type(option) == 'string' and (option:find('top') or option:find('bottom') or option:find('center')) then
                position = option
            end
            
            lib.showTextUI(message, {
                position = position
            })
        end
        
    elseif system == 'qb-core' then
        if GetResourceState('qb-core') ~= 'missing' then
            local position = option or Config.TextUI.DefaultPosition
            exports['qb-core']:DrawText(message, position)
        end
    end
end

function HideTextUI()
    local system = GetTextUISystem()
    
    if system == 'esx' then
        if GetResourceState('esx_textui') ~= 'missing' then
            exports['esx_textui']:HideUI()
        end
        
    elseif system == 'native' then
        isNativeActive = false
        
    elseif system == 'okok' then
        if GetResourceState('okokTextUI') ~= 'missing' then
            exports['okokTextUI']:Close()
        end
        
    elseif system == 'ox_lib' then
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
        
    elseif system == 'qb-core' then
        if GetResourceState('qb-core') ~= 'missing' then
            exports['qb-core']:HideText()
        end
    end
end

exports('ShowTextUI', ShowTextUI)
exports('HideTextUI', HideTextUI)
