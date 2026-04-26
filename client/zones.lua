local Config = Config or {}
local resourceZones = {}

local function GetZonesSystem()
    local system = Config.Zones.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('PolyZone') ~= 'missing' then return 'polyzone'
        end
    end
    return system
end

function CreatePolyZone(data)
    local system = GetZonesSystem()
    local resourceName = GetCurrentResourceName()

    local zone = nil

    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            zone = lib.zones.poly({
                points = data.points,
                thickness = data.thickness or 2.0,
                debug = data.debug or false,
                onEnter = data.onEnter,
                onExit = data.onExit,
                inside = data.inside
            })
        end

    elseif system == 'polyzone' then
        if GetResourceState('PolyZone') ~= 'missing' then
            zone = PolyZone:Create(data.points, {
                name = data.name,
                debugPoly = data.debug or false,
                minZ = data.minZ,
                maxZ = data.maxZ
            })

            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
        end
    end

    if zone then
        if not resourceZones[resourceName] then
            resourceZones[resourceName] = {}
        end
        table.insert(resourceZones[resourceName], {zone = zone, system = system})
    end

    return zone
end

function CreateBoxZone(data)
    local system = GetZonesSystem()
    local resourceName = GetCurrentResourceName()

    local zone = nil

    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            zone = lib.zones.box({
                coords = data.coords,
                size = data.size,
                rotation = data.rotation,
                debug = data.debug or false,
                onEnter = data.onEnter,
                onExit = data.onExit,
                inside = data.inside
            })
        end

    elseif system == 'polyzone' then
        if GetResourceState('PolyZone') ~= 'missing' then
            zone = BoxZone:Create(data.coords, data.size.y, data.size.x, {
                name = data.name,
                heading = data.rotation,
                debugPoly = data.debug or false,
                minZ = data.minZ,
                maxZ = data.maxZ
            })

            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
        end
    end

    if zone then
        if not resourceZones[resourceName] then
            resourceZones[resourceName] = {}
        end
        table.insert(resourceZones[resourceName], {zone = zone, system = system})
    end

    return zone
end

function CreateSphereZone(data)
    local system = GetZonesSystem()
    local resourceName = GetCurrentResourceName()

    local zone = nil

    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            zone = lib.zones.sphere({
                coords = data.coords,
                radius = data.radius,
                debug = data.debug or false,
                onEnter = data.onEnter,
                onExit = data.onExit,
                inside = data.inside
            })
        end

    elseif system == 'polyzone' then
        if GetResourceState('PolyZone') ~= 'missing' then
            zone = CircleZone:Create(data.coords, data.radius, {
                name = data.name,
                debugPoly = data.debug or false,
                useZ = true
            })

            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
        end
    end

    if zone then
        if not resourceZones[resourceName] then
            resourceZones[resourceName] = {}
        end
        table.insert(resourceZones[resourceName], {zone = zone, system = system})
    end

    return zone
end

function DeleteZone(zone)
    local system = GetZonesSystem()

    if system == 'ox_lib' then
        if zone and zone.remove then zone:remove() end
    elseif system == 'polyzone' then
        if zone and zone.destroy then zone:destroy() end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceZones[resourceName] then
        for _, zoneData in ipairs(resourceZones[resourceName]) do
            if zoneData.system == 'ox_lib' then
                if zoneData.zone and zoneData.zone.remove then zoneData.zone:remove() end
            elseif zoneData.system == 'polyzone' then
                if zoneData.zone and zoneData.zone.destroy then zoneData.zone:destroy() end
            end
        end
        resourceZones[resourceName] = nil
    end
end)

exports('CreatePolyZone', CreatePolyZone)
exports('CreateBoxZone', CreateBoxZone)
exports('CreateSphereZone', CreateSphereZone)
exports('DeleteZone', DeleteZone)
