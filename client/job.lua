local RSGCore = exports['rsg-core']:GetCoreObject()

-- Variables
local PlayerJob = {}
local createdEntries = {}
local currentGarage = 1
local onDuty = false

local TakeOutVehicle = function(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]

    RSGCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetEntityHeading(veh, coords.w)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        Citizen.InvokeNative(0x400F9556,veh, Lang:t('info.police_plate')..tostring(math.random(1000, 9999)))
        SetVehicleEngineOn(veh, true, true)
    end, coords, true)
end

local MenuGarage = function()
    local vehicleMenu =
    {
        {
            header = Lang:t('menu.garage_title'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[RSGCore.Functions.GetPlayerData().job.grade.level]

    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu+1] =
        {
            header = label,
            txt = "",
            params =
            {
                event = "police:client:TakeOutVehicle",
                args =
                {
                    vehicle = veh
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu+1] =
    {
        header = Lang:t('menu.close'),
        txt = "",
        params =
        {
            event = "rsg-menu:client:closeMenu"
        }

    }

    exports['rsg-menu']:openMenu(vehicleMenu)
end

CreatePrompts = function()
    for k, v in pairs(Config.Locations['duty']) do
        exports['rsg-core']:createPrompt('duty_prompt_'..k, v, RSGCore.Shared.Keybinds['J'], 'Toggle duty status',
        {
            type = 'client',
            event = 'rsg-policejob:ToggleDuty'
        })

        createdEntries[#createdEntries + 1] = {type = 'PROMPT', handle = 'duty_prompt_'..k}
    end

    for k, v in pairs(Config.Locations["vehicle"]) do
        exports['rsg-core']:createPrompt("police:vehicle_"..k, vector3(v.x, v.y, v.z), RSGCore.Shared.Keybinds['R'], 'Jobgarage',
        {
            type = 'client',
            event = 'police:client:promptVehicle',
            args = {k}
        })

        createdEntries[#createdEntries + 1] = {type = 'PROMPT', handle = "police:vehicle_"..k}
    end

    for k, v in pairs(Config.Locations['evidence']) do
        exports['rsg-core']:createPrompt('evidence_prompt_'..k, v, RSGCore.Shared.Keybinds['J'], 'Open Evidence Stash',
        {
            type = 'client',
            event = 'police:client:EvidenceStashDrawer',
            args = {k}
        })

        createdEntries[#createdEntries + 1] = {type = 'PROMPT', handle = 'evidence_prompt_'..k}
    end

    for k, v in pairs(Config.Locations['stash']) do
        exports['rsg-core']:createPrompt('stash_prompt_'..k, v, RSGCore.Shared.Keybinds['J'], 'Open Personal Stash',
        {
            type = 'client',
            event = 'police:client:OpenPersonalStash'
        })

        createdEntries[#createdEntries + 1] = {type = 'PROMPT', handle = 'stash_prompt_'..k}
    end

    for k, v in pairs(Config.Locations['armory']) do
        exports['rsg-core']:createPrompt('armory_prompt_'..k, v, RSGCore.Shared.Keybinds['J'], 'Open Armory',
        {
            type = 'client',
            event = 'police:client:OpenArmory'
        })

        createdEntries[#createdEntries + 1] = {type = 'PROMPT', handle = 'armory_prompt_'..k}
    end
end


local SetWeaponSeries = function()
    for k, _ in pairs(Config.Items.items) do
        if k < 6 then
            Config.Items.items[k].info.serie = tostring(RSGCore.Shared.RandomInt(2)..RSGCore.Shared.RandomStr(3)..
                RSGCore.Shared.RandomInt(1)..RSGCore.Shared.RandomStr(2)..RSGCore.Shared.RandomInt(3)..RSGCore.Shared.RandomStr(4))
        end
    end
end

AddEventHandler('police:client:promptVehicle', function(k)
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        local ped = PlayerPedId()

        if PlayerJob.name == "police"  then
            if IsPedInAnyVehicle(ped, false) then
                RSGCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped))
            else
                MenuGarage()

                currentGarage = k
            end
        else
            RSGCore.Functions.Notify(Lang:t('error.not_lawyer'), 'error')
        end
    end)
end)

AddEventHandler('police:client:CheckStatus', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.name == "police" then
            local player, distance = RSGCore.Functions.GetClosestPlayer()

            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)

                RSGCore.Functions.TriggerCallback('police:GetPlayerStatus', function(result)
                    if result then
                        for _, v in pairs(result) do
                            RSGCore.Functions.Notify(''..v..'', 'primary')
                        end
                    end
                end, playerId)
            else
                RSGCore.Functions.Notify(Lang:t("error.none_nearby"), 'error')
            end
        end
    end)
end)

AddEventHandler('police:client:EvidenceStashDrawer', function(k)
    local currentEvidence = k
    local pos = GetEntityCoords(PlayerPedId())
    local takeLoc = Config.Locations["evidence"][currentEvidence]

    if not takeLoc then return end

    if #(pos - takeLoc) <= 1.0 then
        local drawer = LocalInput(Lang:t('info.slot'), 11)

        if tonumber(drawer) then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer}),
            {
                maxweight = 4000000,
                slots = 500,
            })

            TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer}))
        end
    end
