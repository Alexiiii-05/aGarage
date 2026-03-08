ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('garage:getVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query('SELECT plate, vehicle, stored FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier}, function(result)
        cb(result)
    end)
end)

RegisterNetEvent('garage:storeVehicle')
AddEventHandler('garage:storeVehicle', function(props)
    local xPlayer = ESX.GetPlayerFromId(source)
    local plate = props.plate
    MySQL.update('UPDATE owned_vehicles SET vehicle = ?, stored = ? WHERE plate = ? AND owner = ?', {json.encode(props),1,plate,xPlayer.identifier})
end)

RegisterNetEvent('garage:setState')
AddEventHandler('garage:setState', function(plate, state)
    MySQL.update('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', {0,plate})
end)

RegisterNetEvent("garage:enterPreview")
AddEventHandler("garage:enterPreview", function()
    SetPlayerRoutingBucket(source, source)
end)

RegisterNetEvent("garage:leavePreview")
AddEventHandler("garage:leavePreview", function()
    SetPlayerRoutingBucket(source, 0)
end)

ESX.RegisterServerCallback("garage:checkOwner", function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query("SELECT owner FROM owned_vehicles WHERE plate = ?",{plate},function(result)
            if result[1] and result[1].owner == xPlayer.identifier then
                cb(true)
            else
                cb(false)
            end
        end
    )
end)

ESX.RegisterServerCallback('aGarage:getPoundVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.query('SELECT * FROM owned_vehicles WHERE owner = ? AND stored = 0', {xPlayer.identifier}, function(result)
        cb(result)
    end)
end)

ESX.RegisterServerCallback('aGarage:getVehicleProps', function(source, cb, plate)
    MySQL.query('SELECT vehicle FROM owned_vehicles WHERE plate = ?', {plate}, function(result)
        if result[1] then
            cb(json.decode(result[1].vehicle))
        end
    end)
end)

RegisterNetEvent("aGarage:payPound")
AddEventHandler("aGarage:payPound", function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local price = Config.Pound.price
    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        MySQL.update('UPDATE owned_vehicles SET stored = 1 WHERE plate = ?', {plate})
        TriggerClientEvent("aGarage:spawnPoundVehicle", src, plate)
    else
        TriggerClientEvent("esx:showNotification", src, "Pas assez d'argent")
    end

end)