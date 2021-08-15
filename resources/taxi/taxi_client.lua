taxiHailed = false
hasEntered = false
hasArrivedForPickup = false
taxiBlip = nil
destination = nil
circle = nil
carModel = 'taxi'

function log(args)
    Citizen.Trace(args .. '\n')
end

AddEventHandler('taxi:hail', function()
    if taxiHailed then
        endTransport()
    end
    taxiHailed = true

    TriggerEvent('chat:addMessage', {
		args = { 'A taxi is on the way!' }
	})
end)

RegisterNetEvent("taxi:callAI")
AddEventHandler('taxi:callAI', function()
    StartAiTaxi()
end)

AddEventHandler('taxi:cancel', function()
    endTransport()
end)

-- TODO: move to utils file
function GetGroundZCoord(x, y)
    for h = 1, 1000 do
        local foundGround, z = GetGroundZFor_3dCoord(x, y, h + 0.0)

        if foundGround then
            TriggerEvent('chat:addMessage', {
                args = { 'meow ' .. x .. ', ' .. y .. ', ' .. h + 0.0  }
            })
            return vector3(x, y, h + 0.0)
        end

        Wait(5)
    end
end

-- might be good to put in utils and pass in vehicle model and ped model as well
function SpawnTaxi(coords)
    -- different ped?
    local taxiDriver = 's_m_o_busker_01'
    local vector, h = GetTaxiSpawnPoint(coords)
    local sX, sY, sZ = table.unpack(vector)

    RequestModel(carModel)
    while not HasModelLoaded(carModel) do
        Wait(0)
    end

    local taxi = CreateVehicle(carModel, sX, sY, sZ, h, true, false)
    SetEntityInvincible(taxi, true)
    SetVehicleOnGroundProperly(taxi)

    RequestModel(taxiDriver)
    while not HasModelLoaded(taxiDriver) do 
        Wait(0)
    end

    local taxiPed = CreatePedInsideVehicle(taxi, 4, taxiDriver, -1, true, false)
    SetModelAsNoLongerNeeded(carModel)
    SetModelAsNoLongerNeeded(taxiDriver)
    Citizen.Wait(1000)
    SetEntityInvincible(taskveh, false) 

    return taxi, taxiPed
end

-- move to utils to use for any vehicle spawn?
function GetTaxiSpawnPoint(coords)
    while true do
        local _, spawn, h = GetNthClosestVehicleNode(coords.x, coords.y, coords.z, math.random(80, 100), 0, 100.0, 2.5)
        if spawn.z ~= 0.0 then
            local nearVehicle = GetClosestVehicle(spawn.x, spawn.y, spawn.z, 20.000, 0, 70)
            if not DoesEntityExist(nearVehicle) then
                return spawn, h
            end
        end
        Wait(1000)
    end
end

function GetTaxiDropOffPoint(coords)
    while true do
        local _, drop, h = GetClosestVehicleNode(coords.x, coords.y, coords.z, 0, 100.0, 2.5)
        if drop.z ~= 0.0 then
            local nearVehicle = GetClosestVehicle(drop.x, drop.y, drop.z, 20.000, 0, 70)
            if not DoesEntityExist(nearVehicle) then
                return drop, h
            end
        end
        Wait(1000)
    end
end

-- failed experiment because driveways are considered roads and medians are roadsides
-- TODO: remove
function CalculateRoadsideCoords(dest)
    local dX, dY, dZ = table.unpack(dest)
    local _, rs = GetPointOnRoadSide(dX, dY, dZ, 0)
    local _, node = GetClosestVehicleNode(dX, dY, dZ, 0, 3.0, 0)

    local x, y = rs.x, rs.y
    local m = (node.y - y)/(node.x - x)
    local b = y - (m*x)
    
    local timer = GetGameTimer()
    local counter = 0

    Citizen.Trace('PlayerCoord is ' .. rs .. '\n')
    Citizen.Trace('VehicleNode is ' .. node .. '\n')
    Citizen.Trace('slope is ' .. m .. '\n')
    Citizen.Trace('y-intersect is ' .. b .. '\n')
    -- Citizen.Trace('IsPointOnRoad ' .. IsPointOnRoad(x, y, dest1.z) .. '\n')

    while not IsPointOnRoad(x, y, rs.z) and GetGameTimer() < timer + 5000 do
        y = m*x + b
        x = x + 0.1
        counter = counter + 1
        Wait(1)
    end

    Citizen.Trace('point on road is ' .. x .. ' ' .. y .. ' ' .. rs.z .. '\n')
    Citizen.Trace('Time calculated ' .. counter .. '\n')

    return vector3(x, y, rs.z)
