fx_version "adamant"
games {"rdr3"}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Horse#0001'
description 'RDX Teams'
version '1.1.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@redm_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@redm_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua'
}