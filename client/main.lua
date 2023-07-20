-- Variables
RSGCore = exports['rsg-core']:GetCoreObject()

local createdEntries = {}
local PlayerJob = {}
local DutyBlips = {}
local onDuty = false
IsHandcuffed = false
IsEscorted = false

-- Functions
local CreateDutyBlips = function(playerId, playerLabel, playerJob, playerLocation)
    local ped = GetPlayerPed(playerId)
    local blip = GetBlipFromEntity(ped)

    if not DoesBlipExist(blip) then
        if NetworkIsPlayerActive(playerId) then
            blip = Citizen.InvokeNative(0x30822554, ped)
        else
            blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, playerLocation.x, playerLocation.y, playerLocation.z)
        end

        SetBlipSprite(blip, 54149631, 1)
        SetBlipScale(blip, 0.7)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, playerLabel)

        DutyBlips[#DutyBlips + 1] = blip
        createdEntries[#createdEntries + 1] = {type = 'BLIP', handle = blip}
    end

    if GetBlipFromEntity(PlayerPedId()) == blip then
        RemoveBlip(blip)
    end
end

LocalInput = function(text, number)
    AddTextEntry('FMMC_MPM_NA', text)
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", number or 30)

    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0)

        Wait(0)
    end

    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()

        return result
    end
end

-- Events
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    local player = RSGCore.Functions.GetPlayerData()
    PlayerJob = player.job
    onDuty = player.job.onduty
    IsHandcuffed = false

    TriggerServerEvent("RSGCore:Server:SetMetaData", "ishandcuffed", false)
    TriggerServerEvent("police:server:SetHandcuffStatus", false)
    TriggerServerEvent("police:server:UpdateCurrentCops")

    if PlayerJob and PlayerJob.name ~= "police" then
        if DutyBlips then
            for _, v in pairs(DutyBlips) do
                RemoveBlip(v)
            end
        end

        DutyBlips = {}
    end

    if PlayerJob and PlayerJob.name == 'police' then
        CreatePrompts()
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    TriggerServerEvent("police:server:SetHandcuffStatus", false)
    TriggerServerEvent("police:server:UpdateCurrentCops")

    IsHandcuffed = false
    IsEscorted = false
    onDuty = false

    ClearPedTasks(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)

    if DutyBlips then
        for _, v in pairs(DutyBlips) do
            RemoveBlip(v)
        end

        DutyBlips = {}
    end
end)

RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(JobInfo)
    if JobInfo.name == "police" and PlayerJob.name ~= "police" then
        CreatePrompts()

        if JobInfo.onduty then
            TriggerServerEvent("RSGCore:ToggleDuty")

            onDuty = false
        end
    end

    if JobInfo.name ~= "police" then
        if DutyBlips then
            for _, v in pairs(DutyBlips) do
                RemoveBlip(v)
            end
        end

        DutyBlips = {}
    end

    PlayerJob = JobInfo
end)

RegisterNetEvent('police:client:UpdateBlips', function(players)
    if Config.ShowBlips then
        if PlayerJob and (PlayerJob.name == 'police' or PlayerJob.name == 'ambulance') and onDuty then
            if DutyBlips then
                for _, v in pairs(DutyBlips) do
                    RemoveBlip(v)
                end
            end

            DutyBlips = {}

            if players then
                for _, data in pairs(players) do
                    local id = GetPlayerFromServerId(data.source)

                    CreateDutyBlips(id, data.label, data.job, data.location)
                end
            end
        end
    end
end)

RegisterNetEvent('police:client:policeAlert', function(coords, text)
    RSGCore.Functions.Notify(text, 'police')

    local transG = 250
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    local blip2 = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    local blipText = Lang:t('info.blip_text', {value = text})

    SetBlipSprite(blip, -693644997)
    SetBlipSprite(blip2, -184692826)
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_AREA_PULSE'))
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip2, GetHashKey('BLIP_MODIFIER_AREA_PULSE'))
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipText)

    createdEntries[#createdEntries + 1] = {type = 'BLIP', handle = blip}
    createdEntries[#createdEntries + 1] = {type = 'BLIP', handle = blip2}

    while transG ~= 0 do
        Wait(180 * 4)

        transG = transG - 1

        if transG <= 0 then
            for i = 1, #createdEntries do
                if blipEntries[i].type == "BLIP" then
                    RemoveBlip(blipEntries[i].handle)
                end
            end

            transG = 250

            return
        end
    end
end)

RegisterNetEvent('police:client:SendToJail', function(time)
    TriggerServerEvent("police:server:SetHandcuffStatus", false)

    IsHandcuffed = false
    IsEscorted = false

    ClearPedTasks(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)

    TriggerEvent('rsg-prison:client:Enter', time)
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
    end
end)