end

-- TODO: remove
function PickUpFare(ped, veh, dest)
    circle = dest
    TriggerEvent('chat:addMessage', {
		args = { 'Pick up at ' .. dest.x .. ', ' .. dest.y .. ', ' .. dest.z  }
	})
    TaskVehicleDriveToCoord(ped, veh, dest.x, dest.y, dest.z, 8.0, 1, carModel, 786603, 15.0, true)
    SetPedKeepTask(ped, true)
end

-- TODO: remove
function DriveToAsTaxi(ped, veh, dest)
    -- local roadSide = CalculateRoadsideCoords(dest)
    -- local r1, r2, roadSide, r4, r5, r6 = GetClosestRoad(dX, dY, dZ, 1.0, 0, false)
    -- groundZCoord = GetGroundZCoord(dest)
    local x, y, z = table.unpack(dest)
    local _, drop = GetNthClosestVehicleNodeFavourDirection(x, y, z, x, y, z, 3, 1, 0x40400000, 0)
    local dx, dy, dz = table.unpack(drop)
    circle = drop
    
    -- Citizen.Trace(r1 .. '\n')
    -- Citizen.Trace(r2 .. '\n')
    -- Citizen.Trace(roadSide .. '\n')
    -- Citizen.Trace(r4 .. '\n')
    -- Citizen.Trace(r5 .. '\n')
    -- Citizen.Trace(r6 .. '\n')
    TriggerEvent('chat:addMessage', {
		args = { 'drop off at ' .. x .. ', ' .. y .. ', ' .. z  }
	})
    TriggerEvent('chat:addMessage', {
		args = { 'closest vnode ' .. dx .. ', ' .. dy .. ', ' .. dz  }
	})
    TaskVehicleDriveToCoordLongrange(ped, veh, dx, dy, dz, 14.0, 786603, 55.0)
    SetPedKeepTask(ped, true)

    -- while distance > whatever
    -- 
    -- local taskSeq = 0
    -- OpenSequenceTask(taskSeq)
    -- TaskVehicleDriveToCoordLongrange(0, veh, x, y, z, 20.0, 786468, 500.0)
    -- TaskVehicleDriveToCoord(0, veh, x, y, z, 20.0, 5.0, veh, 786468, 20.0, true)
    -- TaskVehicleDriveToCoord(0, veh, x, y, z, 10.0, 5.0, veh, 786468, 3.0, true)
    -- -- TaskVehiclePark(0, veh, x, x, z, GetEntityHeading(veh), 0, 20.0, true)
    -- -- TaskVehicleMissionCoorsTarget(ped, veh, x, y, z, 22, 10.0, 786468, 1.0, 2.0, false)
    -- -- TaskVehicleTempAction(0, taxi, 21, 2000)
    -- -- TaskVehicleTempAction(0, taxi, 27, 10000)
    -- CloseSequenceTask(taskSeq)
    
    -- TaskPerformSequence(ped, taskSeq)
    -- SetPedKeepTask(ped, true)
    -- ClearSequenceTask(taskSeq)
end

function EndTransport()
    Wait(2000)
    RemoveBlip(taxiBlip)
    SetPedKeepTask(taxiPed, false)
    SetPedAsNoLongerNeeded(taxi)
    SetVehicleAsNoLongerNeeded(taxiPed)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    SetPedKeepTask(taxiPed, true)
    TaskVehicleDriveWander(taxiPed, taxi, 10.0, 786603)
    taxi = nil
    taxiPed = nil
    taxiHailed = false
    hasEntered = false
    hasArrivedForPickup = false
    taxiBlip = nil
    destination = nil
end

