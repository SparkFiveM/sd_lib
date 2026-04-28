
local currentFramework = Config.Framework

if currentFramework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then
        currentFramework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        currentFramework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        currentFramework = 'esx'
    else
        currentFramework = 'custom'
    end
end

if currentFramework == 'qb' then
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
elseif currentFramework == 'esx' then
    if GetResourceState('es_extended') == 'started' then
        if exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            
            CreateThread(function()
                while ESX == nil do
                    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                    Wait(0)
                end
            end)
        end
    end
end

function GetPlayerData()
    if currentFramework == 'qb' then
        return QBCore.Functions.GetPlayerData()
    elseif currentFramework == 'qbx' then
        return QBX.PlayerData
    elseif currentFramework == 'esx' then
        return ESX.GetPlayerData()
    end
    return {}
end

function GetPlayerFullName()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata and pdata.charinfo then
            local firstname = pdata.charinfo.firstname or ''
            local lastname = pdata.charinfo.lastname or ''
            return firstname .. ' ' .. lastname
        end
    elseif currentFramework == 'esx' then
        if pdata and pdata.firstName and pdata.lastName then
            return pdata.firstName .. ' ' .. pdata.lastName
        elseif pdata and pdata.name then
            return pdata.name
        end
    end
    
    local playerName = GetPlayerName(-1)
    return playerName or 'Unknown'
end

function GetPlayerJobName()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata and pdata.job then
            return pdata.job.name or 'unemployed'
        end
    elseif currentFramework == 'esx' then
        if pdata and pdata.job then
            return pdata.job.name or 'unemployed'
        end
    end
    
    return 'unemployed'
end

function GetFunds()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        return {
            cash = pdata.money.cash,
            bank = pdata.money.bank
        }
    elseif currentFramework == 'esx' then
        return {
            cash = pdata.money,
            bank = pdata.accounts and pdata.accounts[2] and pdata.accounts[2].money or 0
        }
    end
    
    return {}
end

function GetPlayerName()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata and pdata.charinfo then
            local firstname = pdata.charinfo.firstname or ''
            local lastname = pdata.charinfo.lastname or ''
            return firstname .. " " .. lastname
        end
    elseif currentFramework == 'esx' then
        if pdata and pdata.firstName and pdata.lastName then
            return pdata.firstName .. " " .. pdata.lastName
        end
    end
    
    return "Unknown"
end

function GetPlayerJobGrade()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata and pdata.job and pdata.job.grade and pdata.job.grade.name then
            return pdata.job.grade.name
        end
    elseif currentFramework == 'esx' then
        if pdata and pdata.job and pdata.job.grade_label then
            return pdata.job.grade_label
        end
    end
    
    return 'Unknown'
end

function GetPlayerStats()
    local stats = {}
    local pdata = GetPlayerData()

    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata then
            stats.hunger = pdata.metadata.hunger
            stats.thirst = pdata.metadata.thirst
        end
        return stats
    elseif currentFramework == 'esx' then
        local hungerDone, thirstDone = false, false

        TriggerEvent("esx_status:getStatus", 'hunger', function(status)
            stats.hunger = status.val
            hungerDone = true
        end)

        TriggerEvent("esx_status:getStatus", 'thirst', function(status)
            stats.thirst = status.val
            thirstDone = true
        end)

        while not (hungerDone and thirstDone) do
            Wait(0)
        end
        return stats
    end
    
    return stats
end

function SpawnVehicle(model, cb, coords, isNetworked)
    if currentFramework == 'qb' then
        QBCore.Functions.SpawnVehicle(model, function(veh)
            if cb then cb(veh) end
        end, coords, isNetworked)
        return
    elseif currentFramework == 'esx' then
        local spawnCoords = vector3(coords.x, coords.y, coords.z)
        local heading = coords.w or 0.0
        ESX.Game.SpawnVehicle(model, spawnCoords, heading, function(veh)
            if cb then cb(veh) end
        end, isNetworked ~= false)
        return
    elseif currentFramework == 'qbx' then
        if lib then
            local modelHash = type(model) == 'string' and joaat(model) or model
            lib.callback('sd_lib:server:spawnVehicle', false, function(netId)
                if netId then
                    local timeout = 0
                    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout < 100 do
                        Wait(10)
                        timeout = timeout + 1
                    end
                    if NetworkDoesEntityExistWithNetworkId(netId) then
                        local veh = NetToVeh(netId)
                        if cb then cb(veh) end
                    end
                end
            end, modelHash, coords, isNetworked ~= false)
            return
        else
            print('[sd_lib] ox_lib is required for QBX vehicle spawning')
        end
    end

    local modelHash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(modelHash) then return end
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w or 0.0, isNetworked or true, false)
    SetModelAsNoLongerNeeded(modelHash)
    if cb then cb(veh) end
end

function SetVehicleProperties(vehicle, props)
    if currentFramework == 'qb' then
        return QBCore.Functions.SetVehicleProperties(vehicle, props)
    elseif currentFramework == 'esx' then
        return ESX.Game.SetVehicleProperties(vehicle, props)
    elseif currentFramework == 'qbx' then
        if lib then return lib.setVehicleProperties(vehicle, props) end
    else
        if lib then return lib.setVehicleProperties(vehicle, props) end
    end
    return false
end

function GetVehicleProperties(vehicle)
    if currentFramework == 'qb' then
        return QBCore.Functions.GetVehicleProperties(vehicle)
    elseif currentFramework == 'esx' then
        return ESX.Game.GetVehicleProperties(vehicle)
    elseif currentFramework == 'qbx' then
        if lib then return lib.getVehicleProperties(vehicle) end
    else
        if lib then return lib.getVehicleProperties(vehicle) end
    end
    return {}
end

function GetCharId()
    local pData = GetPlayerData()
    if not pData then return nil end
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        return pData.citizenid
    elseif currentFramework == 'esx' then
        return pData.identifier
    end
    return nil
end

function GetPlayerJob()
    local pdata = GetPlayerData()
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if pdata and pdata.job then
            return {
                name = pdata.job.name,
                label = pdata.job.label,
                grade = pdata.job.grade.level,
                grade_name = pdata.job.grade.name,
                isBoss = pdata.job.isboss or pdata.job.grade.isboss
            }
        end
    elseif currentFramework == 'esx' then
        if pdata and pdata.job then
            return {
                name = pdata.job.name,
                label = pdata.job.label,
                grade = pdata.job.grade,
                grade_name = pdata.job.grade_name,
                isBoss = pdata.job.grade_name == 'boss'
            }
        end
    end
    
    return nil
end

exports('GetPlayerData', GetPlayerData)
exports('GetPlayerFullName', GetPlayerFullName)
exports('GetPlayerJobName', GetPlayerJobName)
exports('GetFunds', GetFunds)
exports('GetPlayerName', GetPlayerName)
exports('GetPlayerJobGrade', GetPlayerJobGrade)
exports('GetPlayerStats', GetPlayerStats)
exports('SpawnVehicle', SpawnVehicle)
exports('SetVehicleProperties', SetVehicleProperties)
exports('GetVehicleProperties', GetVehicleProperties)
exports('GetCharId', GetCharId)
exports('GetPlayerJob', GetPlayerJob)
