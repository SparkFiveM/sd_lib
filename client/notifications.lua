
local function GetNotificationSystem()
    local system = Config.Notification.System
    if system == 'auto' then
        if GetResourceState('sd_notify') ~= 'missing' then return 'sd_notify'
        elseif GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('mythic_notify') ~= 'missing' then return 'mythic_notify'
        elseif GetResourceState('okokNotify') ~= 'missing' then return 'okok'
        elseif GetResourceState('vms_notify') ~= 'missing' then return 'vms_notify'
        elseif GetResourceState('es_extended') ~= 'missing' then return 'esx'
        elseif GetResourceState('qb-core') ~= 'missing' then return 'qb-core'
        else return 'native' end
    end
    return system
end

function ShowNotification(message, type, duration)
    local system = GetNotificationSystem()
    
    if system == 'esx' then
        if GetResourceState('es_extended') ~= 'missing' then
            exports['es_extended']:showNotification(message)
        end
        
    elseif system == 'mythic_notify' then
        if GetResourceState('mythic_notify') ~= 'missing' then
            exports['mythic_notify']:DoHudText(type, message)
        end
        
    elseif system == 'native' then
        CreateThread(function()
            local startTime = GetGameTimer()
            local endTime = startTime + (duration or Config.Notification.DefaultDuration or 5000)
            local alpha = 255
            
            while GetGameTimer() < endTime do
                local timeLeft = endTime - GetGameTimer()
                if timeLeft < 1000 then
                    alpha = math.floor((timeLeft / 1000) * 255)
                end
                
                local color = {255, 255, 255}
                if type == 'error' then
                    color = {220, 38, 38}
                elseif type == 'success' then
                    color = {34, 197, 94}
                elseif type == 'warning' then
                    color = {251, 191, 36}
                elseif type == 'primary' then
                    color = {59, 130, 246}
                end
                
                DrawRect(0.5, 0.1, 0.4, 0.08, 0, 0, 0, math.min(alpha, 150))
                DrawRect(0.5, 0.1, 0.39, 0.07, color[1], color[2], color[3], math.min(alpha, 200))
                
                SetTextScale(0.4, 0.4)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, alpha)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(message)
                DrawText(0.5, 0.08)
                
                Wait(0)
            end
        end)
        
    elseif system == 'okok' then
        if GetResourceState('okokNotify') ~= 'missing' then
            local title = 'Notification'
            local time = duration or Config.Notification.DefaultDuration or 5000
            local notifyType = type or 'info'
            local playSound = true
            
            if notifyType == 'inform' then notifyType = 'info'
            elseif notifyType == 'warn' then notifyType = 'warning'
            end
            
            if notifyType == 'success' then title = 'Success'
            elseif notifyType == 'error' then title = 'Error'
            elseif notifyType == 'warning' then title = 'Warning'
            elseif notifyType == 'info' then title = 'Information'
            elseif notifyType == 'phonemessage' then title = 'Message'
            elseif notifyType == 'neutral' then title = 'Notice'
            end
            
            exports['okokNotify']:Alert(title, message, time, notifyType, playSound)
        end
        
    elseif system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.notify then
            lib.notify({
                title = message,
                type = type,
                duration = duration
            })
        end
        
    elseif system == 'qb-core' then
        if GetResourceState('qb-core') ~= 'missing' then
            exports['qb-core']:Notify(message, type, duration)
        end
        
    elseif system == 'sd_notify' then
        if GetResourceState('sd_notify') ~= 'missing' then
            exports['sd_notify']:Notify({
                title = "Notify",
                description = message,
                type = type or "info",
                duration = duration or 5000
            })
        end
        
    elseif system == 'vms_notify' then
        if GetResourceState('vms_notify') ~= 'missing' then
            local hexColor = '#1c75d2'
            if type == 'success' then hexColor = '#20bb44'
            elseif type == 'error' then hexColor = '#c10114'
            elseif type == 'info' then hexColor = '#1c75d2'
            end
            
            exports["vms_notify"]:Notification("Notify", message, duration, hexColor, "fa-solid fa-comment")
        end
    end
end

exports('ShowNotification', ShowNotification)
