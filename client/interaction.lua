
local ResourceInteractions = {}

local function InitializeResourceTracking(resourceName)
    if not ResourceInteractions[resourceName] then
        ResourceInteractions[resourceName] = {
            points = {},
            vehicles = {},
            models = {},
            entities = {}
        }
    end
end

local function GetCallingResource()
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName()
    end
    return resource
end

local function CleanupResourceInteractions(resourceName)
    if not ResourceInteractions[resourceName] then return end
    
    local interactions = ResourceInteractions[resourceName]
    
    for pointId, _ in pairs(interactions.points) do
        RemoveInteractionPoint(pointId)
    end
    
    for vehicleId, _ in pairs(interactions.vehicles) do
        RemoveVehicleInteraction(vehicleId)
    end
    
    for modelId, _ in pairs(interactions.models) do
        RemoveModelInteraction(modelId)
    end
    
    for entityId, _ in pairs(interactions.entities) do
        RemoveEntityInteraction(entityId)
    end
    
    ResourceInteractions[resourceName] = nil
end

AddEventHandler('onResourceStop', function(resourceName)
    CleanupResourceInteractions(resourceName)
end)

function HandleDrawText(pos, radius, options, entity)
    CreateThread(function()
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local dist = #(pcoords - pos)

            if dist <= radius then
                sleep = 0
                local availableOption = nil
                for _, opt in ipairs(options) do
                    if not opt.canInteract or opt.canInteract(entity, dist, pos) then
                        availableOption = opt
                        break
                    end
                end
                
                if availableOption then
                    SetTextScale(0.45, 0.45)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 255, 255, 215)
                    SetTextCentre(true)
                    SetDrawOrigin(pos.x, pos.y, pos.z + 1.0, 0)
                    BeginTextCommandDisplayText("STRING")
                    AddTextComponentSubstringPlayerName("[E] " .. (availableOption.label or "Interact"))
                    EndTextCommandDisplayText(0.0, 0.0)
                    ClearDrawOrigin()

                    if IsControlJustPressed(0, 38) then
                        if availableOption.onSelect then
                            availableOption.onSelect(entity)
                        elseif availableOption.action then
                            availableOption.action(entity)
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

local function GetInteractionSystem()
    local system = Config.Interaction.System
    if system == 'auto' then
        if GetResourceState('lunar_bridge') ~= 'missing' then return 'lunar_bridge'
        elseif GetResourceState('ox_target') ~= 'missing' then return 'ox_target'
        elseif GetResourceState('qb-target') ~= 'missing' then return 'qb-target'
        elseif GetResourceState('is_interaction') ~= 'missing' then return 'is_interaction'
        else return 'textui' end
    end
    return system
end

