fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'rsg-policejob'
version '1.0.0'

shared_scripts
{
    'config.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua' -- Change this to your preferred language
}

client_scripts
{
    'client/main.lua',
    'client/interactions.lua',
    'client/job.lua'
}

server_scripts
{
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}