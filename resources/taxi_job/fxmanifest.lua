
fx_version 'cerulean'
game 'gta5'

author 'P2'
description 'A version of a taxi job for the players to make money'
version '1.0.0'

resource_type 'gameplay' { name = 'Taxi Job' }
ui_page 'nui/taxi_job_nui.html'

client_scripts {
    'taxi_job_client.lua',
    'config.lua'
}

server_scripts {
    'taxi_job_server.lua',
    'config.lua'
}

files {
    'nui/taxi_job_nui.html',
    'nui/taxi_job_style.css',
    'nui/taxi_job_listener.js'
}
