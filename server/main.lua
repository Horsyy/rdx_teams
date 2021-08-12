RDX = nil
TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)

RegisterNetEvent('rdx_teams:AddTeammateRequest')
AddEventHandler('rdx_teams:AddTeammateRequest', function(playerId, teamName)
	local xPlayer = RDX.GetPlayerFromId(source)
	local xTarget = RDX.GetPlayerFromId(playerId)
	xTarget.triggerEvent('rdx_teams:OpenTeammateRequest', source, teamName, xPlayer.getName())
end)

RegisterServerEvent('rdx_teams:CreateTeam')
AddEventHandler('rdx_teams:CreateTeam', function(teamName)
	local xPlayer = RDX.GetPlayerFromId(source)
	local identifier = xPlayer.getIdentifier()
	MySQL.Async.fetchAll('SELECT * FROM rdx_teams WHERE identifier = @identifier', {['@identifier'] = identifier}, function(data)
		if next(data) == nil then
			MySQL.Async.execute('INSERT INTO rdx_teams (identifier, name, team, isLeader) VALUES (@identifier, @name, @team, @isLeader)', {
				['@identifier'] = identifier,
				['@name'] = xPlayer.getName(),
				['@team'] = teamName,
				['@isLeader'] = true
			})
			xPlayer.triggerEvent('rdx_teams:Notify', _U('team_system'), _('created_team', teamName), 'toast_log_blips', 'blip_ambient_gang_leader', 10000)
			xPlayer.triggerEvent('rdx_teams:LoadTeam')
		else
			xPlayer.showNotification(_U('ownteam'))
		end
	end)
end)

RegisterServerEvent('rdx_teams:DeleteTeam')
AddEventHandler('rdx_teams:DeleteTeam', function(teamName)
	local xPlayer = RDX.GetPlayerFromId(source)
	MySQL.Async.execute("DELETE FROM rdx_teams WHERE team = @team", {['@team'] = teamName})
	xPlayer.triggerEvent('rdx_teams:Notify', _U('team_system'), _U('team_deletion'), 'toast_log_blips', 'blip_ambient_gang_leader', 10000)
end)

RegisterServerEvent('rdx_teams:AddTeammate')
AddEventHandler('rdx_teams:AddTeammate', function(src, player, teamName)
	local xPlayer = RDX.GetPlayerFromId(src)
	local xTarget = RDX.GetPlayerFromId(player)
	local identifier = xTarget.getIdentifier()
	MySQL.Async.fetchAll('SELECT * FROM rdx_teams WHERE identifier = @identifier', {['@identifier'] = identifier}, function(data)
		if next(data) == nil then
			MySQL.Async.execute('INSERT INTO rdx_teams (identifier, name, team, isLeader) VALUES (@identifier, @name, @team, @isLeader)', {
				['@identifier'] = identifier,
				['@name'] = xTarget.getName(),
				['@team'] = teamName,
				['@isLeader'] = false
			})
			xPlayer.triggerEvent('rdx_teams:Notify', _U('team_system'), _U('member_join', xTarget.getName()), 'toast_challenges_weaponexpert', 'challenge_weapons_expert_8', 10000)
			xTarget.triggerEvent('rdx_teams:LoadTeam')
		else
			xPlayer.showNotification(_U('exists'))
		end
	end)
end)

RegisterServerEvent('rdx_teams:RemoveTeammate')
AddEventHandler('rdx_teams:RemoveTeammate', function(name)
	local xPlayer = RDX.GetPlayerFromId(source)
	MySQL.Async.execute("DELETE FROM rdx_teams WHERE name = @name", {['@name'] = name})
	xPlayer.triggerEvent('rdx_teams:Notify', _U('team_system'), _U('member_removed', name), 'toast_challenges_weaponexpert', 'challenge_weapons_expert_8', 10000)
	for k,v in pairs(GetPlayers()) do
		local xTarget = RDX.GetPlayerFromId(v)
		PlayerName = xTarget.getName()
		if PlayerName == name then
			xTarget.triggerEvent('rdx_teams:RemovedTeam')
			xTarget.triggerEvent('rdx_teams:Notify', _U('team_system'), _('removed_by', xPlayer.getName()), 'toast_log_blips', 'blip_ambient_gang_leader', 10000)
		end
	end
end)

RegisterServerEvent('rdx_teams:LeaveTeam')
AddEventHandler('rdx_teams:LeaveTeam', function(name)
	local xPlayer = RDX.GetPlayerFromId(source)
	MySQL.Async.execute("DELETE FROM rdx_teams WHERE name = @name", {['@name'] = xPlayer.getName()})
	xPlayer.triggerEvent('rdx_teams:Notify', _U('team_system'), _U('left_team'), 'toast_log_blips', 'blip_ambient_gang_leader', 10000)
end)


RDX.RegisterServerCallback("rdx_teams:ParseTeam", function(source, cb, playerID)
	local xPlayer = RDX.GetPlayerFromId(playerID)
	local identifier = xPlayer.getIdentifier()
	MySQL.Async.fetchAll('SELECT * FROM rdx_teams WHERE identifier = @identifier', {['@identifier'] = identifier}, function(data)
		cb(data)
	end)
end)

RDX.RegisterServerCallback("rdx_teams:ParseTeammates", function(source, cb, teamName)
	local xPlayer = RDX.GetPlayerFromId(source)
	local identifier = xPlayer.getIdentifier()
	MySQL.Async.fetchAll('SELECT * FROM rdx_teams WHERE team = @team', {['@team'] = teamName}, function(data)
		cb(data)
	end)
end)

RDX.RegisterServerCallback("rdx_teams:getTeammates", function(source, cb)
	local xPlayer = RDX.GetPlayerFromId(source)
	local identifier = xPlayer.getIdentifier()
	MySQL.Async.fetchAll('SELECT * FROM rdx_teams WHERE identifier = @identifier', {['@identifier'] = identifier}, function(data)
		cb(data)
	end)
end)



--------------------------------------------------------------
------------------------- TEAM BLIPS -------------------------
--------------------------------------------------------------

if Config.EnableTeamBlips then
	AddEventHandler('playerDropped', function()
		local playerId = source
		if playerId then
			Citizen.Wait(5000)
			TriggerClientEvent('rdx_teams:updateBlip', -1)
		end
	end)

	RegisterNetEvent('rdx_teams:forceBlip')
	AddEventHandler('rdx_teams:forceBlip', function()
		TriggerClientEvent('rdx_teams:updateBlip', -1)
	end)

	AddEventHandler('onResourceStart', function(resource)
		if resource == GetCurrentResourceName() then
			Citizen.Wait(5000)
			TriggerClientEvent('rdx_teams:updateBlip', -1)
		end
	end)
end