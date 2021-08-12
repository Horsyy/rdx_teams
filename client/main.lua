RDX = nil
Citizen.CreateThread(function()
	while RDX == nil do
		TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)
		Citizen.Wait(10)
	end
end)

AddEventHandler('rdx:onPlayerSpawn', function(data)
	LoadTeam()
	TriggerServerEvent('rdx_teams:forceBlip')
end)

RegisterNetEvent('rdx_teams:LoadTeam')
AddEventHandler('rdx_teams:LoadTeam', function()
	LoadTeam()
	TriggerServerEvent('rdx_teams:forceBlip')
end)

RegisterNetEvent('rdx_teams:RemovedTeam')
AddEventHandler('rdx_teams:RemovedTeam', function()
	SetPedRelationshipGroupHash(PlayerPedId(), GetHashKey("PLAYER"))
end)

RegisterNetEvent('rdx_teams:OpenTeammateRequest')
AddEventHandler('rdx_teams:OpenTeammateRequest', function(src, teamName, sender)
	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'OpenTeammateRequest', {
		title = _U('invite_req', sender, teamName),
		align = 'center',
		elements = {
			{label = 'Reject', value = 'no'},
			{label = 'Accept',  value = 'yes'}
		}
	}, function(data2, menu2)
		if data2.current.value == 'yes' then
			TriggerServerEvent('rdx_teams:AddTeammate', src, GetPlayerServerId(PlayerId()), teamName)
			menu2.close()
		elseif data2.current.value == 'no' then
			RDX.ShowNotification('You rejected the incoming request.')
			menu2.close()
	  	end
	end)
end)

RegisterNetEvent('rdx_teams:Notify')
AddEventHandler('rdx_teams:Notify', function(title, subtitle, opt1 ,opt2, duration)
	exports['LRP_Notify']:DisplayLeftNotification(title, subtitle, opt1, opt2, duration)
end)

if Config.EnableButton then
	Citizen.CreateThread(function()
		while true do
		Citizen.Wait(1)
			if IsControlJustReleased(0, Config.Button) then
				OpenActions()
			end
		end
	end)
end

if Config.EnableCommand then
	RegisterCommand(Config.Command, function(source, args, rawCommand)
		OpenActions()
	end, false)
end

function OpenActions()
	local Data = {}
	local elements = {}
	local teamName

	RDX.TriggerServerCallback("rdx_teams:ParseTeam", function(data) Data = data end, GetPlayerServerId(PlayerId()))
	Citizen.Wait(250)
	for k,v in pairs(Data) do
		if v.isLeader == '1' then
			table.insert(elements, {label = _U('add_member'), value = 'add_member'})
			table.insert(elements, {label = _U('manage_team'), value = 'manage_team'})
			table.insert(elements, {label = _U('delete_team'), value = 'delete_team'})
			teamName = v.team
		else
			table.insert(elements, {label = _U('leave_team'), value = 'leave_team'})
		end
	end
	if json.encode(Data) == '[]' then
		table.insert(elements, {label = _U('create_team'), value = 'create_team'})
	end

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'team_system', {
		title    = _U('team_system'),
		align    = 'left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'add_member' then
			local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()
			if closestPlayer ~= -1 and closestDistance <= 3.0 then
				TriggerServerEvent('rdx_teams:AddTeammateRequest', GetPlayerServerId(closestPlayer), teamName)
			else
				RDX.ShowNotification(_U('nonclose'))
			end
		elseif data.current.value == 'manage_team' then
			TeammatesManagment(teamName)
		elseif data.current.value == 'delete_team' then
			RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'team_deletion', {
				title = 'Are you Sure?',
				align = 'center',
				elements = {
					{label = 'No', value = 'no'},
					{label = 'Yes',  value = 'yes'}
				}
			}, function(data2, menu2)
				if data2.current.value == 'yes' then
					TriggerServerEvent('rdx_teams:DeleteTeam', teamName)
					menu2.close()
					menu.close()
				elseif data2.current.value == 'no' then
					RDX.ShowNotification('You canceled the Team deletion.')
					menu2.close()
				end
			end)
		elseif data.current.value == 'leave_team' then
			TriggerServerEvent('rdx_teams:LeaveTeam')
			SetPedRelationshipGroupHash(PlayerPedId(), GetHashKey("PLAYER"))
		elseif data.current.value == 'create_team' then
			RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'creating_team', {
				title = "Creating a Team",
			}, function (data2, menu2)
				local TeamName = data2.value
				
				if TeamName == nil then
					RDX.ShowNotification(_U('invalid'))
				else
					TriggerServerEvent('rdx_teams:CreateTeam', TeamName)
					menu2.close()
					menu.close()
				end
			end, function (data2, menu2)
				menu2.close()
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function TeammatesManagment(teamName)
	local Data = {}
	local elements = {}
	RDX.TriggerServerCallback("rdx_teams:ParseTeammates", function(data) Data = data end, teamName)
	Citizen.Wait(250)
	for k,v in pairs(Data) do
		if v.isLeader == '0' then
			table.insert(elements, {label = v.name})
		end
	end

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), "TeamManagment",
		{
			title    = 'Manage Team',
			align    = "left",
			elements = elements
		}, function(data, menu)
			RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'TeamOptions', {
					title = 'Team Options',
					align = 'left',
					elements = {
						{label = _U('remove_member'), value = 'remove_member'}
					}
				}, function(data2, menu2)
				if data2.current.value == 'remove_member' then
					TriggerServerEvent('rdx_teams:RemoveTeammate', data.current.label)
					menu2.close()
					menu.close()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
	end, function(data, menu)
		menu.close()
	end)
