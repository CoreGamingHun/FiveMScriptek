ESX = nil
local pizzaJobActive = false
local deliveryBlip = nil
local vehicle = nil
local selectedVehicleModel = nil

local deliveryLocations = {
    {x = 215.76, y = -810.12, z = 30.73},
    {x = 150.21, y = -1030.54, z = 29.33},
    {x = 105.43, y = -1235.32, z = 29.53},
    {x = 55.11, y = -876.65, z = 30.45},
}

local pizzaShopInterior = {x = -1197.5, y = -893.7, z = 14.0, heading = 90.0}

local vehicles = {
    {name = "Bati (motor)", model = "bati"},
    {name = "Panto (autó)", model = "panto"},
    {name = "Faggio (robogó)", model = "faggio"}
}

-- ESX shared objektum betöltése
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local function notify(msg)
    ESX.ShowNotification(msg)
end

local function getRandomDeliveryLocation()
    return deliveryLocations[math.random(#deliveryLocations)]
end

local function PlayPizzaAnim()
    local playerPed = PlayerPedId()
    RequestAnimDict("amb@prop_human_bbq@male@base")
    while not HasAnimDictLoaded("amb@prop_human_bbq@male@base") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "amb@prop_human_bbq@male@base", "base", 8.0, -8.0, 3500, 1, 0, false, false, false)
    Citizen.Wait(3500)
    ClearPedTasks(playerPed)
end

local function OpenVehicleMenu()
    local elements = {}

    for i, v in ipairs(vehicles) do
        table.insert(elements, {label = v.name, value = v.model})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_menu', {
        title = 'Válassz járművet',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        selectedVehicleModel = data.current.value
        notify('Jármű kiválasztva: ' .. data.current.label)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

local function startPizzaJob()
    if pizzaJobActive then
        notify("~r~Már aktív a pizza futár melód!")
        return
    end

    pizzaJobActive = true

    -- Teleportálás pizzéria belső térbe
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, pizzaShopInterior.x, pizzaShopInterior.y, pizzaShopInterior.z)
    SetEntityHeading(playerPed, pizzaShopInterior.heading)
    Citizen.Wait(500)

    -- Animáció pizzafelvevéshez
    PlayPizzaAnim()
    notify("Felvetted a pizzát!")

    -- Jármű spawn
    local model = GetHashKey(selectedVehicleModel or "bati")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    vehicle = CreateVehicle(model, pizzaShopInterior.x + 3, pizzaShopInterior.y, pizzaShopInterior.z, pizzaShopInterior.heading, true, false)
    SetPedIntoVehicle(playerPed, vehicle, -1)
    SetModelAsNoLongerNeeded(model)

    -- Első kiszállítás jelzőpont
    local loc = getRandomDeliveryLocation()
    deliveryBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)
    notify("Menj a kiszállítási pontra!")
end

RegisterCommand('startpizza', function()
    startPizzaJob()
end)

RegisterCommand('selectvehicle', function()
    OpenVehicleMenu()
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

RegisterCommand('stoppizza', function()
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