function CreateInteractionPoint(coords, options)
    local system = GetInteractionSystem()
    local resourceName = GetCallingResource()
    InitializeResourceTracking(resourceName)
    
    if system == 'drawtext' then
        if options.options and #options.options > 0 then
            local pointId = 'drawtext_' .. resourceName .. '_' .. math.random(10000, 99999)
            HandleDrawText(coords, options.distance or Config.Interaction.DefaultDistance, options.options)
            
            ResourceInteractions[resourceName].points[pointId] = {
                type = 'drawtext',
                coords = coords,
                options = options
            }
            return pointId
        end
        
    elseif system == 'textui' then
         local pointId = 'textui_' .. resourceName .. '_' .. math.random(10000, 99999)
         local threadActive = true
         
         ResourceInteractions[resourceName].points[pointId] = {
            type = 'textui',
            stopThread = function() threadActive = false end
         }
         
         CreateThread(function()
             local distance = options.distance or Config.Interaction.DefaultDistance
             local isInRange = false
             local currentLabel = nil
             while threadActive do
                 local sleep = 1000
                 local ped = PlayerPedId()
                 local pcoords = GetEntityCoords(ped)
                 local dist = #(pcoords - coords)
                 
                 if dist <= distance then
                     sleep = 0
                     local availableOption = nil
                     if options.options and #options.options > 0 then
                         for _, opt in ipairs(options.options) do
                             if not opt.canInteract or opt.canInteract() then
                                 availableOption = opt
                                 break
                             end
                         end
                     end

                     if not isInRange then
                         isInRange = true
                         if options.onEnter then options.onEnter() end
                         if availableOption then
                             currentLabel = availableOption.label or 'Interact'
                             exports['spark_lib']:ShowTextUI("[E] " .. currentLabel, 'interaction')
                         else
                             currentLabel = nil
                         end
                     else
                         local newLabel = availableOption and (availableOption.label or 'Interact') or nil
                         if currentLabel ~= newLabel then
                             currentLabel = newLabel
                             if newLabel then
                                 exports['spark_lib']:ShowTextUI("[E] " .. newLabel, 'interaction')
                             else
                                 exports['spark_lib']:HideTextUI()
                             end
                         end
                     end

                     if options.options and #options.options > 0 then
                         if IsControlJustPressed(0, 38) then
                             for _, opt in ipairs(options.options) do
                                 if not opt.canInteract or opt.canInteract() then
                                     if opt.action then opt.action()
                                     elseif opt.onSelect then opt.onSelect()
                                     end
                                     break
                                 end
                             end
                         end
                     end
                 else
                     if isInRange then
                         isInRange = false
                         currentLabel = nil
                         if options.onExit then options.onExit() end
                         exports['spark_lib']:HideTextUI()
                     end
                 end
                 Wait(sleep)
             end
         end)
         return pointId

    elseif system == 'ox_target' then
        if GetResourceState('ox_target') ~= 'missing' then
            local oxOptions = {}
            local defaultDistance = options.distance or 2.0
            if options.options then
                for i, opt in ipairs(options.options) do
                    local oxOpt = {}
                    for k, v in pairs(opt) do oxOpt[k] = v end
                    if opt.action then
                        oxOpt.onSelect = function(data) opt.action(data.entity) end
                        oxOpt.action = nil
                    end
                    if opt.onSelect and not opt.action then
                        oxOpt.onSelect = function(data) opt.onSelect(data.entity) end
                    end
                    if opt.canInteract then oxOpt.canInteract = opt.canInteract end
                    oxOpt.distance = defaultDistance
                    table.insert(oxOptions, oxOpt)
                end
            end
            local pointId = exports.ox_target:addBoxZone({
                coords = coords,
                size = options.size or vector3(2.0, 2.0, 2.0),
                rotation = options.rotation or 0,
                options = oxOptions
            })
            if pointId then ResourceInteractions[resourceName].points[pointId] = true end
            return pointId
        end

    elseif system == 'qb-target' then
        if GetResourceState('qb-target') ~= 'missing' then
            local processedOptions = {}
            if options.options then
                for i, opt in ipairs(options.options) do
                    local qbOpt = {}
                    for k, v in pairs(opt) do qbOpt[k] = v end
                    qbOpt.type = qbOpt.type or 'client'
                    if opt.canInteract then qbOpt.canInteract = opt.canInteract end
                    table.insert(processedOptions, qbOpt)
                end
            end
            local size = options.size or vector3(2.0, 2.0, 2.0)
            local pointId = exports['qb-target']:AddBoxZone(options.name or options.id or 'interaction_zone', coords, 
                size.x, size.y, {
                    name = options.name or options.id or 'interaction_zone',
                    heading = options.rotation or 0,
                    debugPoly = options.debug or false,
                    minZ = coords.z - (size.z / 2),
                    maxZ = coords.z + (size.z / 2),
                }, {
                    options = processedOptions,
                    distance = options.distance or Config.Interaction.DefaultDistance
                })
            if pointId then ResourceInteractions[resourceName].points[pointId] = true end
            return pointId
        end

    elseif system == 'lunar_bridge' then
        if GetResourceState('lunar_bridge') ~= 'missing' then
            local lbOptions = {}
            local defaultDistance = options.distance or Config.Interaction.DefaultDistance
            if options.options then
                for i, opt in ipairs(options.options) do
                    local lbOpt = {}
                    for k, v in pairs(opt) do lbOpt[k] = v end
                    if opt.action then
                        lbOpt.onSelect = function(data)
                            local entity = type(data) == 'table' and data.entity or data
                            opt.action(entity)
                        end
                        lbOpt.action = nil
                    end
                    if opt.onSelect and not opt.action then
                        lbOpt.onSelect = function(data)
                            local entity = type(data) == 'table' and data.entity or data
                            opt.onSelect(entity)
                        end
                    end
                    if opt.canInteract then lbOpt.canInteract = opt.canInteract end
                    table.insert(lbOptions, lbOpt)
                end
            end
            local pointId = exports.lunar_bridge:addPoint({
                coords = coords,
                distance = defaultDistance,
                options = lbOptions
            })
            if pointId then ResourceInteractions[resourceName].points[pointId] = true end
            return pointId
        end

    elseif system == 'is_interaction' then
        if GetResourceState('is_interaction') ~= 'missing' then
            local defaultDistance = options.distance or Config.Interaction.DefaultDistance
            local pointName = options.name or options.id or ('sd_' .. resourceName .. '_' .. math.random(10000, 99999))
            local coordsVec = vec3(coords.x, coords.y, coords.z + 1.0)
            
            local isRegistered = false
            local threadActive = true
            local lastRegisteredOptionsHash = ""

            local function registerPoint(filteredOptions)
                exports['is_interaction']:addInteractionCoords(pointName, coordsVec, {
                    distance = defaultDistance,
                    distanceText = defaultDistance,
                    options = filteredOptions,
                })
            end

            local function unregisterPoint()
                exports['is_interaction']:removeCoords(coordsVec, pointName)
            end

            CreateThread(function()
                while threadActive do
                    local allowedOptions = {}
                    local optionHashParts = {}

                    if options.options and #options.options > 0 then
                        for i, opt in ipairs(options.options) do
                            local optAllowed = true
                            if opt.canInteract then
                                local status, val = pcall(opt.canInteract)
                                if status then
                                    optAllowed = val
                                else
                                    optAllowed = false
                                end
                            end

                            if optAllowed then
                                table.insert(allowedOptions, {
                                    name  = opt.name or ('ep_opt_' .. i),
                                    label = opt.label or 'Interact',
                                    icon  = opt.icon or 'fa-solid fa-hand-pointer',
                                    onSelect = function(entity)
                                        if opt.canInteract and not opt.canInteract(entity) then return end
                                        if opt.onSelect then opt.onSelect(entity)
                                        elseif opt.action then opt.action(entity) end
                                    end,
                                })
                                table.insert(optionHashParts, opt.name or ('ep_opt_' .. i))
                            end
                        end
                    end

                    local currentHash = table.concat(optionHashParts, ",")

                    if #allowedOptions > 0 and threadActive then
                        if not isRegistered or currentHash ~= lastRegisteredOptionsHash then
                            if isRegistered then
                                unregisterPoint()
                            end
                            registerPoint(allowedOptions)
                            isRegistered = true
                            lastRegisteredOptionsHash = currentHash
                        end
                    else
                        if isRegistered then
                            unregisterPoint()
                            isRegistered = false
                            lastRegisteredOptionsHash = ""
                        end
                    end
                    Wait(250)
                end
            end)

            local pointId = pointName
            ResourceInteractions[resourceName].points[pointId] = {
                type   = 'is_interaction',
                name   = pointName,
                coords = coordsVec,
                stopThread = function()
                    threadActive = false
                    unregisterPoint()
                end
            }
            return pointId
        end
    end
