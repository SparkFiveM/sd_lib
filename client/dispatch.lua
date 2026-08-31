
local function GetDispatchSystem()
    local system = Config.Dispatch.System
    if system == 'auto' then
        if GetResourceState('sd_dispatch') ~= 'missing' then return 'sd_dispatch'
        elseif GetResourceState('ps-dispatch') ~= 'missing' then return 'ps-dispatch'
        elseif GetResourceState('cd_dispatch') ~= 'missing' then return 'cd_dispatch'
        elseif GetResourceState('core_dispatch') ~= 'missing' then return 'core_dispatch'
        elseif GetResourceState('wasabi_mdt') ~= 'missing' then return 'wasabi_mdt'
        elseif GetResourceState('rcore_dispatch') ~= 'missing' then return 'rcore_dispatch'
        elseif GetResourceState('redutzu-mdt') ~= 'missing' then return 'redutzu-mdt'
        elseif GetResourceState('l2s-dispatch') ~= 'missing' then return 'l2s-dispatch'
        elseif GetResourceState('dusa_dispatch') ~= 'missing' then return 'dusa_dispatch'
        elseif GetResourceState('lb-tablet') ~= 'missing' then return 'lb-tablet'
        elseif GetResourceState('origen_police') ~= 'missing' then return 'origen_police'
        end
    end
    return system
end

function Dispatch(coords, code, priority, content, jobs, title, info)
    local system = GetDispatchSystem()
    if not coords then return end
    
    if system == 'cd_dispatch' then
        if GetResourceState('cd_dispatch') ~= 'missing' then
            TriggerServerEvent('cd_dispatch:AddNotification', {
                job_table = jobs,
                coords = coords,
                title = code or '10-00',
                message = content or 'No details provided'
            })
        end

    elseif system == 'core_dispatch' then
         if GetResourceState('core_dispatch') ~= 'missing' then
             local isPriority = false
             if priority then isPriority = true end
             for _, job in pairs(jobs) do
                 exports['core_dispatch']:addCall(
                     code or '10-00',
                     content or 'No details provided',
                     { coords.x, coords.y, coords.z },
                     job,
                     240000,
                     isPriority or false
                 )
             end
         end

    elseif system == 'dusa_dispatch' then
        if GetResourceState('dusa_dispatch') ~= 'missing' then
            local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(street1)
            
            local prio = 0
            if priority == 'low' then prio = 0
            elseif priority == 'medium' then prio = 1
            elseif priority == 'high' then prio = 2
            end
            
            local dispatchData = {
                id = 0,
                event = 'ALERT RECEIVED',
                title = title or 'Alert',
                description = content or 'No details provided',
                code = code,
                codeName = 'spark_lib_alert',
                coords = coords,
                icon = 'suspect',
                priority = prio,
                street = street or '',
                recipientJobs = jobs,
            }
            exports.dusa_dispatch:CustomDispatch(dispatchData)
        end

    elseif system == 'l2s-dispatch' then
        if GetResourceState('l2s-dispatch') ~= 'missing' then
            local prio = 0
            if priority == 'low' then prio = 1
            elseif priority == 'medium' then prio = 2
            elseif priority == 'high' then prio = 3
            end
            
            local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(street1)
            
            TriggerServerEvent('l2s-dispatch:server:AddNotification', {
                departments = jobs,
                title = title or 'Alert',
                message = content or 'No details provided',
                coords = vec2(coords.x, coords.y),
                priority = prio,
                sound = 1,
                street = street or '',
                reply = GetPlayerServerId(PlayerId()), 
                anonymous = false,
            })
        end

    elseif system == 'lb-tablet' then
        if GetResourceState('lb-tablet') ~= 'missing' then
            local dispatchData = {}
            for _, job in pairs(jobs) do
                if job == 'police' or job == 'ambulance' then
                    dispatchData = {
                        priority = priority or 'medium',
                        code = code or '10-00',
                        title = title or 'Alert',
                        description = content or 'No details provided',
                        location = {
                            label = "Alert",
                            coords = { x = coords.x, y = coords.y }
                        },
                        time = 1000,
                        job = job,
                    }
                    exports["lb-tablet"]:AddDispatch(dispatchData)
                end
            end
        end

    elseif system == 'origen_police' then
        if GetResourceState('origen_police') ~= 'missing' then
            for _, job in pairs(jobs) do
                TriggerServerEvent("SendAlert:police", {
                    coords = coords,
                    title = title or 'Alert',
                    type = 'GENERAL',
                    message = content or 'No details provided',
                    job = job
                })
            end
        end

    elseif system == 'ps-dispatch' then
        if GetResourceState('ps-dispatch') ~= 'missing' then
            exports["ps-dispatch"]:CustomAlert({
                coords = coords,
                message = content or 'No details provided',
                dispatchCode = code or '10-00',
                priority = priority or 0
            })
        end

    elseif system == 'rcore_dispatch' then
        if GetResourceState('rcore_dispatch') ~= 'missing' then
            local alertData = {
                code = code or '10-00',
                default_priority = priority or 'medium',
                coords = coords,
                job = jobs,
                text = content or 'No details provided',
                type = 'alerts',
            }
            TriggerServerEvent('rcore_dispatch:server:sendAlert', alertData)
        end

    elseif system == 'redutzu-mdt' then
        if GetResourceState('redutzu-mdt') ~= 'missing' then
            local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(street1)
            TriggerServerEvent('redutzu-mdt:server:sendDispatchMessage', {
                code = code or 'driveby',
                coords = coords,
                street = street or '',
            })
        end

    elseif system == 'sd_dispatch' then
        if GetResourceState('sd_dispatch') ~= 'missing' then
            exports['sd_dispatch']:CreateAlert({
                coords = coords,
                code = code or '10-00',
                title = title or 'Alert',
                description = content or 'No details provided',
                info = info,
                job = jobs
            })
        end

    elseif system == 'wasabi_mdt' then
        if GetResourceState('wasabi_mdt') ~= 'missing' then
            local prio = 1
            if priority == "low" then prio = 1
            elseif priority == "medium" then prio = 2
            elseif priority == "high" then prio = 3
            end
            
            exports.wasabi_mdt:CreateDispatch({
                 type = 'disturbance',
                 title = code or '10-00',
                 description = content or 'No details provided',
                 coords = {x = coords.x, y = coords.y, z = coords.z},
                 priority = prio,
                 departments = jobs
            })
        end
    end
end

exports('Dispatch', Dispatch)
