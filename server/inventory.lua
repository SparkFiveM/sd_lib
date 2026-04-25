local Config = Config or {}

local function GetInventorySystem()
    local system = Config.Inventory.System
    if system == 'auto' then
        if GetResourceState('ox_inventory') ~= 'missing' then return 'ox_inventory'
        elseif GetResourceState('ps-inventory') ~= 'missing' then return 'ps-inventory'
        elseif GetResourceState('qb-inventory') ~= 'missing' then return 'qb-inventory'
        elseif GetResourceState('lj-inventory') ~= 'missing' then return 'lj-inventory'
        elseif GetResourceState('origen_inventory') ~= 'missing' then return 'origen_inventory'
        elseif GetResourceState('codem-inventory') ~= 'missing' then return 'codem-inventory'
        elseif GetResourceState('tgiann-inventory') ~= 'missing' then return 'tgiann-inventory'
        elseif GetResourceState('jpr-inventory') ~= 'missing' then return 'jpr-inventory'
        end
    end
    return system
end

function AddItem(player, item, count)
    local system = GetInventorySystem()
    if GetResourceState(system) == 'missing' then return false end

    if system == 'codem-inventory' then return exports['codem-inventory']:AddItem(player, item, count)
    elseif system == 'jpr-inventory' then return exports['jpr-inventory']:AddItem(player, item, count)
    elseif system == 'lj-inventory' then return exports['lj-inventory']:AddItem(player, item, count)
    elseif system == 'origen_inventory' then return exports['origen_inventory']:AddItem(player, item, count)
    elseif system == 'ox_inventory' then return exports.ox_inventory:AddItem(player, item, count)
    elseif system == 'ps-inventory' then return exports['ps-inventory']:AddItem(player, item, count)
    elseif system == 'qb-inventory' then return exports['qb-inventory']:AddItem(player, item, count)
    elseif system == 'tgiann-inventory' then return exports['tgiann-inventory']:AddItem(player, item, count)
    end
    return false
end

function RemoveItem(player, item, count)
    local system = GetInventorySystem()
    if GetResourceState(system) == 'missing' then return false end
    
    if system == 'codem-inventory' then return exports['codem-inventory']:RemoveItem(player, item, count)
    elseif system == 'jpr-inventory' then return exports['jpr-inventory']:RemoveItem(player, item, count)
    elseif system == 'lj-inventory' then return exports['lj-inventory']:RemoveItem(player, item, count)
    elseif system == 'origen_inventory' then return exports['origen_inventory']:RemoveItem(player, item, count)
    elseif system == 'ox_inventory' then return exports.ox_inventory:RemoveItem(player, item, count)
    elseif system == 'ps-inventory' then return exports['ps-inventory']:RemoveItem(player, item, count)
    elseif system == 'qb-inventory' then return exports['qb-inventory']:RemoveItem(player, item, count)
    elseif system == 'tgiann-inventory' then return exports['tgiann-inventory']:RemoveItem(player, item, count)
    end
    return false
end

function GetItemCount(player, item)
    local system = GetInventorySystem()
    if GetResourceState(system) == 'missing' then return 0 end
    
    if system == 'codem-inventory' then return exports['codem-inventory']:GetItemsTotalAmount(player, item) or 0
    elseif system == 'jpr-inventory' then return exports['jpr-inventory']:GetItemCount(player, item) or 0
    elseif system == 'lj-inventory' then return exports['lj-inventory']:GetItemCount(player, item) or 0
    elseif system == 'origen_inventory' then return exports['origen_inventory']:GetItemCount(player, item) or 0
    elseif system == 'ox_inventory' then return exports.ox_inventory:GetItemCount(player, item) or 0
    elseif system == 'ps-inventory' then return exports['ps-inventory']:GetItemCount(player, item) or 0
    elseif system == 'qb-inventory' then return exports['qb-inventory']:GetItemCount(player, item) or 0
    elseif system == 'tgiann-inventory' then return exports['tgiann-inventory']:GetItemCount(player, item) or 0
    end
    return 0
end

exports('AddItem', AddItem)
exports('RemoveItem', RemoveItem)
exports('GetItemCount', GetItemCount)
