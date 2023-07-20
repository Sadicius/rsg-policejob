local RSGCore = exports['rsg-core']:GetCoreObject()

-- Variables
local PlayerStatus = {}

-- Functions
local UpdateBlips = function()
    local dutyPlayers = {}
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v and (v.PlayerData.job.name == "police" or v.PlayerData.job.name == "ambulance") and v.PlayerData.job.onduty then
            local coords = GetEntityCoords(GetPlayerPed(v.PlayerData.source))
            local heading = GetEntityHeading(GetPlayerPed(v.PlayerData.source))

            dutyPlayers[#dutyPlayers + 1] =
            {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata["callsign"],
                job = v.PlayerData.job.name,
                location =
                {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    w = heading
                }
            }
        end
    end

    TriggerClientEvent("police:client:UpdateBlips", -1, dutyPlayers)
end

local GetCurrentCops = function()
    local amount = 0
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end

    return amount
end

-- Commands
RSGCore.Commands.Add("cuff", Lang:t("commands.cuff_player"), {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:CuffPlayer", src)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

RSGCore.Commands.Add("escort", Lang:t("commands.escort"), {}, false, function(source, args)
    local src = source

    TriggerClientEvent("police:client:EscortPlayer", src)
end)

RSGCore.Commands.Add("callsign", Lang:t("commands.callsign"), {{name = "name", help = Lang:t('info.callsign_name')}}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    Player.Functions.SetMetaData("callsign", table.concat(args, " "))
end)

RSGCore.Commands.Add("jail", Lang:t("commands.jail_player"), {{name = "id", help = Lang:t('info.player_id')}, {name = "time", help = Lang:t('info.jail_time')}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
        local playerId = tonumber(args[1])
        local time = tonumber(args[2])

        if time > 0 then
            TriggerClientEvent("police:client:JailCommand", src, playerId, time)
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('info.jail_time_no'), 'primary')
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

RSGCore.Commands.Add("unjail", Lang:t("commands.unjail_player"), {{name = "id", help = Lang:t('info.player_id')}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
        local playerId = tonumber(args[1])

        TriggerClientEvent("prison:client:UnjailPerson", playerId)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

RSGCore.Commands.Add("seizecash", Lang:t("commands.seizecash"), {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:SeizeCash", src)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

RSGCore.Commands.Add("sc", Lang:t("commands.softcuff"), {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
        TriggerClientEvent("police:client:CuffPlayerSoft", src)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.on_duty_police_only"), 'error')
    end
end)

-- Usable Items
RSGCore.Functions.CreateUseableItem("handcuffs", function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.Functions.GetItemByName(item.name) then
        TriggerClientEvent("police:client:CuffPlayerSoft", src)
    end
end)

-- Callbacks
RSGCore.Functions.CreateCallback('police:GetPlayerStatus', function(source, cb, playerId)
    local Player = RSGCore.Functions.GetPlayer(playerId)
    local statList = {}

    if Player then
        if PlayerStatus[Player.PlayerData.source] and next(PlayerStatus[Player.PlayerData.source]) then
            for k, _ in pairs(PlayerStatus[Player.PlayerData.source]) do
                statList[#statList + 1] = PlayerStatus[Player.PlayerData.source][k].text
            end
        end
    end

    cb(statList)
end)

RSGCore.Functions.CreateCallback('police:GetCops', function(source, cb)
    local amount = 0
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end

    cb(amount)
end)

RSGCore.Functions.CreateCallback('police:server:GetSuspectHorse', function(source, cb, id)
    local Player = RSGCore.Functions.GetPlayer(id)

    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active',
    {
        citizenid = citizenid,
        active = 1
    })

    if not result[1] then return end

    cb(result[1])
end)

-- Events
RegisterNetEvent('police:server:policeAlert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'police' and v.PlayerData.job.onduty then
            TriggerClientEvent('police:client:policeAlert', v.PlayerData.source, coords, text)
        end
    end
end)

RegisterNetEvent('police:server:CuffPlayer', function(playerId, isSoftcuff)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local CuffedPlayer = RSGCore.Functions.GetPlayer(playerId)

    if not CuffedPlayer then return end

    if Player.Functions.GetItemByName("handcuffs") or Player.PlayerData.job.name == "police" then
        TriggerClientEvent("police:client:GetCuffed", CuffedPlayer.PlayerData.source, Player.PlayerData.source, isSoftcuff)
    end
end)

RegisterNetEvent('police:server:EscortPlayer', function(playerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    local EscortPlayer = RSGCore.Functions.GetPlayer(playerId)

    if not EscortPlayer then return end

    if (Player.PlayerData.job.name == "police" or Player.PlayerData.job.name == "ambulance")
    or (EscortPlayer.PlayerData.metadata["ishandcuffed"] or EscortPlayer.PlayerData.metadata["isdead"]
    or EscortPlayer.PlayerData.metadata["inlaststand"])
    then
        TriggerClientEvent("police:client:GetEscorted", EscortPlayer.PlayerData.source, Player.PlayerData.source)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t("error.not_cuffed_dead"), 'error')
    end
end)

RegisterNetEvent('police:server:JailPlayer', function(playerId, time)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local OtherPlayer = RSGCore.Functions.GetPlayer(playerId)
    local currentDate = os.date("*t")

    if currentDate.day == 31 then
        currentDate.day = 30
    end

    if Player.PlayerData.job.name ~= "police" or not OtherPlayer then return end

    OtherPlayer.Functions.SetMetaData("injail", time)
    OtherPlayer.Functions.SetMetaData("criminalrecord",
    {
        ["hasRecord"] = true,
        ["date"] = currentDate
    })

    TriggerClientEvent("police:client:SendToJail", OtherPlayer.PlayerData.source, time)
    TriggerClientEvent('RSGCore:Notify', src, Lang:t("info.sent_jail_for", {time = time}), 'primary')
end)

RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    Player.Functions.SetMetaData("ishandcuffed", isHandcuffed)
end)

RegisterNetEvent('police:server:SearchPlayer', function(playerId)
    local src = source
    local SearchedPlayer = RSGCore.Functions.GetPlayer(playerId)

    if not SearchedPlayer then return end

    TriggerClientEvent('RSGCore:Notify', src, Lang:t("info.cash_found", {cash = SearchedPlayer.PlayerData.money["cash"]}), 'primary')
    TriggerClientEvent('RSGCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.being_searched"), 'primary')
end)

RegisterNetEvent('police:server:SeizeCash', function(playerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local SearchedPlayer = RSGCore.Functions.GetPlayer(playerId)

    if not SearchedPlayer then return end

    local moneyAmount = SearchedPlayer.PlayerData.money["cash"]
    local info = {cash = moneyAmount}

    if SearchedPlayer.Functions.RemoveMoney("cash", moneyAmount, "police-cash-seized") then
        Player.Functions.AddItem("moneybag", 1, false, info)

        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items["moneybag"], "add")
        TriggerClientEvent('RSGCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.cash_confiscated"), 5000, 0, 'blips', 'blip_radius_search', 'COLOR_WHITE')
    end
end)

RegisterNetEvent('police:server:RobPlayer', function(playerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local SearchedPlayer = RSGCore.Functions.GetPlayer(playerId)

    if not SearchedPlayer then return end

    local money = SearchedPlayer.PlayerData.money["cash"]

    if SearchedPlayer.Functions.RemoveMoney("cash", money, "police-player-robbed") then
        Player.Functions.AddMoney("cash", money, "police-player-robbed")

        TriggerClientEvent('RSGCore:Notify', SearchedPlayer.PlayerData.source, Lang:t("info.cash_robbed", {money = money}), 5000, 0, 'blips', 'blip_radius_search', 'COLOR_WHITE')
        TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, Lang:t("info.stolen_money", {stolen = money}), 5000, 0, 'blips', 'blip_radius_search', 'COLOR_WHITE')
    end
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    local src = source
    PlayerStatus[src] = data
end)

RegisterNetEvent('police:server:UpdateCurrentCops', function()
    local amount = 0
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end

    TriggerClientEvent("police:SetCopCount", -1, amount)
end)

-- Threads
CreateThread(function()
    while true do
        Wait(1000 * 60 * 10)

        local curCops = GetCurrentCops()

        TriggerClientEvent("police:SetCopCount", -1, curCops)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)

        UpdateBlips()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CreateThread(function()
            MySQL.Async.execute("DELETE FROM stashitems WHERE stash='policetrash'")
        end)
    end
end)