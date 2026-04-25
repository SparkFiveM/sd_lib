if GetResourceState('qbx_core') == 'started' then
    local import = LoadResourceFile('qbx_core', 'modules/playerdata.lua')
    local chunk = assert(load(import, '@@qbx_core/modules/playerdata.lua'))
    chunk()
end

if GetResourceState('PolyZone') == 'started' then
    local files = {
        'client.lua',
        'BoxZone.lua',
        'CircleZone.lua',
        'EntityZone.lua',
        'ComboZone.lua'
    }
    for _, file in ipairs(files) do
        local code = LoadResourceFile('PolyZone', file)
        local chunk = assert(load(code, '@@PolyZone/' .. file))
        chunk()
    end
end

function GetJobUpdateEvents()
    local events = {}

    if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        table.insert(events, 'QBCore:Client:OnJobUpdate')
    end

    if GetResourceState('es_extended') == 'started' then
        table.insert(events, 'esx:setJob')
    end

    return events
end

function GetPlayerLoadedEvents()
    local events = {}

    if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        table.insert(events, 'QBCore:Client:OnPlayerLoaded')
    end

    if GetResourceState('es_extended') == 'started' then
        table.insert(events, 'esx:playerLoaded')
    end

    return events
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
        return 'custom'
    end
    
    return framework
end

RegisterNetEvent('sd_lib:client:showNotification', function(message, type, duration)
    ShowNotification(message, type, duration)
end)

exports('GetJobUpdateEvents', GetJobUpdateEvents)
exports('GetPlayerLoadedEvents', GetPlayerLoadedEvents)
exports('GetFramework', GetFramework)