function StartAiTaxi()
    local playerPed = PlayerPedId()
    local pcoords = GetEntityCoords(playerPed)
    local dcoords = vector3(-900.0, -900.0, -900.0)
    local count = 400000
    local inTaxi = false
    local enroute = false
    SetWaypointOff()
    -- spawn
    local taxi, taxiPed = SpawnTaxi(pcoords) -- switch to use returned values instead of globals
    log('taxi spawned at ' .. pcoords)

    circle = pcoords
    TriggerEvent('chat:addMessage', {
        args = { 'Pick up at ' .. pcoords.x .. ', ' .. pcoords.y .. ', ' .. pcoords.z  }
    })
    TaskVehicleDriveToCoord(taxiPed, taxi, pcoords.x, pcoords.y, pcoords.z, 10.0, 1, carModel, 786603, 10.0, true)
    SetPedKeepTask(taxiPed, true)
    -- pick up
    while count > 0 and not IsPedDeadOrDying(taxiPed, true) and DoesEntityExist(taxiPed) do
        Wait(1)
        count = count - 1
        
        if not enroute and GetVehiclePedIsIn(playerPed, false) ~= taxi then
            local distanceToTaxi = #(GetEntityCoords(taxi) - GetEntityCoords(playerPed))
            -- only using for testing pick up location\
            if not hasArrivedForPickup then
                if circle.x ~= nil then
                    DrawMarker(1, circle.x, circle.y, circle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                5.0, 5.0, 2.0, 204, 204, 0, 100,
                                false, false, 2, false, nil, nil, false)
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

                if distanceToTaxi < 10.0 then
                    hasArrivedForPickup = true
                    log('arrived' .. GetGameTimer())
                end
            end
                
            if distanceToTaxi < 25.0 then
                -- SetVehicleForwardSpeed(taxi, math.ceil(GetEntitySpeed(taxi)*0.75 ))
                TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
            end

            if distanceToTaxi < 10.0 then
                if not IsPedInAnyVehicle(playerPed, false) and IsControlJustPressed(0,23) then
                    -- experiment with SetVehicleExclusiveDriver_2 instead
                    TaskEnterVehicle(playerPed, taxi, -1, 2, 1.0, 1, 0)
                end
            end
        end

        if GetVehiclePedIsIn(playerPed, false) == taxi then
            Wait(1000)
            log(count)

            if IsControlJustPressed(0,23) and inTaxi then
                log('got out')
                count = 0
                if GetEntitySpeed > 1.0 then
                    -- SetVehicleForwardSpeed(taxi, math.ceil(GetEntitySpeed(taxi)*0.75 ))
                    TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
                end
            end

            if not inTaxi then
                inTaxi = true
                log('got in')
                RemoveBlip(taxiBlip)
                -- remove blips
            end

            if not enroute and IsWaypointActive() then
                local waypoint = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                enroute = true
                dcoords = GetTaxiDropOffPoint(waypoint)
                log(dcoords)
                TaskVehicleDriveToCoordLongrange(taxiPed, taxi, dcoords.x, dcoords.y, dcoords.z, 28.0, 786603, 55.0)
                SetPedKeepTask(taxiPed, true) 
            end

            if enroute then
                local endDist = #(GetEntityCoords(taxi) - dcoords)
                
                if endDist < 150.0 or count < 100 then

                    while GetEntitySpeed(taxi) > 1.0 and endDist > 10.0 do
                        endDist = #(GetEntityCoords(taxi) - dcoords)
                        Wait(1000)
                    end
    
                    while GetEntitySpeed(taxi) > 1.0 do
                        TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
                        Wait(1)
                    end

                    SetPedKeepTask(taxiPed, false)
                    SetPedAsNoLongerNeeded(taxiPed)         
                    SetVehicleAsNoLongerNeeded(taxi)
                    FreezeEntityPosition(taxi,true)
                    Citizen.Wait(1000)

                    SetBlockingOfNonTemporaryEvents(taxiPed, true)      
                    SetPedKeepTask(taxiPed, true) 
                    
				    FreezeEntityPosition(taxi,false)
                    TaskVehicleDriveWander(taxiPed, taxi, 10.0, 786603)
                    count = 0
                    log('taxi should leave ' .. count)
                end

                if not IsWaypointActive() then
                    enroute = false
                end
            end
        else
            inTaxi = false
        end
    end
    log('taxi task finished ' .. count)
    -- reset everything
    inTaxi = false
    SetPedKeepTask(taxiPed, false)
    SetPedAsNoLongerNeeded(taxiPed)         
    SetVehicleAsNoLongerNeeded(taxi)
    taxi = nil
    taxiPed = nil
