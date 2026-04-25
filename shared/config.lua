Config = {}

---[[====[ SYSTEM CONFIGURATION ]====]]
Config.Framework = 'auto' -- 'auto', 'qb', 'qbx', 'esx'
Config.VoiceSystem = 'pma-voice' -- 'pma-voice', 'saltychat'

---[[====[ INVENTORY SYSTEM SETTINGS ]====]]
Config.Inventory = {
    System = 'auto', -- 'auto', 'ox_inventory', 'qb-inventory', 'ps-inventory', 'tgiann-inventory', 'codem-inventory' 'jpr-inventory', 'origen_inventory', 'lj-inventory'
}

---[[====[ INTERACTION SYSTEM SETTINGS ]====]]
Config.Interaction = {
    System = 'auto', -- 'auto', 'lunar_bridge', 'ox_target', 'qb-target', 'textui', 'drawtext'
    DefaultDistance = 2.0
}

---[[====[ NOTIFICATION SYSTEM SETTINGS ]====]]
Config.Notification = {
    System = 'auto', -- 'auto', 'sd_notify', 'ox_lib', 'qb-core', 'vms_notify', 'es_extended', 'mythic_notify', 'okok'
    DefaultDuration = 5000
}

---[[====[ PROGRESS SYSTEM SETTINGS ]====]]
Config.Progress = {
    System = 'auto', -- 'auto', 'ox_lib', 'qb-core', 'progressbar'
    DefaultDuration = 5000
}

---[[====[ TEXTUI SYSTEM SETTINGS ]====]]
Config.TextUI = {
    System = 'auto', -- 'auto', 'ox_lib', 'qb-core', 'esx', 'okok', 'native'
    DefaultPosition = 'bottom-center',
    DefaultDuration = 5000
}

---[[====[ DISPATCH SYSTEM SETTINGS ]====]]
Config.Dispatch = {
    System = 'auto', -- 'auto', 'sd_dispatch', 'rcore_dispatch', 'lb-tablet', 'origen_police', 'l2s-dispatch', 'dusa-dispatch', 'redutzu-mdt', 'cd_dispatch/3d', 'ps-dispatch', 'core_dispatch', 'wasabi_mdt'
    DefaultDistance = 2.0
}

---[[====[ SKILLCHECK SYSTEM SETTINGS ]====]]
Config.Skillcheck = {
    System = 'auto' -- 'auto', 'ox_lib', 'bl_ui', 'ps-ui/ps_lib'
}

---[[====[ DIALOG SYSTEM SETTINGS ]====]]
Config.Dialog = {
    System = 'auto' -- 'auto', 'ox_lib', 'qb-input', 'esx_menu_dialog', 'native'
}

---[[====[ ZONE SYSTEM SETTINGS ]====]]
Config.Zones = {
    System = 'auto' -- 'auto', 'ox_lib', 'polyzone'
}