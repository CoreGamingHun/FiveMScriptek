ESX = nil
local pizzaJobActive = false
local deliveryBlip = nil
local vehicle = nil

local deliveryLocations = {
    {x = 215.76, y = -810.12, z = 30.73},
    {x = 150.21, y = -1030.54, z = 29.33},
    {x = 105.43, y = -1235.32, z = 29.53},
    {x = 55.11, y = -876.65, z = 30.45},
}

local pizzaShop = {x = 248.76, y = -791.12, z = 30.73}

-- ESX shared object lekérése
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function notify(msg)
    ESX.ShowNotification(msg)
end

function getRandomDeliveryLocation()
    return deliveryLocations[math.random(#deliveryLocations)]
end

RegisterCommand("startpizza", function()
    if pizzaJobActive then
        notify("~r~Már aktív a pizza futár melód!")
        return
    end

    local playerPed = PlayerPedId()
    pizzaJobActive = true

    local model = GetHashKey("bati")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    vehicle = CreateVehicle(model, pizzaShop.x + 5, pizzaShop.y, pizzaShop.z, 90.0, true, false)
    SetPedIntoVehicle(playerPed, vehicle, -1)
    SetModelAsNoLongerNeeded(model)

    notify("Pizza futár meló elindult! Vedd fel a pizzát a pizzériánál!")

    local loc = getRandomDeliveryLocation()
    deliveryBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)
    notify("Menj a kiszállítási pontra!")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if pizzaJobActive and deliveryBlip then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local blipCoords = GetBlipCoords(deliveryBlip)
            local distance = #(playerCoords - blipCoords)

            if distance < 10.0 then
                DrawMarker(1, blipCoords.x, blipCoords.y, blipCoords.z - 1.0, 0,0,0,0,0,0,1.5,1.5,1.0, 0,255,0,100, false, true, 2, false, nil, nil, false)

                if distance < 1.5 then
                    notify("Nyomj ~INPUT_CONTEXT~-t (E), hogy leszállítsd a pizzát!")

                    if IsControlJustPressed(0, 38) then
                        RemoveBlip(deliveryBlip)
                        deliveryBlip = nil

                        local pay = math.random(1000, 2000)
                        TriggerServerEvent('pizza:pay', pay)

                        local loc = getRandomDeliveryLocation()
                        deliveryBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
                        SetBlipSprite(deliveryBlip, 1)
                        SetBlipColour(deliveryBlip, 2)
                        SetBlipRoute(deliveryBlip, true)
                        notify("Menj a következő kiszállítási pontra!")
                    end
                end
            end
        end
    end
end)

RegisterCommand("stoppizza", function()
    if pizzaJobActive then
        pizzaJobActive = false

        if deliveryBlip then
            RemoveBlip(deliveryBlip)
            deliveryBlip = nil
        end

        if vehicle then
            DeleteVehicle(vehicle)
            vehicle = nil
        end

        notify("Pizza futár meló befejezve.")
    else
        notify("~r~Nincs aktív pizza futár melód.")
    end
end)