end

function CreateVehicleInteraction(options)
    local system = GetInteractionSystem()
    local resourceName = GetCallingResource()
    InitializeResourceTracking(resourceName)
    
    if system == 'drawtext' then
        local vehicleId = 'drawtext_vehicle_' .. resourceName .. '_' .. math.random(10000, 99999)
        local threadActive = true
        CreateThread(function()
            local distance = options.distance or Config.Interaction.DefaultDistance
            while threadActive do
                local sleep = 1000
                local ped = PlayerPedId()
                local pcoords = GetEntityCoords(ped)
                local vehicle = GetClosestVehicle(pcoords.x, pcoords.y, pcoords.z, distance + 5.0, 0, 71)
                if vehicle ~= 0 and DoesEntityExist(vehicle) then
                    local vcoords = GetEntityCoords(vehicle)
                    local dist = #(pcoords - vcoords)
                    if dist <= distance then
                        sleep = 0
                        local availableOption = nil
                        for _, opt in ipairs(options.options) do
                            if not opt.canInteract or opt.canInteract(vehicle, dist, vcoords) then
                                availableOption = opt
                                break
                            end
                        end
                        if availableOption then
                             SetTextScale(0.45, 0.45)
                             SetTextFont(4)
                             SetTextProportional(1)
                             SetTextColour(255, 255, 255, 215)
                             SetTextCentre(true)
                             SetDrawOrigin(vcoords.x, vcoords.y, vcoords.z + 1.0, 0)
                             BeginTextCommandDisplayText("STRING")
                             AddTextComponentSubstringPlayerName("[E] " .. (availableOption.label or "Interact"))
                             EndTextCommandDisplayText(0.0, 0.0)
                             ClearDrawOrigin()
                             if IsControlJustPressed(0, 38) then
                                 if availableOption.action then availableOption.action(vehicle)
                                 elseif availableOption.onSelect then availableOption.onSelect(vehicle) end
                             end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
        ResourceInteractions[resourceName].vehicles[vehicleId] = {
            type = 'drawtext',
            options = options,
            stopThread = function() threadActive = false end
        }
        return vehicleId
        
    elseif system == 'textui' then
         local vehicleId = 'textui_vehicle_' .. resourceName .. '_' .. math.random(10000, 99999)
         local threadActive = true
         ResourceInteractions[resourceName].vehicles[vehicleId] = {
            type = 'textui',
            stopThread = function() threadActive = false end
         }
         CreateThread(function()
             local distance = options.distance or Config.Interaction.DefaultDistance
             local isInRange = false
             while threadActive do
                 local sleep = 1000
                 local ped = PlayerPedId()
                 local pcoords = GetEntityCoords(ped)
                 local vehicle = GetClosestVehicle(pcoords.x, pcoords.y, pcoords.z, distance + 5.0, 0, 71)
                 if vehicle ~= 0 and DoesEntityExist(vehicle) then
                      local vcoords = GetEntityCoords(vehicle)
                      local dist = #(pcoords - vcoords)
                      if dist <= distance then
                          sleep = 0
                          if not isInRange then
                              isInRange = true
                              if options.onEnter then options.onEnter(vehicle) end
                              local availableOption = nil
                              if options.options and #options.options > 0 then
                                  for _, opt in ipairs(options.options) do
                                      if not opt.canInteract or opt.canInteract(vehicle, dist, vcoords) then
                                          availableOption = opt
                                          break
                                      end
                                  end
                                  if availableOption then
                                      exports['spark_lib']:ShowTextUI("[E] " .. (availableOption.label or 'Interact'), 'interaction')
                                  end
                              end
                          end
                          if options.options and #options.options > 0 then
                              if IsControlJustPressed(0, 38) then
                                  for _, opt in ipairs(options.options) do
                                      if not opt.canInteract or opt.canInteract(vehicle, dist, vcoords) then
                                          if opt.action then opt.action(vehicle)
                                          elseif opt.onSelect then opt.onSelect(vehicle) end
                                          break
                                      end
                                  end
                              end
                          end
                      else
                          if isInRange then
                              isInRange = false
                              if options.onExit then options.onExit(vehicle) end
                              exports['spark_lib']:HideTextUI()
                          end
                      end
                 else
                     if isInRange then
                         isInRange = false
                         if options.onExit then options.onExit() end
                         exports['spark_lib']:HideTextUI()
                     end
                 end
                 Wait(sleep)
             end
         end)
         return vehicleId
         
    elseif system == 'ox_target' or system == 'lunar_bridge' then
        if GetResourceState('ox_target') == "started" then
            local oxOptions = {}
            local defaultDistance = options.distance or 2.0
             if options.options then
                 for i, opt in ipairs(options.options) do
                     local oxOpt = {}
                     for k, v in pairs(opt) do oxOpt[k] = v end
                     if opt.action then
                         oxOpt.onSelect = function(data) opt.action(data.entity) end
                         oxOpt.action = nil
                     end
                     if opt.onSelect and not opt.action then
                         oxOpt.onSelect = function(data) opt.onSelect(data.entity) end
                     end
                     if opt.canInteract then oxOpt.canInteract = opt.canInteract end
                     oxOpt.distance = defaultDistance
                     table.insert(oxOptions, oxOpt)
                 end
             end
            exports.ox_target:addGlobalVehicle(oxOptions)
            local vehicleKey = 'vehicles_' .. math.random(10000, 99999)
            ResourceInteractions[resourceName].vehicles[vehicleKey] = { options = options }
             return vehicleKey
            end
         
    elseif system == 'qb-target' then
         local processedOptions = {}
         if options.options then
             for i, opt in ipairs(options.options) do
                 local qbOpt = {}
                 for k, v in pairs(opt) do qbOpt[k] = v end
                 qbOpt.type = qbOpt.type or 'client'
                 if opt.canInteract then qbOpt.canInteract = opt.canInteract end
                 table.insert(processedOptions, qbOpt)
             end
         end
         exports['qb-target']:AddGlobalVehicle({
             options = processedOptions,
             distance = options.distance or Config.Interaction.DefaultDistance
         })
         local vehicleKey = 'vehicles_' .. math.random(10000, 99999)
         ResourceInteractions[resourceName].vehicles[vehicleKey] = { options = options }
         return vehicleKey
    end
end

function CreateModelInteraction(models, options)
    local system = GetInteractionSystem()
    local resourceName = GetCallingResource()
    InitializeResourceTracking(resourceName)
    
    if system == 'drawtext' then
        local modelId = 'drawtext_model_' .. resourceName .. '_' .. math.random(10000, 99999)
        local threadActive = true
        CreateThread(function()
            while threadActive do
                local sleep = 1000
                local ped = PlayerPedId()
                local pcoords = GetEntityCoords(ped)
                local foundEntity = nil
                local distance = options.distance or Config.Interaction.DefaultDistance
                for _, model in ipairs(models) do
                    local modelHash = type(model) == 'string' and GetHashKey(model) or model
                    local entity = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, distance + 3.0, modelHash, false, false, false)
                    if entity ~= 0 and DoesEntityExist(entity) then
                        local dist = #(pcoords - GetEntityCoords(entity))
                        if dist <= distance then
                            foundEntity = entity
                            break
                        end
                    end
                end
                
                if foundEntity then
                    local ecoords = GetEntityCoords(foundEntity)
                    local dist = #(pcoords - ecoords)
                    if dist <= distance then
                        sleep = 0
                        local availableOption = nil
                        for _, opt in ipairs(options.options) do
                            if not opt.canInteract or opt.canInteract(foundEntity, dist, ecoords) then
                                availableOption = opt
                                break
                            end
                        end
                        if availableOption then
                             SetTextScale(0.45, 0.45)
                             SetTextFont(4)
                             SetTextProportional(1)
                             SetTextColour(255, 255, 255, 215)
                             SetTextCentre(true)
                             SetDrawOrigin(ecoords.x, ecoords.y, ecoords.z + 1.0, 0)
                             BeginTextCommandDisplayText("STRING")
                             AddTextComponentSubstringPlayerName("[E] " .. (availableOption.label or "Interact"))
                             EndTextCommandDisplayText(0.0, 0.0)
                             ClearDrawOrigin()
                             if IsControlJustPressed(0, 38) then
                                 if availableOption.action then availableOption.action(foundEntity)
                                 elseif availableOption.onSelect then availableOption.onSelect(foundEntity) end
                             end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
        ResourceInteractions[resourceName].models[modelId] = {
            type = 'drawtext',
            models = models, 
            options = options,
            stopThread = function() threadActive = false end
        }
        return modelId
        
    elseif system == 'textui' then
         local modelId = 'textui_model_' .. resourceName .. '_' .. math.random(10000, 99999)
         local threadActive = true
         ResourceInteractions[resourceName].models[modelId] = {
             type = 'textui',
             models = models,
             stopThread = function() threadActive = false end
         }
         CreateThread(function()
             local distance = options.distance or Config.Interaction.DefaultDistance
             local isInRange = false
             while threadActive do
                 local sleep = 1000
                 local ped = PlayerPedId()
                 local pcoords = GetEntityCoords(ped)
                 local foundEntity = nil
                 for _, model in ipairs(models) do
                     local modelHash = type(model) == 'string' and GetHashKey(model) or model
                     local entity = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, distance + 3.0, modelHash, false, false, false)
                     if entity ~= 0 and DoesEntityExist(entity) then
                         local dist = #(pcoords - GetEntityCoords(entity))
                         if dist <= distance then
                             foundEntity = entity
                             break
                         end
                     end
                 end
                 
                 if foundEntity then
                     local ecoords = GetEntityCoords(foundEntity)
                     local dist = #(pcoords - ecoords)
                     if dist <= distance then
                         sleep = 0
                         if not isInRange then
                             isInRange = true
                             if options.onEnter then options.onEnter(foundEntity) end
                             local availableOption = nil
                             if options.options and #options.options > 0 then
                                 for _, opt in ipairs(options.options) do
                                     if not opt.canInteract or opt.canInteract(foundEntity, dist, ecoords) then
                                         availableOption = opt
                                         break
                                     end
                                 end
                                 if availableOption then
                                     exports['spark_lib']:ShowTextUI("[E] " .. (availableOption.label or 'Interact'), 'interaction')
                                 end
                             end
                         end
                         if options.options and #options.options > 0 then
                             if IsControlJustPressed(0, 38) then
                                 for _, opt in ipairs(options.options) do
                                     if not opt.canInteract or opt.canInteract(foundEntity, dist, ecoords) then
                                         if opt.action then opt.action(foundEntity)
                                         elseif opt.onSelect then opt.onSelect(foundEntity) end
                                         break
                                     end
                                 end
                             end
                         end
                     else
                         if isInRange then
                             isInRange = false
                             if options.onExit then options.onExit(foundEntity) end
                             exports['spark_lib']:HideTextUI()
                         end
                     end
                 else
                     if isInRange then
                         isInRange = false
                         if options.onExit then options.onExit() end
                         exports['spark_lib']:HideTextUI()
                     end
                 end
                 Wait(sleep)
             end
         end)
         return modelId
         
    elseif system == 'ox_target' then
         local oxOptions = {}
         local defaultDistance = options.distance or 2.0
         if options.options then
             for i, opt in ipairs(options.options) do
                 local oxOpt = {}
                 for k, v in pairs(opt) do oxOpt[k] = v end
                 if opt.action then
                     oxOpt.onSelect = function(data) opt.action(data.entity) end
                     oxOpt.action = nil
                 end
                 if opt.onSelect and not opt.action then
                     oxOpt.onSelect = function(data) opt.onSelect(data.entity) end
                 end
                 if opt.canInteract then oxOpt.canInteract = opt.canInteract end
                 oxOpt.distance = defaultDistance
                 table.insert(oxOptions, oxOpt)
             end
         end
         exports.ox_target:addModel(models, oxOptions)
         local optionNames = {}
         if options.options then
             for _, opt in ipairs(options.options) do
                 if opt.name then table.insert(optionNames, opt.name) end
             end
         end
         local modelKey = 'models_' .. math.random(10000, 99999)
         ResourceInteractions[resourceName].models[modelKey] = {
             models = models,
             optionNames = optionNames
         }
         return modelKey
         
    elseif system == 'qb-target' then
         local processedOptions = {}
         if options.options then
             for i, opt in ipairs(options.options) do
                 local qbOpt = {}
                 for k, v in pairs(opt) do qbOpt[k] = v end
                 qbOpt.type = qbOpt.type or 'client'
                 if opt.canInteract then qbOpt.canInteract = opt.canInteract end
                 table.insert(processedOptions, qbOpt)
             end
         end
         exports['qb-target']:AddTargetModel(models, {
             options = processedOptions,
             distance = options.distance or Config.Interaction.DefaultDistance
         })
         local labels = {}
         if options.options then
             for _, opt in ipairs(options.options) do
                 if opt.label then table.insert(labels, opt.label) end
             end
         end
         local modelKey = 'models_' .. math.random(10000, 99999)
         ResourceInteractions[resourceName].models[modelKey] = {
             models = models,
             labels = labels
         }
         return modelKey

    elseif system == 'is_interaction' then
        if GetResourceState('is_interaction') ~= 'missing' then
            local defaultDistance = options.distance or Config.Interaction.DefaultDistance
            local modelKey = 'sd_model_' .. resourceName .. '_' .. math.random(10000, 99999)
            local processedOptions = {}
            if options.options then
                for i, opt in ipairs(options.options) do
                    table.insert(processedOptions, {
                        name = opt.name or ('ep_opt_' .. i),
                        label = opt.label or 'Interact',
                        icon = opt.icon or 'fa-solid fa-hand-pointer',
                        onSelect = function(entity)
                            if opt.canInteract and not opt.canInteract(entity) then return end
                            if opt.onSelect then opt.onSelect(entity)
                            elseif opt.action then opt.action(entity) end
                        end,
                    })
                end
            end
            
            local modelHashes = {}
            if type(models) == 'table' then
                for _, model in ipairs(models) do
                    local hash = type(model) == 'string' and GetHashKey(model) or model
                    table.insert(modelHashes, hash)
                end
            else
                local hash = type(models) == 'string' and GetHashKey(models) or models
                modelHashes = { hash }
            end

            exports['is_interaction']:addInteractionModel(modelKey, modelHashes, {
                distance = defaultDistance,
                distanceText = defaultDistance,
                offset = {
                    text = {x = 0.0, y = 0.0, z = 1.0},
                    target = {x = 0.0, y = 0.0, z = 1.0}
                },
                options = processedOptions,
            })

            ResourceInteractions[resourceName].models[modelKey] = {
                type = 'is_interaction',
                models = modelHashes,
                stopThread = function()
                    exports['is_interaction']:removeModel(modelHashes, modelKey)
                end
            }
            return modelKey
        end
    end
