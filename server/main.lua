function ShowNotification(source, message, type, duration)
    TriggerClientEvent('sd_lib:client:showNotification', source, message, type, duration)
end

function GetFramework()
    local framework = Config.Framework
    
    if framework == 'auto' then
        if GetResourceState('qbx_core') == 'started' then
            return 'qbx'
        elseif GetResourceState('qb-core') == 'started' then
            return 'qb'
        elseif GetResourceState('es_extended') == 'started' then
            return 'esx'
        end
        return nil
    end
    
    return framework
end

function GetPlayerJob(source)
    local framework = GetFramework()
    local Player = nil
    
    if framework == 'qb' then
        Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local job = Player.PlayerData.job
            return {
                name = job.name,
                label = job.label,
                grade = job.grade.level,
                grade_name = job.grade.name,
                isBoss = job.isboss or job.grade.isboss
            }
        end
    elseif framework == 'qbx' then
        Player = exports.qbx_core:GetPlayer(source)
        if Player then
            local job = Player.PlayerData.job
            return {
                name = job.name,
                label = job.label,
                grade = job.grade.level,
                grade_name = job.grade.name,
                isBoss = job.isboss or job.grade.isboss
            }
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local job = xPlayer.job
            return {
                name = job.name,
                label = job.label,
                grade = job.grade,
                grade_name = job.grade_name,
                isBoss = job.grade_name == 'boss'
            }
        end
    end
    
    return nil
end

function GetJobEmployees(jobName)
    local framework = GetFramework()
    local employees = {}
    local onlineIds = {}

    if framework == 'qb' then
        local players = QBCore.Functions.GetPlayers()
        for _, player in ipairs(players) do
            local job = player.PlayerData.job
            if job.name == jobName then
                onlineIds[player.PlayerData.citizenid] = true
                table.insert(employees, {
                    id = player.PlayerData.source,
                    identifier = player.PlayerData.citizenid,
                    name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                    grade = job.grade.level,
                    grade_name = job.grade.name,
                    online = true
                })
            end
        end

        local offlinePlayers = MySQL.query.await('SELECT citizenid, charinfo, job FROM players WHERE job LIKE ?', { '%' .. jobName .. '%' })
        if offlinePlayers then
            for _, player in ipairs(offlinePlayers) do
                local jobData = json.decode(player.job or '{}')
                if jobData.name == jobName and not onlineIds[player.citizenid] then
                    local charinfo = json.decode(player.charinfo or '{}')
                    table.insert(employees, {
                        id = nil,
                        identifier = player.citizenid,
                        name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                        grade = jobData.grade or 0,
                        grade_name = jobData.grade_name or 'Unknown',
                        online = false
                    })
                end
            end
        end
    elseif framework == 'qbx' then
        local players = exports.qbx_core:GetQBPlayers()
        for _, playerId in ipairs(players) do
            local player = exports.qbx_core:GetPlayer(tonumber(playerId))
            if player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == jobName then
                onlineIds[player.PlayerData.citizenid] = true
                table.insert(employees, {
                    id = player.PlayerData.source,
                    identifier = player.PlayerData.citizenid,
                    name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                    grade = player.PlayerData.job.grade.level,
                    grade_name = player.PlayerData.job.grade.name,
                    online = true
                })
            end
        end

        local offlinePlayers = MySQL.query.await('SELECT citizenid, charinfo, job FROM players WHERE job LIKE ?', { '%' .. jobName .. '%' })
        if offlinePlayers then
            for _, player in ipairs(offlinePlayers) do
                local jobData = json.decode(player.job or '{}')
                if jobData.name == jobName and not onlineIds[player.citizenid] then
                    local charinfo = json.decode(player.charinfo or '{}')
                    table.insert(employees, {
                        id = nil,
                        identifier = player.citizenid,
                        name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                        grade = jobData.grade or 0,
                        grade_name = jobData.grade_name or 'Unknown',
                        online = false
                    })
                end
            end
        end
    elseif framework == 'esx' then
        local xPlayers = ESX.GetPlayers()
        for _, xPlayer in ipairs(xPlayers) do
            local job = xPlayer.job
            if job.name == jobName then
                onlineIds[xPlayer.identifier] = true
                table.insert(employees, {
                    id = xPlayer.source,
                    identifier = xPlayer.identifier,
                    name = xPlayer.getName(),
                    grade = job.grade,
                    grade_name = job.grade_name,
                    online = true
                })
            end
        end

        local offlinePlayers = MySQL.query.await('SELECT identifier, firstname, lastname, job, job_grade FROM users WHERE job = ?', { jobName })
        if offlinePlayers then
            for _, player in ipairs(offlinePlayers) do
                if not onlineIds[player.identifier] then
                    table.insert(employees, {
                        id = nil,
                        identifier = player.identifier,
                        name = player.firstname .. ' ' .. player.lastname,
                        grade = player.job_grade,
                        grade_name = tostring(player.job_grade),
                        online = false
                    })
                end
            end
        end
    end

    return employees
