fx_version 'cerulean'
game 'gta5'

author 'ChatGPT'
description 'Pizza futár meló ESX-hez'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- ha van mysql és adatbázis, vagy törölhető
    'server.lua'
}