end

function CreateEntityInteraction(entity, options)
    local system = GetInteractionSystem()
    local resourceName = GetCallingResource()
    InitializeResourceTracking(resourceName)
    
    if system == 'drawtext' then
        local entityId = 'drawtext_entity_' .. resourceName .. '_' .. math.random(10000, 99999)
        local threadActive = true
        CreateThread(function()
            while DoesEntityExist(entity) and threadActive do
                local sleep = 1000
                local ped = PlayerPedId()
                local pcoords = GetEntityCoords(ped)
                local ecoords = GetEntityCoords(entity)
                local dist = #(pcoords - ecoords)
                if dist <= (options.distance or Config.Interaction.DefaultDistance) then
                    sleep = 0
                    local availableOption = nil
                    for _, opt in ipairs(options.options) do
                        if not opt.canInteract or opt.canInteract(entity, dist, ecoords) then
                            availableOption = opt
                            break
                        end
                    end
                    if availableOption then
                        SetTextScale(0.45, 0.45)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 255, 255, 215)
                        SetTextCentre(true)
                        SetDrawOrigin(ecoords.x, ecoords.y, ecoords.z + 1.0, 0)
                        BeginTextCommandDisplayText("STRING")
                        AddTextComponentSubstringPlayerName("[E] " .. (availableOption.label or "Interact"))
                        EndTextCommandDisplayText(0.0, 0.0)
                        ClearDrawOrigin()
                        if IsControlJustPressed(0, 38) then
                            if availableOption.action then availableOption.action(entity)
                            elseif availableOption.onSelect then availableOption.onSelect(entity) end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
        ResourceInteractions[resourceName].entities[entityId] = {
            type = 'drawtext',
            entity = entity, 
            options = options,
            stopThread = function() threadActive = false end
        }
        return entityId
        
    elseif system == 'textui' then
         local entityId = 'textui_entity_' .. resourceName .. '_' .. math.random(10000, 99999)
         local threadActive = true
         ResourceInteractions[resourceName].entities[entityId] = {
            type = 'textui',
            entity = entity,
            stopThread = function() threadActive = false end
         }
         CreateThread(function()
             local distance = options.distance or Config.Interaction.DefaultDistance
             local isInRange = false
             while DoesEntityExist(entity) and threadActive do
                 local sleep = 1000
                 local ped = PlayerPedId()
                 local pcoords = GetEntityCoords(ped)
                 local ecoords = GetEntityCoords(entity)
                 local dist = #(pcoords - ecoords)
                 
                 if dist <= distance then
                     sleep = 0
                     if not isInRange then
                         isInRange = true
                         if options.onEnter then options.onEnter(entity) end
                         local availableOption = nil
                         if options.options and #options.options > 0 then
                             for _, opt in ipairs(options.options) do
                                 if not opt.canInteract or opt.canInteract(entity, dist, ecoords) then
                                     availableOption = opt
                                     break
                                 end
                             end
                             if availableOption then
                                 exports['spark_lib']:ShowTextUI("[E] " .. (availableOption.label or 'Interact'), 'interaction')
                             end
                         end
                     end
                     if options.options and #options.options > 0 then
                         if IsControlJustPressed(0, 38) then
                             for _, opt in ipairs(options.options) do
                                 if not opt.canInteract or opt.canInteract(entity, dist, ecoords) then
                                     if opt.action then opt.action(entity)
                                     elseif opt.onSelect then opt.onSelect(entity) end
                                     break
                                 end
                             end
                         end
                     end
                 else
                     if isInRange then
                         isInRange = false
                         if options.onExit then options.onExit(entity) end
                         exports['spark_lib']:HideTextUI()
                     end
                 end
                 Wait(sleep)
             end
         end)
         return entityId
         
    elseif system == 'ox_target' then
         local oxOptions = {}
         local defaultDistance = options.distance or 2.0
         if options.options then
             for i, opt in ipairs(options.options) do
                 local oxOpt = {}
                 for k, v in pairs(opt) do oxOpt[k] = v end
                 if opt.action then
                     oxOpt.onSelect = function(data) opt.action(data.entity) end
                     oxOpt.action = nil
                 end
                 if opt.onSelect and not opt.action then
                     oxOpt.onSelect = function(data) opt.onSelect(data.entity) end
                 end
                 if opt.canInteract then oxOpt.canInteract = opt.canInteract end
                 oxOpt.distance = defaultDistance
                 table.insert(oxOptions, oxOpt)
             end
         end
         local entityId = exports.ox_target:addLocalEntity(entity, oxOptions)
         if entityId then ResourceInteractions[resourceName].entities[entityId] = entity end
         return entityId
         
    elseif system == 'qb-target' then
         local processedOptions = {}
         if options.options then
             for i, opt in ipairs(options.options) do
                 local qbOpt = {}
                 for k, v in pairs(opt) do qbOpt[k] = v end
                 qbOpt.type = qbOpt.type or 'client'
                 if opt.canInteract then qbOpt.canInteract = opt.canInteract end
                 table.insert(processedOptions, qbOpt)
             end
         end
         local entityId = exports['qb-target']:AddTargetEntity(entity, {
             options = processedOptions,
             distance = options.distance or Config.Interaction.DefaultDistance
         })
         if entityId then ResourceInteractions[resourceName].entities[entityId] = entity end
         return entityId

    elseif system == 'lunar_bridge' then
         if GetResourceState('lunar_bridge') ~= 'missing' then
             local lbOptions = {}
             local defaultDistance = options.distance or Config.Interaction.DefaultDistance
             if options.options then
                 for i, opt in ipairs(options.options) do
                     local lbOpt = {}
                     for k, v in pairs(opt) do lbOpt[k] = v end
                     if opt.action then
                         lbOpt.onSelect = function(data)
                             local ent = type(data) == 'table' and data.entity or entity
                             opt.action(ent)
                         end
                         lbOpt.action = nil
                     end
                     if opt.onSelect and not opt.action then
                         lbOpt.onSelect = function(data)
                             local ent = type(data) == 'table' and data.entity or entity
                             opt.onSelect(ent)
                         end
                     end
                     if opt.canInteract then lbOpt.canInteract = opt.canInteract end
                     table.insert(lbOptions, lbOpt)
                 end
             end
             local entityId = exports.lunar_bridge:addLocalEntity({
                 entity = entity,
                 distance = defaultDistance,
                 offset = options.offset or vector3(0.0, 0.0, 0.0),
                 options = lbOptions
             })
             if entityId then ResourceInteractions[resourceName].entities[entityId] = entity end
             return entityId
         end

    elseif system == 'is_interaction' then
        if GetResourceState('is_interaction') ~= 'missing' then
            local defaultDistance = options.distance or Config.Interaction.DefaultDistance
            local entityId = 'sd_entity_' .. resourceName .. '_' .. math.random(10000, 99999)
            local processedOptions = {}
            if options.options then
                for i, opt in ipairs(options.options) do
                    table.insert(processedOptions, {
                        name = opt.name or ('ep_opt_' .. i),
                        label = opt.label or 'Interact',
                        icon = opt.icon or 'fa-solid fa-hand-pointer',
                        onSelect = function(ent)
                            if opt.canInteract and not opt.canInteract(ent) then return end
                            if opt.onSelect then opt.onSelect(ent)
                            elseif opt.action then opt.action(ent) end
                        end,
                    })
                end
            end

            exports['is_interaction']:addInteractionLocalEntity(entityId, entity, {
                distance = defaultDistance,
                distanceText = defaultDistance,
                offset = {
                    text = {x = 0.0, y = 0.0, z = 1.0},
                    target = {x = 0.0, y = 0.0, z = 1.0}
                },
                options = processedOptions,
            })

            ResourceInteractions[resourceName].entities[entityId] = {
                type = 'is_interaction',
                entity = entity,
                stopThread = function()
                    exports['is_interaction']:removeLocalEntity(entity, entityId)
                end
            }
            return entityId
        end
    end
