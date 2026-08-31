
local function GetProgressSystem()
    local system = Config.Progress.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('InsaneScripts_hud') ~= 'missing' then return 'InsaneScripts_hud'
        elseif GetResourceState('qb-core') ~= 'missing' then return 'qb-core'
        elseif GetResourceState('progressbar') ~= 'missing' then return 'progressbar'
        else return 'native' end
    end
    return system
end

function ShowProgress(label, duration, callback)
    local system = GetProgressSystem()
    
    if system == 'InsaneScripts_hud' or system == 'insane' or system == 'insane_hud' then
        if GetResourceState('InsaneScripts_hud') ~= 'missing' then
            local data = {}
            if type(label) == 'table' then
                data = label
                callback = duration or callback
            else
                data = {
                    duration = duration,
                    label = label,
                    canCancel = false,
                    useWhileDead = false,
                    controlDisables = {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }
                }
            end
            exports['InsaneScripts_hud']:progressBar(data, function(completed)
                if completed and callback then callback() end
            end)
        end

    elseif system == 'native' then
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
                name = "spark_lib_progress",
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
                QBCore.Functions.Progressbar("spark_lib_progress", label, duration, false, false, {
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

function CancelProgress()
    local system = GetProgressSystem()
    if system == 'InsaneScripts_hud' or system == 'insane' or system == 'insane_hud' then
        if GetResourceState('InsaneScripts_hud') ~= 'missing' then
            exports['InsaneScripts_hud']:cancelProgressBar()
        end
    elseif system == 'ox_lib' then
        if lib and lib.cancelProgress then
            lib.cancelProgress()
        end
    end
end

exports('ShowProgress', ShowProgress)
exports('CancelProgress', CancelProgress)
