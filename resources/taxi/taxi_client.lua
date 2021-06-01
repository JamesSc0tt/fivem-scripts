taxi = nil
taxiPed = nil
taxiHailed = false
hasEntered = false
taxiBlip = nil

AddEventHandler('taxi:hail', function()
    taxiHailed = true

    TriggerEvent('chat:addMessage', {
		args = { 'A taxi is on the way!' }
	})
end)

function spawnTaxi()
    local vehicleName = GetHashKey('taxi')
    local taxiDriver = GetHashKey('s_m_o_busker_01')
    local playerPed = PlayerPedId()
    local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
    local _, vector = GetNthClosestVehicleNode(pX, pY, pZ, math.random(50, 100), 0, 0, 0)
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
    -- TaskVehicleDriveToCoord(taxiPed, taxi, pX, pY, pZ, 15.0, 1.0, GetEntityModel(taxi), 786603, 3.0, true)
    -- TaskVehicleMissionPedTarget(taxiPed, taxi, playerPed, 22, 26.0, 786603, 5.0, 1.0, false)
    -- TaskVehicleParktaxiPed, taxi()
    driveToAsTaxi(taxiPed, taxi, GetEntityCoords(playerPed))
    -- TaskVehicleMissionCoorsTarget(taxiPed, taxi, rX, rY, rZ, 22, 26.0, 786603, 5.0, 1.0, false)
end

function driveToAsTaxi(ped, veh, destination)
    local dX, dY, dZ = table.unpack(destination)
    local _, roadSide = GetPointOnRoadSide(dX, dY, dZ, 1)
    local x, y, z = table.unpack(roadSide)
    TaskVehicleMissionCoorsTarget(ped, veh, x, y, z, 22, 100.0, 786603, 1.0, 1.0, false)
end

function endTransport(ped, veh, destination)
    RemoveBlip(taxiBlip)
    ClearVehicleTasks(veh)
    ClearPedTasks(taxiPed)
    Wait(3000)
    TaskVehicleDriveWander(taxiPed, taxi, 26.0, 786603)
    taxi = nil
    taxiPed = nil
    taxiHailed = false
    hasEntered = false
    taxiBlip = nil
    destination = nil
end

CreateThread(function()
    local destination = nil
    while true do
        Wait(0)
        if taxiHailed then
            local playerPed = PlayerPedId()
            local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))

            if taxi == nil then
                spawnTaxi()
            end
            
            if taxiBlip == nil then
                taxiBlip = AddBlipForEntity(taxi)
                SetBlipSprite(taxiBlip, 198)
                SetBlipFlashes(taxiBlip, true)
                SetBlipFlashTimer(taxiBlip, 5000)
                SetBlipDisplay(taxiBlip, 4)
                SetBlipScale  (taxiBlip, 0.75)
                SetBlipColour (taxiBlip, 2)
                SetBlipAsShortRange(taxiBlip, false)
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
                    end
                    -- can player cancel entering or do i need to specifically look for controls?
                else
                    -- wait for waypoint before driving
                    -- while waypoint == nil do
                    -- end
                    -- get waypoint coords
                        -- local waypoint = {x,y,z}
                        -- if waypoint
                        -- TaskVehicleDriveToCoord(taxiPed, taxi, waypoint.x, waypoint.y, waypoint.z, 26.0, 0, GetEntityModel(taxi), 411, 10.0)
                    -- drive to waypoint
                    -- check for change in waypoint
                    -- wait for player to get out
                    -- drive off and remove entity stuff
                    -- end
                end
            end
            if IsPedSittingInVehicle(playerPed, taxi) then
                hasEntered = true
                -- check for waypoint change
                if DoesBlipExist(GetFirstBlipInfoId(8)) then
                    -- get waypoint
                    local wp = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                    -- check for waypoint change
                    if wp ~= nil and wp ~= destination then
                        destination = wp
                        driveToAsTaxi(taxiPed, taxi, wp)
                        -- is a normal wait better here?
                        Wait(1000)
                    end
                end
            end
            if hasEntered and not IsPedSittingInVehicle(playerPed, taxi) then
                endTransport(taxiPed, taxi, destination)
            end
        else
            Wait(5000)
        end
    end
end)