end)

-- Toggle Duty in an event.
AddEventHandler('rsg-policejob:ToggleDuty', function()
    onDuty = not onDuty

    TriggerServerEvent("police:server:UpdateCurrentCops")
    TriggerServerEvent("RSGCore:ToggleDuty")
end)

AddEventHandler('police:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle

    TakeOutVehicle(vehicle)
end)

AddEventHandler('police:client:OpenPersonalStash', function()
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..RSGCore.Functions.GetPlayerData().citizenid)
    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..RSGCore.Functions.GetPlayerData().citizenid)
end)

AddEventHandler('police:client:OpenArmory', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.name == "police" then
            local authorizedItems =
            {
                label = Lang:t('menu.pol_armory'),
                slots = 30,
                items = {}
            }

            local index = 1

            for _ , armoryItem in pairs(Config.Items.items) do
                for i = 1, #armoryItem.authorizedJobGrades do
                    if armoryItem.authorizedJobGrades[i] == PlayerData.job.grade.level then
                        authorizedItems.items[index] = armoryItem
                        authorizedItems.items[index].slot = index
                        index = index + 1
                    end
                end
            end

            SetWeaponSeries()

            TriggerServerEvent("inventory:server:OpenInventory", "shop", "police", authorizedItems)
        else
            RSGCore.Functions.Notify('law enforcement only', 'error')
        end
    end)
end)

-- Toggle Duty
CreateThread(function()
    if LocalPlayer.state.isLoggedIn and PlayerJob.name == 'police' then
        CreatePrompts()
    end

    for _, v in pairs(Config.Locations["stations"]) do
        local StationBlip = N_0x554d9d53f696d002(1664425300, v.coords)

        SetBlipSprite(StationBlip, -693644997)
        SetBlipScale(StationBlip, 0.7)
        Citizen.InvokeNative(0x9CB1A1623062F402, StationBlip, v.label)

        createdEntries[#createdEntries + 1] = {type = 'BLIP', handle = StationBlip}
    end

    for _, v in pairs(RSGCore.Shared.Weapons) do
        local weaponName = v.name
        local weaponLabel = v.label
        local weaponHash = GetHashKey(v.name)
        local weaponAmmo, weaponAmmoLabel = nil, 'unknown'

        if v.ammotype then
            weaponAmmo = v.ammotype:lower()
            weaponAmmoLabel = RSGCore.Shared.Items[weaponAmmo].label
        end

        Config.WeaponHashes[weaponHash] =
        {
            weaponName = weaponName,
            weaponLabel = weaponLabel,
            weaponAmmo = weaponAmmo,
            weaponAmmoLabel = weaponAmmoLabel
        }
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for i = 1, #createdEntries do
        if createdEntries[i].type == 'BLIP' then
            if createdEntries[i].handle then
                RemoveBlip(createdEntries[i].handle)
            end
        end

        if createdEntries[i].type == 'PROMPT' then
            if createdEntries[i].handle then
                exports['rsg-core']:deletePrompt(createdEntries[i].handle)
            end
        end
    end
end)