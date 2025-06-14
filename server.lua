ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent('pizza:pay')
AddEventHandler('pizza:pay', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', source, "Fizetés: ~g~$" .. amount)
    end
end)