end

function GetJobGrades(jobName)
    local framework = GetFramework()
    local grades = {}
    
    if framework == 'qb' then
        local jobGrades = QBCore.Shared.Jobs[jobName]?.grades
        if jobGrades then
            for level, grade in pairs(jobGrades) do
                table.insert(grades, {
                    level = tonumber(level),
                    name = grade.name,
                    salary = grade.payment or 0
                })
            end
        end
    elseif framework == 'qbx' then
        local jobGrades = exports.qbx_core:GetJobs()[jobName]?.grades
        if jobGrades then
            for level, grade in pairs(jobGrades) do
                table.insert(grades, {
                    level = tonumber(level),
                    name = grade.name,
                    salary = grade.payment or 0
                })
            end
        end
    elseif framework == 'esx' then
        local jobGrades = ESX.GetJobGrades(jobName)
        if jobGrades then
            for grade, data in pairs(jobGrades) do
                table.insert(grades, {
                    level = tonumber(grade),
                    name = data.label or grade,
                    salary = data.salary or 0
                })
            end
        end
    end
    
    return grades
end

function GetJobSalaries(jobName)
    local framework = GetFramework()
    local salaries = {}
    
    if framework == 'qb' then
        local jobGrades = QBCore.Shared.Jobs[jobName]?.grades
        local jobLabel = QBCore.Shared.Jobs[jobName]?.label or jobName
        if jobGrades then
            for level, grade in pairs(jobGrades) do
                table.insert(salaries, {
                    name = jobLabel,
                    grade_name = grade.name,
                    grade_level = tonumber(level),
                    salary = grade.payment or 0
                })
            end
        end
    elseif framework == 'qbx' then
        local jobData = exports.qbx_core:GetJob(jobName)
        if jobData then
            local jobLabel = jobData.label or jobName
            local jobGrades = jobData.grades
            if jobGrades then
                for level, grade in pairs(jobGrades) do
                    table.insert(salaries, {
                        name = jobLabel,
                        grade_name = grade.name,
                        grade_level = tonumber(level),
                        salary = grade.payment or 0
                    })
                end
            end
        end
    elseif framework == 'esx' then
        local jobGrades = ESX.GetJobGrades(jobName)
        local jobLabel = ESX.GetJob(jobName)?.label or jobName
        if jobGrades then
            for grade, data in pairs(jobGrades) do
                table.insert(salaries, {
                    name = jobLabel,
                    grade_name = data.label or grade,
                    grade_level = tonumber(grade),
                    salary = data.salary or 0
                })
            end
        end
    end
    
    return salaries
end

function GetJobs()
    local framework = GetFramework()
    local jobs = {}

    if framework == 'qb' then
        jobs = QBCore.Shared.Jobs
    elseif framework == 'qbx' then
        jobs = exports.qbx_core:GetJobs()
    elseif framework == 'esx' then
        jobs = ESX.GetJobs()
    end

    return jobs
end

function GetPlayerIdentifier(source)
    local framework = GetFramework()

    if framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    elseif framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    elseif framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier
        end
    end

    return nil
end

exports('ShowNotification', ShowNotification)
exports('GetFramework', GetFramework)
exports('GetPlayerJob', GetPlayerJob)
exports('GetPlayerIdentifier', GetPlayerIdentifier)
exports('GetJobs', GetJobs)
exports('GetJobEmployees', GetJobEmployees)
exports('GetJobGrades', GetJobGrades)
exports('GetJobSalaries', GetJobSalaries)