end

function LoadTeam()
	local Data = {}
	RDX.TriggerServerCallback("rdx_teams:getTeammates", function(data) Data = data end)
	Citizen.Wait(250)
	for k,v in pairs(Data) do
		id, hash = AddRelationshipGroup(v.team)
		SetPedRelationshipGroupHash(PlayerPedId(), hash)
		SetRelationshipBetweenGroups (1, hash, hash)
		print(GetPedRelationshipGroupHash(PlayerPedId()))
		TriggerEvent('rdx_teams:Notify', _U('team_system'), _U('current_team', v.team), 'toast_log_blips', 'blip_ambient_gang_leader', 10000)
	end
end

--------------------------------------------------------------
------------------------- TEAM BLIPS -------------------------
--------------------------------------------------------------

TeamBlips = {}

function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Add blip and create head display on player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.85) -- set scale

		table.insert(TeamBlips, blip) -- add blip to array so we can remove it later
	end
end

RegisterNetEvent('rdx_teams:updateBlip')
AddEventHandler('rdx_teams:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(TeamBlips) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	TeamBlips = {}

	if not Config.EnableTeamBlips then
		return
	end

	RDX.TriggerServerCallback('rdx_society:getOnlinePlayers', function(players)
		for i=1, #players, 1 do
			local id = GetPlayerFromServerId(players[i].source)
			if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
				if GetPedRelationshipGroupHash(PlayerPedId()) == GetPedRelationshipGroupHash(GetPlayerPed(id)) then
					--Citizen.InvokeNative(0x23f74c2fda6e7c61, -1749618580, GetPlayerPed(id)) -- https://pastebin.com/raw/iHshvCe1
					createBlip(id)
				end
			end
		end
	end)
end)


--[[
function showBlips()
	RDX.TriggerServerCallback('rdx_society:getOnlinePlayers', function(players)
		for i=1, #players, 1 do
			local id = GetPlayerFromServerId(players[i].source)
			if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
				if GetPedRelationshipGroupHash(PlayerPedId()) == GetPedRelationshipGroupHash(GetPlayerPed(id)) then
					Citizen.InvokeNative(0x23f74c2fda6e7c61, -1749618580, GetPlayerPed(id)) -- https://pastebin.com/raw/iHshvCe1
				end
			end
		end
	end)
end
]]

--[[
local MPTagTeam = 0

Citizen.CreateThread(function()
	while true do
	Citizen.Wait(50)
		local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 10.0 and GetPlayerFromServerId(closestPlayer) ~= PlayerId() then
			MPTagTeam = Citizen.InvokeNative(0xE961BF23EAB76B12, GetPlayerPed(GetPlayerServerId(closestPlayer)), GetPlayerName(GetPlayerServerId(closestPlayer))) -- CreateMpGamerTagOnEntity
			Citizen.InvokeNative(0x5F57522BC1EB9D9D, MPTagTeam, "PLAYER_HORSE") -- SetMpGamerTagTopIcon
			Citizen.InvokeNative(0xA0D7CE5F83259663, MPTagTeam, " ") -- SetMpGamerTagBigText
			Citizen.InvokeNative(0x93171DDDAB274EB8, MPTagTeam, 2) -- SetMpGamerTagVisibility
		else
			if Citizen.InvokeNative(0x6E1C31E14C7A5F97, MPTagTeam) then
				Citizen.InvokeNative(0x93171DDDAB274EB8, MPTagTeam, 0) -- SetMpGamerTagVisibility
			end
		end
	end
end)
]]