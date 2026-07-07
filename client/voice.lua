local lastRadioState = false

function GetRadioChannel()
    local system = Config.VoiceSystem
    
    if system == 'pma-voice' then
        if GetResourceState('pma-voice') ~= 'missing' then
            return LocalPlayer.state.radioChannel or 0
        end
        
    elseif system == 'saltychat' then
        if GetResourceState('saltychat') ~= 'missing' then
            return exports.saltychat:GetRadioChannel(true) or 0
        end
    end
    return 0
end

function IsUsingRadio()
    local system = Config.VoiceSystem
    
    if system == 'pma-voice' then
        if GetResourceState('pma-voice') ~= 'missing' then
            return lastRadioState
        end
        
    elseif system == 'saltychat' then
        if GetResourceState('saltychat') ~= 'missing' then
            return lastRadioState
        end
    end
    return false
end

local function SetRadioState(isUsingRadio)
    isUsingRadio = isUsingRadio == true

    if lastRadioState == isUsingRadio then
        return
    end

    lastRadioState = isUsingRadio
    TriggerEvent('sd_lib:radioStateChanged', isUsingRadio)
end

RegisterNetEvent('pma-voice:radioActive', function(isUsingRadio)
    if Config.VoiceSystem == 'pma-voice' then
        SetRadioState(isUsingRadio)
    end
end)

RegisterNetEvent('SaltyChat_RadioTrafficStateChanged', function(_primaryReceive, primaryTransmit, _secondaryReceive, secondaryTransmit)
    if Config.VoiceSystem == 'saltychat' then
        SetRadioState(primaryTransmit == true or secondaryTransmit == true)
    end
end)

CreateThread(function()
    if Config.VoiceSystem == 'pma-voice' and GetResourceState('pma-voice') ~= 'missing' then
        lastRadioState = LocalPlayer.state.radioTalking == true

        AddStateBagChangeHandler('radioTalking', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
            SetRadioState(value)
        end)
    end
end)

exports('GetRadioChannel', GetRadioChannel)
exports('IsUsingRadio', IsUsingRadio)
