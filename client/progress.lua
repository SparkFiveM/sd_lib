
local function GetProgressSystem()
    local system = Config.Progress.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('qb-core') ~= 'missing' then return 'qb-core'
        elseif GetResourceState('progressbar') ~= 'missing' then return 'progressbar'
        else return 'native' end
    end
    return system
end

function ShowProgress(label, duration, callback)
    local system = GetProgressSystem()
    
    if system == 'native' then
        CreateThread(function()
            local startTime = GetGameTimer()
            while GetGameTimer() - startTime < duration do
                DrawRect(0.5, 0.9, 0.3, 0.05, 0, 0, 0, 150)
                DrawRect(0.5, 0.9, 0.29 * ((GetGameTimer() - startTime) / duration), 0.04, 255, 255, 255, 255)
                
                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(label)
                DrawText(0.5, 0.87)
                
                Wait(0)
            end
            
            if callback then callback() end
        end)
        
    elseif system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.progressBar then
            local success = lib.progressBar({
                duration = duration,
                label = label,
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                }
            })
            if success and callback then callback() end
        end
        
    elseif system == 'progressbar' then
        if GetResourceState('progressbar') ~= 'missing' then
            exports['progressbar']:Progress({
                name = "sd_lib_progress",
                duration = duration,
                label = label,
                useWhileDead = false,
                canCancel = false,
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(cancelled)
                if not cancelled and callback then callback() end
            end)
        end
        
    elseif system == 'qb-core' then
        if GetResourceState('qb-core') ~= 'missing' then
            if QBCore then
                QBCore.Functions.Progressbar("sd_lib_progress", label, duration, false, false, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    if callback then callback() end
                end)
            end
        end
    end
end

exports('ShowProgress', ShowProgress)
