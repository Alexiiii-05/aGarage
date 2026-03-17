ESX = exports["es_extended"]:getSharedObject()
local arrowColors = {"~r~",  "~o~",  "~y~",  "~g~",  "~c~",  "~b~",  "~p~",  "~m~",  "~w~",}
local arrowIndex = 1
local previewVehicle = nil
local previewCam = nil
local selectedVehicleData = nil
local currentGarage = nil
local open = false
local fourriere = false
local GarageMenu = RageUI.CreateMenu("Garage", "Vos véhicules")
local ConfirmMenu = RageUI.CreateSubMenu(GarageMenu, "Véhicule", "Actions")
local FourriereMenu = RageUI.CreateMenu("Fourrière", "Vos véhicules")
FourriereMenu:SetRectangleBanner(255, 140, 0, 255)

GarageMenu.Closed = function()

    open = false

    if previewVehicle then
        DeleteEntity(previewVehicle)
        DeletePreviewCam()
        previewVehicle = nil
        selectedVehicleData = nil
    end

end

CreateThread(function()
    while true do
        arrowIndex = arrowIndex + 1
        if arrowIndex > #arrowColors then arrowIndex = 1 end
        Wait(500)
    end
end)

function AnimatedArrow()
    return arrowColors[arrowIndex]
end

function SpawnVehicleFromPound(props)
    local spawn = Config.Pound.spawnPos
    ESX.Game.SpawnVehicle(props.model, vector3(spawn.x,spawn.y,spawn.z), spawn.w, function(vehicle)
        ESX.Game.SetVehicleProperties(vehicle, props)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end


function OpenGarageMenu()
    if open then return end
    open = true

    ESX.TriggerServerCallback('garage:getVehicles', function(vehicles)

local cachedVehicles = {}

for k,v in pairs(vehicles) do
    local props = json.decode(v.vehicle)
    local name = GetLabelText(GetDisplayNameFromVehicleModel(props.model))

    table.insert(cachedVehicles, {
        data = v,
        name = name,
        plate = v.plate,
        stored = v.stored
    })
end

        RageUI.Visible(GarageMenu, true)

        CreateThread(function()
            while open do
                local wait = 500

                if RageUI.Visible(GarageMenu) or RageUI.Visible(ConfirmMenu) then
                    wait = 1
                end

                Wait(wait)

                RageUI.IsVisible(GarageMenu, function()
                    if #vehicles == 0 then
                        RageUI.Separator("")RageUI.Separator(AnimatedArrow().."Garage vide")RageUI.Separator("")
                    end
                    local availableVehicles = 0
                    for k,v in pairs(cachedVehicles) do
                        if v.stored == 1 then
                            availableVehicles = availableVehicles + 1
                        end
                    end

                    RageUI.Separator(AnimatedArrow().."→ ~s~ véhicule disponible (~g~ "..availableVehicles.."~s~ )")
                
                    for k,v in pairs(cachedVehicles) do
                        local stored = v.stored == 1
                        local vehicleName = v.name
                        local plate = v.plate
                        vehicleName = vehicleName.."~s~ [~o~"..plate.."~s~]"
                        if v.stored == 0 then
                            vehicleName = "~r~"..vehicleName
                        end

                        RageUI.Button(AnimatedArrow().."→ ~s~"..vehicleName,stored and "Voir le véhicule" or "~r~Véhicule déjà sorti",{},stored,{
                            onSelected = function()
                                selectedVehicleData = v.data
                                if previewVehicle and DoesEntityExist(previewVehicle) then
                                    DeleteEntity(previewVehicle)
                                    previewVehicle = nil
                                end
                                PreviewVehicle(v.data)
                            end
                        },stored and ConfirmMenu or nil)
                    end

                end)

                RageUI.IsVisible(ConfirmMenu, function()
                    if previewVehicle then
                        RageUI.Button(AnimatedArrow().."→ ~s~Sortir le véhicule", nil, {}, true, {
                            onSelected = function()

                                DeletePreviewCam()

                                if previewVehicle and DoesEntityExist(previewVehicle) then
                                    DeleteEntity(previewVehicle)
                                    previewVehicle = nil
                                end

                                SpawnVehicle(selectedVehicleData)

                                selectedVehicleData = nil
                                RageUI.CloseAll()
                                open = false

                            end
                        })

                        RageUI.Button("~r~Annuler", nil, {}, true, {
                            onSelected = function()
                                DeleteEntity(previewVehicle)
                                DeletePreviewCam()
                                previewVehicle = nil
                                selectedVehicleData = nil
                                RageUI.GoBack()
                            end
                        })
                    end
                end)
            end
        end)
    end)
end


function OpenPoundMenu()
    if fourriere then return end
    fourriere = true
    ESX.TriggerServerCallback('aGarage:getPoundVehicles', function(vehicles)
        RageUI.Visible(FourriereMenu, true)
        CreateThread(function()
            while fourriere do
                Wait(0)

                RageUI.IsVisible(FourriereMenu, function()
                    for k,v in pairs(vehicles) do
                        local props = json.decode(v.vehicle)
                        local name = GetLabelText(GetDisplayNameFromVehicleModel(props.model))

                        RageUI.Button(AnimatedArrow().."→ ~s~"..name.." [~p~"..v.plate.."~s~]",nil,{RightLabel = "~r~"..Config.Pound.price.." ~s~$"}, true, {
                            onSelected = function()
                                TriggerServerEvent("aGarage:payPound", v.plate)
                                    RageUI.CloseAll()
                                    fourriere = false
                            end
                        })
                    end
                end)
                if not RageUI.Visible(FourriereMenu) then
                    fourriere = false
                end
            end
        end)

    end)
end

function SpawnVehicle(data)
    local spawn = currentGarage.spawnPos
    local props = json.decode(data.vehicle)
    if not props or not props.model then
        print("Erreur modèle véhicule")
        return
    end
    local vehicle = GetClosestVehicle(spawn.x, spawn.y, spawn.z, 3.0, 0, 70)
    if DoesEntityExist(vehicle) then
        ESX.ShowNotification("~r~Le point de sortie est bloqué")
        return
    end
    local model = props.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local veh = CreateVehicle(model,spawn.x,spawn.y,spawn.z,spawn.w,true,true)
    SetVehicleOnGroundProperly(veh)
    ESX.Game.SetVehicleProperties(veh, props)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    TriggerServerEvent("garage:setState", data.plate, false)

end

function StoreVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local props = ESX.Game.GetVehicleProperties(vehicle)
    ESX.TriggerServerCallback("garage:checkOwner", function(isOwner)
        if isOwner then
            TriggerServerEvent("garage:storeVehicle", props)
            ESX.Game.DeleteVehicle(vehicle)
            ESX.ShowNotification("Véhicule rangé dans le garage")
        else
            ESX.ShowNotification("~r~Ce véhicule ne vous appartient pas")
        end
    end, props.plate)
end

function PreviewVehicle(data)
    local props = json.decode(data.vehicle)
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end

    local model = props.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    previewVehicle = CreateVehicle(model,currentGarage.previewPos.x,currentGarage.previewPos.y,currentGarage.previewPos.z,currentGarage.previewPos.w,false,true)
    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetEntityAlpha(previewVehicle, 180, false)
    ESX.Game.SetVehicleProperties(previewVehicle, props)
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    SetEntityInvincible(previewVehicle, true)
    SetEntityCollision(previewVehicle, false, false)
    selectedVehicleData = data
    CreatePreviewCam(previewVehicle)
end

function CreatePreviewCam(vehicle)
    local coords = GetEntityCoords(vehicle)
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, coords.x + 3.0, coords.y + 3.0, coords.z + 1.5)
    PointCamAtEntity(previewCam, vehicle)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 1000, true, true)
