local Config = Config or {}

local function GetDialogSystem()
    local system = Config.Dialog.System
    if system == 'auto' then
        if GetResourceState('ox_lib') ~= 'missing' then return 'ox_lib'
        elseif GetResourceState('qb-input') ~= 'missing' then return 'qb-input'
        elseif GetResourceState('esx_menu_dialog') ~= 'missing' then return 'esx_menu_dialog'
        else return 'native' end
    end
    return system
end

function ShowDialog(header, inputs, callback)
    local system = GetDialogSystem()
    
    if system == 'esx_menu_dialog' then
        if GetResourceState('esx_menu_dialog') ~= 'missing' then
             local elements = {}
             for _, input in ipairs(inputs) do
                 table.insert(elements, {label = input.label, type = input.type})
             end
             ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'native_dialog', {
                 title = header,
                 elements = elements
             }, function(data, menu)
                 if callback then callback(data.current.value) end
                 menu.close()
             end, function(data, menu)
                 menu.close()
             end)
        end
        
    elseif system == 'native' then
        AddTextEntry('FMMC_KEY_TIP1', header)
        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", "", "", "", "", 32)
        while UpdateOnscreenKeyboard() == 0 do
            Wait(0)
        end
        if GetOnscreenKeyboardResult() then
            if callback then callback({input = GetOnscreenKeyboardResult()}) end
        end
        
    elseif system == 'ox_lib' then
        if GetResourceState('ox_lib') ~= 'missing' and lib and lib.inputDialog then
            local dialog = lib.inputDialog(header, inputs)
            if callback then callback(dialog) end
        end
        
    elseif system == 'qb-input' then
        if GetResourceState('qb-input') ~= 'missing' then
            local dialog = exports['qb-input']:ShowInput({
                header = header,
                submitText = "Submit",
                inputs = inputs
            })
            if callback then callback(dialog) end
        end
    end
end

function CloseDialog()
    local system = GetDialogSystem()
    if system == 'esx_menu_dialog' then
        ESX.UI.Menu.CloseAll()
    elseif system == 'ox_lib' and lib and lib.closeInputDialog then
        lib.closeInputDialog()
    end
end

exports('ShowDialog', ShowDialog)
exports('CloseDialog', CloseDialog)
