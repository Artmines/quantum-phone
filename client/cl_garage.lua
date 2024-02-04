--[[
    App: Garage
]]

Garage = {}

function Garage.Render()
    local Data = CallbackModule.SendCallback("quantum-phone/server/get-garage-data")
    local PlayerData = PlayerModule.GetPlayerData()
    
    for k, v in pairs(Data) do
        local SharedData = Shared.Vehicles[GetHashKey(v.vehicle)]
        v.Label = SharedData ~= nil and SharedData['Model'] .. ' ' .. SharedData['Name'] or GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle))
        v.Type = SharedData ~= nil and SharedData['Type'] or 'Car'
    end

    exports['quantum-ui']:SendUIMessage("Phone", "RenderGarageApp", {
        Vehicles = Data,
    })
end

RegisterNUICallback("Garage/TrackVehicle", function(Data, Cb)
    local Result = CallbackModule.SendCallback("quantum-vehicles/server/get-vehicle-position", Data.Plate)
    if Result then
        SetWaypointOff()
        Citizen.SetTimeout(500, function()
            SetNewWaypoint(Result[1].x, Result[1].y)
            exports['quantum-ui']:Notify('found', Result[2], "success")
        end)
    else
        exports['quantum-ui']:Notify('not-found', "Can\'t find vehicle..", "error")
    end
    Cb('Ok')
end)