taxiVehicle = nil
taxiPed = nil

RegisterCommand('taxi', function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local vehicleName = GetHashKey('taxi')
    local taxiDriver = GetHashKey('s_m_o_busker_01')
    local Px, Py, Pz = table.unpack(GetEntityCoords(playerPed))

    RequestModel(vehicleName)
    RequestModel(taxiDriver)

    while not HasModelLoaded(vehicleName) and not HasModelLoaded(taxiDriver) do
        Wait(200)
    end

    local _, vector = GetNthClosestVehicleNode(x, y, z, math.random(5, 10), 0, 0, 0)
    local sX, sY, sZ = table.unpack(vector)

    taxiVehicle = CreateVehicle(vehicleName, sX, sY, sZ, 0, true, false)
    SetEntityAsMissionEntity(taxiVehicle, true, true)
    SetVehicleEngineOn(taxiVehicle, true, true, false)

    taxiPed = CreatePedInsideVehicle(taxiVehicle, 26, taxiDriver, -1, true, false)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
	SetEntityAsMissionEntity(taxiPed, true, true)

    SetPedVehicleForcedSeatUsage(playerPed, vehicle, 1, 33)
    -- SetPlayerResetFlagPreferRearSeats(playerPed, {1,2})

    local blip = AddBlipForEntity(taxiVeh)
    SetBlipSprite(blip, 198)
    SetBlipFlashes(blip, true)
    SetBlipFlashTimer(blip, 5000)
    
    TaskVehicleDriveToCoord(taxiPed, taxiVehicle, Px, Py, Pz, 26.0, 0, GetEntityModel(taxiVehicle), 411, 10.0)
    SetPedKeepTask(driver, true)

    -- SetEntityAsNoLongerNeeded(taxiVehicle)
    -- SetModelAsNoLongerNeeded(vehicleName)
    -- SetEntityAsNoLongerNeeded(taxiPed)
    -- SetModelAsNoLongerNeeded(taxiDriver)

    TriggerEvent('chat:addMessage', {
		args = { 'A taxi is on the way!' }
	})
end, false)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        if not DoesEntityExist(taxiVehicle) then
            if not IsPedInAnyVehicle(playerPed, false) or not IsPedInAnyTaxi(playerPed) then
                if IsControlJustPressed(0, 168) then
                end
            end
        else
            Px, Py, Pz = table.unpack(GetEntityCoords(playerPed))
            vehX, vehY, vehZ = table.unpack(GetEntityCoords(taxiVeh))
            DistanceBetweenTaxi = GetDistanceBetweenCoords(Px, Py, Pz, vehX, vehY, vehZ, true)
            if DistanceBetweenTaxi <= 20.0 then
                if not IsPedInAnyVehicle(playerPed, false) then
                    if IsControlJustPressed(0, 23) then
                        TaskEnterVehicle(playerPed, taxiVeh, -1, 2, 1.0, 1, 0)
                        PlayerEntersTaxi = true
                        TaxiInfoTimer = GetGameTimer()
                    end
                end
            end
        end
    end
end, false)
