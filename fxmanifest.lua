fx_version 'cerulean'
game 'gta5'

author 'DebellaMartin'
description 'ESX Pizza futár meló menüs járműválasztással és pizzéria belső animációval'
version '1.0.0'

client_scripts {
    'client.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- ha nincs, töröld ki
    'server.lua',
}