end

CreateThread(function() -- move everything out into above function. Doesn't need to be a thread that always runs
    while true do
        Wait(1)
        if taxiHailed then
            local playerPed = PlayerPedId()
            local pcoords = GetEntityCoords(playerPed)
            local arrivalTime = 0.0
            
            if taxi == nil then
                SpawnTaxi(pcoords) -- switch to use returned values instead of globals
                log('taxi spawned at ' .. pcoords)

                circle = pcoords
                TriggerEvent('chat:addMessage', {
                    args = { 'Pick up at ' .. pcoords.x .. ', ' .. pcoords.y .. ', ' .. pcoords.z  }
                })
                TaskVehicleDriveToCoord(taxiPed, taxi, pcoords.x, pcoords.y, pcoords.z, 8.0, 1, carModel, 786603, 15.0, true)
                SetPedKeepTask(taxiPed, true)
            end
            

            -- only using for testing pick up location
            if circle.x ~= nil then
                DrawMarker(1, circle.x, circle.y, circle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            5.0, 5.0, 2.0, 204, 204, 0, 100,
                            false, false, 2, false, nil, nil, false)
            end
            
            -- while enroute do this. stop after pick up
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
            vX, vY, vZ = table.unpack(GetEntityCoords(taxi))
            local DistanceBetweenTaxi = GetDistanceBetweenCoords(pcoords.x, pcoords.y, pcoords.z, vX, vY, vZ, true)

            if DistanceBetweenTaxi <= 20.0 then
                if not IsPedInAnyVehicle(playerPed, false) and IsControlPressed(0,23) and IsControlJustReleased(0,23) then
                    -- experiment with SetVehicleExclusiveDriver_2 instead
                    TaskEnterVehicle(playerPed, taxi, -1, 2, 1.0, 1, 0)
                end
                if not hasArrivedForPickup then
                    hasArrivedForPickup = true
                    arrivalTime = GetGameTimer()
                end
            end
            if hasArrivedForPickup and not hasEntered and GetGameTimer() > arrivalTime + 40000 then
                EndTransport()
                arrivalTime = 0.0
            end
            if IsPedSittingInVehicle(playerPed, taxi) then
                hasEntered = true
                -- check for waypoint change
                if IsWaypointActive() then
                    -- get waypoint
                    -- local wp = GetBlipCoords(GetFirstBlipInfoId(8))
                    local waypoint = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                    -- local wp = Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector())
                    -- check for waypoint change
                    if waypoint ~= nil and waypoint ~= destination then
                        TriggerEvent('chat:addMessage', {
                            args = { 'waypoint changed'  }
                        })
                        destination = waypoint
                        DriveToAsTaxi(taxiPed, taxi, waypoint)
                        
                        -- is a normal wait better here?
                        --Wait(1000)
                    end

                    local endDist = #(GetEntityCoords(taxiPed) - GetEntityCoords(destination))

                    while GetEntitySpeed(taxi) and endDist > 10.0 do
                        endDist = #(GetEntityCoords(taxiPed) - GetEntityCoords(destination))
                        Citizen.Wait(1000)
                        if IsControlPressed(0,23) and IsControlJustReleased(0,23) then
                            endDist = 1.0
                        end
                    end

                    while GetEntitySpeed(taxi) > 1.0 do
                        SetVehicleForwardSpeed(taxi, math.ceil(GetEntitySpeed(taxi)*0.75 ))
                        TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
                        Citizen.Wait(1)
                    end
                    -- TaskVehicleTempAction(taxiPed, taxi, 6, 2000)
                    -- SetVehicleHandbrake(taxiVeh, true)
                    -- SetPedKeepTask(taxiPed, true)
                end
            end
            if hasEntered and not IsPedSittingInVehicle(playerPed, taxi) then
                EndTransport()
            end
        else
            Wait(5000)
        end
    end
end)
