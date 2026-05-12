
function TriggerCallback(name, cb, ...)
    local system = Config.Framework
    
    if system == 'auto' then
        if GetResourceState('qbx_core') == 'started' then system = 'qbx'
        elseif GetResourceState('qb-core') == 'started' then system = 'qb'
        elseif GetResourceState('es_extended') == 'started' then system = 'esx'
        end
    end
    
    if system == 'qb' then
        if QBCore then
            QBCore.Functions.TriggerCallback(name, cb, ...)
        end
    elseif system == 'qbx' then
        if lib then
            lib.callback(name, false, function(result)
                if cb then cb(result) end
            end, ...)
        end
    elseif system == 'esx' then
        if ESX then
            ESX.TriggerServerCallback(name, cb, ...)
        end
    end
end

exports('TriggerCallback', TriggerCallback)
