local QBCore = exports['qb-core']:GetCoreObject()
local isActiveJob = false
local hasPackage = false
local blip = nil
local registeredPeds = {}
local countdown = 0

AddEventHandler('IIB-Delivery:requestJob', function()
    initDelivery()
end)

function initDelivery()
    if isActiveJob then
        print('Currently On A Delivery Job / Complete That First!')
    else
        createPickup()
    end
end

function createPickup()
    isActiveJob = true
    local index = math.random(1, #Config.PickupLocations)
    local data = Config.PickupLocations[index]

    QBCore.Functions.Notify('You have started a delivery, It has been marked on your GPS!', 'success', 5000)

    lib.requestModel(data.pedModel,500)
    local ped = CreatePed(1, data.pedModel, vector3(data.pedCoords.x,data.pedCoords.y,data.pedCoords.z -1), data.pedCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    table.insert(registeredPeds, ped)
    exports['qb-target']:AddTargetEntity(ped, {
            options = { -- This is your options table, in this table all the options will be specified for the target to accept
                { -- This is the first table with options, you can make as many options inside the options table as you want
                    num = 1, -- This is the position number of your option in the list of options in the qb-target context menu (OPTIONAL)
                    icon = 'fas fa-handshake', -- This is the icon that will display next to this trigger option
                    label = 'Pickup Your Delivery?', -- This is the label of this option which you would be able to click on to trigger everything, this has to be a string
                    targeticon = 'fas fa-box', -- This is the icon of the target itself, the icon changes to this when it turns blue on this specific option, this is OPTIONAL
                    action = function(entity) -- This is the action it has to perform, this REPLACES the event and this is OPTIONAL 
                        collectDelivery()
                    end,
                    canInteract = function(entity, distance, data) -- This will check if you can interact with it, this won't show up if it returns false, this is OPTIONAL
                        return true
                    end,
                },
            },
            distance = 2.5, -- This is the distance for you to be at for the target to turn blue, this is in GTA units and has to be a float value
        }
    )

    blipHandleInit(data.pedCoords,data.pickupLabel)
end

function collectDelivery()
    lib.progressCircle({
        duration = 5000,
        label = 'Picking Up The Delivery!',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            combat = true,
        },
        anim = {
            dict = 'random@shop_gunstore',
            clip = '_greeting',
            flag = 17,
        },
    })

    blipHandleDelete()

    QBCore.Functions.Notify('You have got the package, You will get the location shortly, Dont take too long!', 'success', 10000)

    Wait(5000)
    removePeds()
    Wait(5000)
    dropOffPackage()
    countdown = 10
    Citizen.CreateThread(function()
        while countdown > 0 do
            Citizen.Wait(5000)
            if countdown == 1 then 
                cancelJob()
            end
            countdown = countdown - 1
            print("Countdown: " .. countdown)
        end
    end)    
end

function cancelJob()
    QBCore.Functions.Notify('You took too long, The job was cancelled!', 'error', 10000)

    dropCleanup()
end

function dropOffPackage()
    hasPackage = true
    local index = math.random(1, #Config.DropOffLocations)
    local data = Config.DropOffLocations[index]

    QBCore.Functions.Notify('The location is marked on your GPS!', 'success', 5000)

    lib.requestModel(data.pedModel,500)
    local ped = CreatePed(1, data.pedModel, vector3(data.pedCoords.x,data.pedCoords.y,data.pedCoords.z -1), data.pedCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    table.insert(registeredPeds, ped)
    exports['qb-target']:AddTargetEntity(ped, {
            options = { -- This is your options table, in this table all the options will be specified for the target to accept
                { -- This is the first table with options, you can make as many options inside the options table as you want
                    num = 1, -- This is the position number of your option in the list of options in the qb-target context menu (OPTIONAL)
                    icon = 'fas fa-handshake', -- This is the icon that will display next to this trigger option
                    label = 'Drop Off Your Package?', -- This is the label of this option which you would be able to click on to trigger everything, this has to be a string
                    targeticon = 'fas fa-box', -- This is the icon of the target itself, the icon changes to this when it turns blue on this specific option, this is OPTIONAL
                    action = function(entity) -- This is the action it has to perform, this REPLACES the event and this is OPTIONAL 
                        finishDrop()
                    end,
                    canInteract = function(entity, distance, data) -- This will check if you can interact with it, this won't show up if it returns false, this is OPTIONAL
                        return true
                    end,
                },
            },
            distance = 2.5, -- This is the distance for you to be at for the target to turn blue, this is in GTA units and has to be a float value
        }
    )

    blipHandleInit(data.pedCoords,'Drop Off Location')
end

function finishDrop()
    lib.progressCircle({
        duration = 5000,
        label = 'Dropping Off The Delivery!',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            combat = true,
        },
        anim = {
            dict = 'random@shop_gunstore',
            clip = '_greeting',
            flag = 17,
        },
    })

    QBCore.Functions.Notify('You have finished the job!', 'success', 10000)
    TriggerServerEvent('IIB-Delivery:Reward')

    Wait(5000)
    removePeds()
    hasPackage = false
    isActiveJob = false
    countdown = 0
    blipHandleDelete()
end

function dropCleanup()
    blipHandleDelete()
    removePeds()
    hasPackage = false
    isActiveJob = false
    blip = nil
end

function blipHandleInit(location,label)
    blip = AddBlipForCoord(location.xyz)

    SetBlipSprite(blip, 280)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 9)
    SetBlipRoute(blip,  true)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
end

function blipHandleDelete()
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
        blip = nil
    end
end

function removePeds()
    for k,v in pairs(registeredPeds) do
        exports['qb-target']:RemoveTargetEntity(v)
        DeletePed(v)
        registeredPeds = {}
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == 'IIB-Delivery' then
        for k,v in pairs(registeredPeds) do
            exports['qb-target']:RemoveTargetEntity(v)
            DeletePed(v)
            registeredPeds = {}
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    print('Running Cleanup!')
    dropCleanup()
end)