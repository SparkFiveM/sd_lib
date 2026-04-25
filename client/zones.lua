local Config = Config or {}

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
    
    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            return lib.zones.poly({
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
            local zone = PolyZone:Create(data.points, {
                name = data.name,
                debugPoly = data.debug or false,
                minZ = data.minZ,
                maxZ = data.maxZ
            })
            
            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
            
            return zone
        end
    end
end

function CreateBoxZone(data)
    local system = GetZonesSystem()
    
    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            return lib.zones.box({
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
            local zone = BoxZone:Create(data.coords, data.size.y, data.size.x, {
                name = data.name,
                heading = data.rotation,
                debugPoly = data.debug or false,
                minZ = data.minZ,
                maxZ = data.maxZ
            })
            
            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
            
            return zone
        end
    end
end

function CreateSphereZone(data)
    local system = GetZonesSystem()
    
    if system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.zones then
            return lib.zones.sphere({
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
            local zone = CircleZone:Create(data.coords, data.radius, {
                name = data.name,
                debugPoly = data.debug or false,
                useZ = true
            })
            
            if data.onEnter then zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then data.onEnter() else data.onExit() end
            end) end
            
            return zone
        end
    end
end

function DeleteZone(zone)
    local system = GetZonesSystem()
    
    if system == 'ox_lib' then
        if zone and zone.remove then zone:remove() end
    elseif system == 'polyzone' then
        if zone and zone.destroy then zone:destroy() end
    end
end

exports('CreatePolyZone', CreatePolyZone)
exports('CreateBoxZone', CreateBoxZone)
exports('CreateSphereZone', CreateSphereZone)
exports('DeleteZone', DeleteZone)
