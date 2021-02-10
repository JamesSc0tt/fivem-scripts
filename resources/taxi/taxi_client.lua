taxi = nil
taxiPed = nil
taxiHailed = false
inTaxi = false
taxiBlip = nil

RegisterCommand('taxi', function()
    taxiHailed = true
    

    -- SetPedVehicleForcedSeatUsage(playerPed, vehicle, 1, 33)
    -- SetPlayerResetFlagPreferRearSeats(playerPed, {1,2})
    
    


    -- These need to be set after the taxi arrives
    -- SetEntityAsNoLongerNeeded(taxi)
    -- SetModelAsNoLongerNeeded(vehicleName)
    -- SetEntityAsNoLongerNeeded(taxiPed)
    -- SetModelAsNoLongerNeeded(taxiDriver)

    TriggerEvent('chat:addMessage', {
		args = { 'A taxi is on the way!' }
	})
end)

function spawnTaxi()
    local vehicleName = GetHashKey('taxi')
    local taxiDriver = GetHashKey('s_m_o_busker_01')
    local playerPed = PlayerPedId()
    local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
    local _, vector = GetNthClosestVehicleNode(pX, pY, pZ, math.random(5, 10), 0, 0, 0)
    local sX, sY, sZ = table.unpack(vector)

    RequestModel(vehicleName)
    RequestModel(taxiDriver)

    while not HasModelLoaded(vehicleName) and not HasModelLoaded(taxiDriver) do
        Wait(200)
    end

    taxi = CreateVehicle(vehicleName, sX, sY, sZ, 0, true, false)
    SetEntityAsMissionEntity(taxi, true, true)
    SetVehicleEngineOn(taxi, true, true, false)
    SetVehicleUndriveable(taxi, true)

    taxiPed = CreatePedInsideVehicle(taxi, 26, taxiDriver, -1, true, false)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    SetEntityAsMissionEntity(taxiPed, true, true)
    TaskVehicleDriveToCoord(taxiPed, taxi, pX, pY, pZ, 26.0, 0, GetEntityModel(taxi), 411, 10.0)
end

CreateThread(function()
    while true do
        Wait(0)
        if taxiHailed then
            local playerPed = PlayerPedId()
            local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))

            spawnTaxi()
            
            if taxiBlip == nil then
                local blip = AddBlipForEntity(taxi)
                SetBlipSprite(blip, 198)
                SetBlipFlashes(blip, true)
                SetBlipFlashTimer(blip, 5000)
                SetBlipDisplay(blip, 4)
                SetBlipScale  (blip, 0.75)
                SetBlipColour (blip, 2)
                SetBlipAsShortRange(blip, false)
            end

            -- if not DoesEntityExist(taxi) then
            --     if not IsPedInAnyVehicle(playerPed, false) or not IsPedInAnyTaxi(playerPed) then
            --         if IsControlJustPressed(0, 168) then
            --         end
            --     end
            -- else
                pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
                vX, vY, vZ = table.unpack(GetEntityCoords(taxi))
                local DistanceBetweenTaxi = GetDistanceBetweenCoords(pX, pY, pZ, vX, vY, vZ, true)
                if DistanceBetweenTaxi <= 20.0 then
                    if not IsPedInAnyVehicle(playerPed, false) then
                        if IsControlJustPressed(0, 23) then
                            TaskEnterVehicle(playerPed, taxi, -1, 2, 1.0, 1, 0)
                            inTaxi = true
                            TaxiInfoTimer = GetGameTimer()
                        end
                    end
                end
            -- end
        else
            Wait(1000)
        end
    end
end)