end

function DeletePreviewCam()
    if previewCam then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(previewCam)
        previewCam = nil
    end
end

CreateThread(function()
    while true do
        local wait = 750
        local pCoords = GetEntityCoords(PlayerPedId())
        for k,v in pairs(Config.Garages) do
            if #(pCoords - vector3(v.menuPos.x, v.menuPos.y, v.menuPos.z)) < 10.0 then
                wait = 0
                DrawMarker(22, v.menuPos.x, v.menuPos.y, v.menuPos.z,0.0,0.0,0.0,0.0,0.0,0.0,0.7,0.7,0.7,62,255,100,150,
                true,true,2,false,nil,nil,false)
                if #(pCoords - vector3(v.menuPos.x, v.menuPos.y, v.menuPos.z)) < 2.0 then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le garage")

                    if IsControlJustPressed(0,51) then
                        currentGarage = v
                        OpenGarageMenu()
                    end
                end
            end
            if #(pCoords - vector3(v.storePos.x, v.storePos.y, v.storePos.z)) < 20.0 then
                wait = 0
                DrawMarker(36,v.storePos.x, v.storePos.y, v.storePos.z - 1.0,0.0,0.0,0.0,0.0,0.0,0.0,1.2,1.2,1.2,255,50,50,150,false,true,2,false,nil,nil,false)

                if #(pCoords - vector3(v.storePos.x, v.storePos.y, v.storePos.z)) < 3.0 then
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger votre véhicule")

                        if IsControlJustPressed(0,51) then
                            StoreVehicle()
                        end
                    end
                end
            end
        end
        local pound = Config.Pound
        if #(pCoords - pound.menuPos) < 10.0 then
            wait = 0
            DrawMarker(22,pound.menuPos.x, pound.menuPos.y, pound.menuPos.z - 1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.7,0.7,0.7,255,140,0,150,true,true,2,false,nil,nil,false)
            if #(pCoords - pound.menuPos) < 2.0 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder à la fourrière")
                if IsControlJustPressed(0,51) then
                    OpenPoundMenu()
                end
            end
        end
        Wait(wait)
    end
end)


RegisterNetEvent("aGarage:spawnPoundVehicle")
AddEventHandler("aGarage:spawnPoundVehicle", function(plate)
    ESX.TriggerServerCallback('aGarage:getVehicleProps', function(props)
        local spawn = Config.Pound.spawnPos
        ESX.Game.SpawnVehicle(props.model, vector3(spawn.x, spawn.y, spawn.z), spawn.w, function(vehicle)
            ESX.Game.SetVehicleProperties(vehicle, props)
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        end)
    end, plate)
end)