end

function RemoveInteractionPoint(pointId)
    if not pointId then return end
    
    local pointData = nil
    for resourceName, interactions in pairs(ResourceInteractions) do
        if interactions.points[pointId] then
            pointData = interactions.points[pointId]
            if type(pointData) == 'table' and pointData.stopThread then pointData.stopThread() end
            interactions.points[pointId] = nil
            break
        end
    end
    
    local system = GetInteractionSystem()
    if system == 'ox_target' then
        exports.ox_target:removeZone(pointId)
    elseif system == 'qb-target' then
        exports['qb-target']:RemoveZone(pointId)
    elseif system == 'is_interaction' then
        if pointData and type(pointData) == 'table' and pointData.type == 'is_interaction' then
            exports['is_interaction']:removeCoords(pointData.coords, pointData.name)
        end
    else
        exports['spark_lib']:HideTextUI()
    end
end

function RemoveVehicleInteraction(vehicleId)
    if not vehicleId then return end
    for resourceName, interactions in pairs(ResourceInteractions) do
        if interactions.vehicles[vehicleId] then
            local vehicleData = interactions.vehicles[vehicleId]
            
            local system = GetInteractionSystem()
            if system == 'ox_target' and vehicleData and vehicleData.options and vehicleData.options.options then
                 local optionNames = {}
                 for _, opt in ipairs(vehicleData.options.options) do
                     if opt.name then table.insert(optionNames, opt.name) end
                 end
                 if #optionNames > 0 then exports.ox_target:removeGlobalVehicle(optionNames) end
            elseif system == 'qb-target' and vehicleData and vehicleData.options and vehicleData.options.options then
                 local labels = {}
                 for _, opt in ipairs(vehicleData.options.options) do
                     if opt.label then table.insert(labels, opt.label) end
                 end
                 if #labels > 0 then exports['qb-target']:RemoveGlobalVehicle(labels) end
            end
            
            if type(vehicleData) == 'table' and vehicleData.stopThread then vehicleData.stopThread() end
            interactions.vehicles[vehicleId] = nil
            break
        end
    end
    exports['spark_lib']:HideTextUI()
