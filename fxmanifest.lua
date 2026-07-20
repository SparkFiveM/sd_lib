fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Spark Developments'
description 'Framework Library'
version '1.0.3'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua'
}
client_scripts {
    'client/framework.lua',
    'client/inventory.lua',
    'client/textui.lua',
    'client/progress.lua',
    'client/notifications.lua',
    'client/dispatch.lua',
    'client/skill.lua',
    'client/dialog.lua',
    'client/interaction.lua',
    'client/zones.lua',
    'client/callbacks.lua',
    'client/voice.lua',
    'client/main.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/inventory.lua',
    'server/callbacks.lua',
    'server/main.lua'
}