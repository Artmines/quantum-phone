fx_version 'cerulean'
game 'gta5'

author 'Quantum Core'
description 'Phone'

client_script {
    '@quantum-assets/client/cl_errorlog.lua',
    '@quantum-base/shared/sh_shared.lua',
    'config/sh_*.lua',
    'client/*.lua',
}

server_script {
    '@quantum-assets/server/sv_errorlog.lua',
    '@quantum-base/shared/sh_shared.lua',
    'config/sh_*.lua',
    'config/sv_*.lua',
    'server/*.lua',
}

lua54 'yes'