end

function RemoveModelInteraction(modelId)
    if not modelId then return end
    for resourceName, interactions in pairs(ResourceInteractions) do
        if interactions.models[modelId] then
            local modelData = interactions.models[modelId]
            
            local system = GetInteractionSystem()
            if system == 'ox_target' and type(modelData) == 'table' and modelData.models then
                 if #modelData.optionNames > 0 then exports.ox_target:removeModel(modelData.models, modelData.optionNames)
                 else exports.ox_target:removeModel(modelData.models) end
            elseif system == 'qb-target' and type(modelData) == 'table' and modelData.models then
                 if #modelData.labels > 0 then exports['qb-target']:RemoveTargetModel(modelData.models, modelData.labels) end
            end
            
            if type(modelData) == 'table' and modelData.stopThread then modelData.stopThread() end
            interactions.models[modelId] = nil
            break
        end
    end
    exports['spark_lib']:HideTextUI()
end

function RemoveEntityInteraction(entityIdOrEntity)
    if not entityIdOrEntity then return end
    for resourceName, interactions in pairs(ResourceInteractions) do
        for entityId, entityData in pairs(interactions.entities) do
            local shouldRemove = false
            if entityId == entityIdOrEntity then shouldRemove = true
            elseif type(entityData) == 'table' and entityData.entity == entityIdOrEntity then shouldRemove = true
            elseif entityData == entityIdOrEntity then shouldRemove = true
            end
            
            if shouldRemove then
                if type(entityData) == 'table' and entityData.stopThread then entityData.stopThread() end
                interactions.entities[entityId] = nil
                break
            end
        end
    end
    
    local system = GetInteractionSystem()
    if system == 'ox_target' and type(entityIdOrEntity) == 'number' then exports.ox_target:removeLocalEntity(entityIdOrEntity)
    elseif system == 'qb-target' and type(entityIdOrEntity) == 'number' then exports['qb-target']:RemoveTargetEntity(entityIdOrEntity)
    else exports['spark_lib']:HideTextUI()
    end
end

exports('HandleDrawText', HandleDrawText)
exports('CreateInteractionPoint', CreateInteractionPoint)
exports('CreateVehicleInteraction', CreateVehicleInteraction)
exports('CreateModelInteraction', CreateModelInteraction)
exports('CreateEntityInteraction', CreateEntityInteraction)
exports('RemoveInteractionPoint', RemoveInteractionPoint)
exports('RemoveVehicleInteraction', RemoveVehicleInteraction)
exports('RemoveModelInteraction', RemoveModelInteraction)
exports('RemoveEntityInteraction', RemoveEntityInteraction)