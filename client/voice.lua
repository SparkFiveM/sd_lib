
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
            return LocalPlayer.state.radioTalking or false
        end
        
    elseif system == 'saltychat' then
        if GetResourceState('saltychat') ~= 'missing' then
            return exports.saltychat:GetRadioSpeaker() or false
        end
    end
    return false
end

exports('GetRadioChannel', GetRadioChannel)
exports('IsUsingRadio', IsUsingRadio)
