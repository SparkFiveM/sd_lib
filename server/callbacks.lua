
local RegisteredCallbacks = {}

function RegisterCallback(name, cb)
    if RegisteredCallbacks[name] then return end
    RegisteredCallbacks[name] = true
    
    local system = Config.Framework
    
    if system == 'auto' then
        if GetResourceState('qbx_core') == 'started' then system = 'qbx'
        elseif GetResourceState('qb-core') == 'started' then system = 'qb'
        elseif GetResourceState('es_extended') == 'started' then system = 'esx'
        end
    end
    
    if system == 'qb' then
        if QBCore then
            QBCore.Functions.CreateCallback(name, cb)
        end
    elseif system == 'qbx' then
        if lib then
            lib.callback.register(name, cb)
        end
    elseif system == 'esx' then
        if ESX then
            ESX.RegisterServerCallback(name, cb)
        end
    end
end

exports('RegisterCallback', RegisterCallback)
