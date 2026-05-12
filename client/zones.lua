local ResourceZones = {}

local function GetZonesSystem()
    local system = Config.Zones.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('PolyZone') ~= 'missing' then return 'polyzone'
        end
    end
    return system
end

local function GetCallingResource()
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName()
    end
    return resource
end

local function InitializeResourceTracking(resourceName)
    if not ResourceZones[resourceName] then
        ResourceZones[resourceName] = {}
    end
end

local function TrackZone(zone)
    if not zone then return end
    local resourceName = GetCallingResource()
    InitializeResourceTracking(resourceName)
    table.insert(ResourceZones[resourceName], zone)
end

local function CleanupResourceZones(resourceName)
    if not ResourceZones[resourceName] then return end
    
    for _, zone in ipairs(ResourceZones[resourceName]) do
        DeleteZone(zone)
    end
    
    ResourceZones[resourceName] = nil
end

function CreatePolyZone(data)
    local system = GetZonesSystem()
    local zone
    
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
            
            zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then
                    if data.onEnter then data.onEnter() end
                else
                    if data.onExit then data.onExit() end
                end
            end)
        end
    end

    if zone then TrackZone(zone) end
    return zone
end

function CreateBoxZone(data)
    local system = GetZonesSystem()
    local zone
    
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
            
            zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then
                    if data.onEnter then data.onEnter() end
                else
                    if data.onExit then data.onExit() end
                end
            end)
        end
    end

    if zone then TrackZone(zone) end
    return zone
end

function CreateSphereZone(data)
    local system = GetZonesSystem()
    local zone
    
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
            
            zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then
                    if data.onEnter then data.onEnter() end
                else
                    if data.onExit then data.onExit() end
                end
            end)
        end
    end

    if zone then TrackZone(zone) end
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
    CleanupResourceZones(resourceName)
end)

exports('CreatePolyZone', CreatePolyZone)
exports('CreateBoxZone', CreateBoxZone)
exports('CreateSphereZone', CreateSphereZone)
exports('DeleteZone', DeleteZone)