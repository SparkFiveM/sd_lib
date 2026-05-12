
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

function GetInventoryImagePath()
    local system = GetInventorySystem()
    if system == 'codem-inventory' then return "nui://codem-inventory/html/itemimages/"
    elseif system == 'jpr-inventory' then return "nui://jpr-inventory/html/images/"
    elseif system == 'lj-inventory' then return "nui://lj-inventory/html/images/"
    elseif system == 'origen_inventory' then return "nui://origen_inventory/html/images/"
    elseif system == 'ox_inventory' then return "nui://ox_inventory/web/images/"
    elseif system == 'ps-inventory' then return "nui://ps-inventory/html/images/"
    elseif system == 'qb-inventory' then return "nui://qb-inventory/html/images/"
    elseif system == 'tgiann-inventory' then return "nui://tgiann-inventory/inventory_images/images/"
    end
    return ""
end

function GetItemCount(item)
    local system = GetInventorySystem()
    if (system == 'ox_inventory' or system == 'ps-inventory') and GetResourceState('ox_inventory') ~= 'missing' then
        return exports.ox_inventory:Search('count', item)
    end
    return 0
end

exports('GetInventoryImagePath', GetInventoryImagePath)
exports('GetItemCount', GetItemCount)
