
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
        end
    end
end

if currentFramework == 'qbx' and lib then
    lib.callback.register('sd_lib:server:spawnVehicle', function(source, modelHash, coords, isNetworked)
        local spawnCoords = vector4(coords.x, coords.y, coords.z, coords.w or 0.0)
        local result = qbx.spawnVehicle({
            model = modelHash,
            spawnSource = spawnCoords,
            warp = false
        })
        if result then return result end
        return nil
    end)
end

function GetPlayer(source)
    if currentFramework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif currentFramework == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    elseif currentFramework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
    return source
end

function GetPlayerIdentifier(src)
    if currentFramework == 'qb' then
        return GetPlayerIdentifierByType(src, 'license') or nil
    elseif currentFramework == 'qbx' then
        return GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license') or nil
    elseif currentFramework == 'esx' then
        local xPlayer = GetPlayer(src)
        if xPlayer and xPlayer.identifier then return xPlayer.identifier end
        return GetPlayerIdentifierByType(src, 'license') or (GetPlayerIdentifiers(src)[1] or ('src:'..tostring(src)))
    end
    return GetPlayerIdentifierByType(src, 'license') or nil
end

function GetPlayerFullName(src)
    local player = GetPlayer(src)
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if player and player.PlayerData then
            local firstName = player.PlayerData.charinfo.firstname or ""
            local lastName = player.PlayerData.charinfo.lastname or ""
            return firstName .. " " .. lastName
        end
    elseif currentFramework == 'esx' then
        if player then
            return player.getName()
        end
    end
    
    local name = GetPlayerName(src)
    return name or 'Unknown'
end

function GetPlayerJobName(source)
    local player = GetPlayer(source)
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif currentFramework == 'esx' then
        if player then
            return player.job.name
        end
    end
    
    return 'unknown'
end

function GetFunds(Player)
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        return {
            cash = Player.PlayerData.money.cash,
            bank = Player.PlayerData.money.bank
        }
    elseif currentFramework == 'esx' then
        return {
            cash = Player.getAccount('money').money,
            bank = Player.getAccount('bank').money
        }
    end
    return {cash=0, bank=0}
end

function AddMoney(Player, Amount, Type, comment)
    if currentFramework == 'qb' then
        Player.Functions.AddMoney(Type, Amount, comment)
    elseif currentFramework == 'qbx' then
        local identifier = Player.PlayerData.license
        exports.qbx_core:AddMoney(identifier, Type, Amount, comment)
    elseif currentFramework == 'esx' then
        if Type == 'cash' then
            Player.addAccountMoney('money', Amount, comment)
        elseif Type == 'bank' then
            Player.addAccountMoney('bank', Amount, comment)
        end
    end
end

function RemoveMoney(Player, Amount, Type, comment)
    if currentFramework == 'qb' then
        local currentAmount = Player.Functions.GetMoney(Type)
        if currentAmount >= Amount then
            Player.Functions.RemoveMoney(Type, Amount, comment)
            return true
        end
    elseif currentFramework == 'qbx' then
        local identifier = Player.PlayerData.license
        local currentAmount = exports.qbx_core:GetMoney(identifier, Type)
        if currentAmount >= Amount then
            exports.qbx_core:RemoveMoney(identifier, Type, Amount, comment)
            return true
        end
    elseif currentFramework == 'esx' then
        if Type == 'cash' then
            local currentAmount = Player.getAccount('money').money
            if currentAmount >= Amount then
                Player.removeAccountMoney('money', Amount, comment)
                return true
            end
        elseif Type == 'bank' then
            local currentAmount = Player.getAccount('bank').money
            if currentAmount >= Amount then
                Player.removeAccountMoney('bank', Amount, comment)
                return true
            end
        end
    end
    return false
end

function GetJobGrades(jobName)
    if not jobName then return {} end
    
    if currentFramework == 'qb' then
        if QBCore and QBCore.Shared and QBCore.Shared.Jobs then
            local job = QBCore.Shared.Jobs[jobName]
            if job and job.grades then
                local grades = {}
                for gradeIndex, gradeData in pairs(job.grades) do
                    grades[gradeIndex] = {
                        index = gradeIndex,
                        label = gradeData.name,
                        salary = gradeData.payment,
                        isboss = gradeData.isboss or false
                    }
                end
                return grades
            end
        end
    elseif currentFramework == 'qbx' then
        local jobs = exports.qbx_core:GetJobs()
        if jobs then
            local job = jobs[jobName]
            if job and job.grades then
                local grades = {}
                for gradeIndex, gradeData in pairs(job.grades) do
                    grades[gradeIndex] = {
                        index = gradeIndex,
                        label = gradeData.name,
                        salary = gradeData.payment,
                        isboss = gradeData.isboss or false,
                        bankAuth = gradeData.bankAuth or false
                    }
                end
                return grades
            end
        end
    elseif currentFramework == 'esx' then
        if ESX then
            local jobs = ESX.GetJobs()
            if jobs[jobName] and jobs[jobName].grades then
                local grades = {}
                for gradeIndex, gradeData in pairs(jobs[jobName].grades) do
                    grades[tonumber(gradeIndex)] = {
                        index = tonumber(gradeIndex),
                        label = gradeData.label,
                        salary = gradeData.salary
                    }
                end
                return grades
            end
        end
    end
    
    return {}
end

function GetPlayerData(source)
    local player = GetPlayer(source)
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        if player then return player.PlayerData end
    elseif currentFramework == 'esx' then
        return player
    end
    return nil
end

function GetCharId(source)
    local pData = GetPlayerData(source)
    if not pData then return nil end
    
    if currentFramework == 'qb' or currentFramework == 'qbx' then
        return pData.citizenid
    elseif currentFramework == 'esx' then
        return pData.identifier
    end
    return nil
end

function GetPlayerFromIdentifier(identifier)
    if currentFramework == 'qb' then
        return QBCore.Functions.GetPlayerByLicense(identifier)
    elseif currentFramework == 'qbx' then
        return exports.qbx_core:GetPlayerByLicense(identifier)
    elseif currentFramework == 'esx' then
        return ESX.GetPlayerFromIdentifier(identifier)
    end
    return nil
end

function GetPlayers()
    if currentFramework == 'qb' then
        return QBCore.Functions.GetPlayers()
    elseif currentFramework == 'qbx' then
        return exports.qbx_core:GetQBPlayers()
    elseif currentFramework == 'esx' then
        return ESX.GetPlayers()
    end
    return {}
end

exports('GetPlayer', GetPlayer)
exports('GetPlayerIdentifier', GetPlayerIdentifier)
exports('GetPlayerFullName', GetPlayerFullName)
exports('GetPlayerJobName', GetPlayerJobName)
exports('GetFunds', GetFunds)
exports('AddMoney', AddMoney)
exports('RemoveMoney', RemoveMoney)
exports('GetJobGrades', GetJobGrades)
exports('GetPlayers', GetPlayers)
exports('GetPlayerFromIdentifier', GetPlayerFromIdentifier)
exports('GetPlayerData', GetPlayerData)
exports('GetCharId', GetCharId)
