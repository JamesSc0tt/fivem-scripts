taxi = nil
taxiPed = nil
taxiHailed = false
hasEntered = false
hasArrivedForPickup = false
taxiBlip = nil
destination = nil
circle = nil

AddEventHandler('taxi:hail', function()
    if taxiHailed then
        endTransport()
    end
    taxiHailed = true

    TriggerEvent('chat:addMessage', {
		args = { 'A taxi is on the way!' }
	})
end)

AddEventHandler('taxi:cancel', function()
    endTransport()
end)

function getGroundZCoord(coord)
    local cx, cy, cz = table.unpack(coord)
    for i = 0, 1000, 1 do
    -- repeat
        if GetGroundZFor_3dCoord(cx, cy, ToFloat(i), cz, false) then
            cz = ToFloat(i)
            break;
        end
    -- until (ground or i < 0.0)
    end
    TriggerEvent('chat:addMessage', {
		args = { 'meow ' .. cx .. ', ' .. cy .. ', ' .. cz  }
	})
    return vector3(cx, cy, cz)
end

function spawnTaxi(pX, pY, pZ)
    local vehicleName = GetHashKey('taxi')
    local taxiDriver = GetHashKey('s_m_o_busker_01')
    -- GetNthClosestVehicleNodeIdWithHeading
    -- local _, vector = GetNthClosestVehicleNode(pX, pY, pZ, math.random(80, 100), 0, 0, 0)
    local _, vector, h = GetNthClosestVehicleNodeFavourDirection(pX, pY, pZ, pX, pY, pZ, math.random(80, 100), 1, 0x40400000, 0)
    -- TaskTurnPedToFaceCoord
    -- TaskTurnPedToFaceEntity
    -- GetPickupCoords
    -- GetSafePickupCoords
    -- GetSafeCoordForPed
    local sX, sY, sZ = table.unpack(vector)

    RequestModel(vehicleName)
    RequestModel(taxiDriver)

    while not HasModelLoaded(vehicleName) do
        Wait(1)
    end

    while not HasModelLoaded(taxiDriver) do 
        Wait(1)
    end

    taxi = CreateVehicle(vehicleName, sX, sY, sZ, h, true, false)
    SetEntityAsMissionEntity(taxi, true, true)
    SetVehicleEngineOn(taxi, true, true, false)

    taxiPed = CreatePedInsideVehicle(taxi, 26, taxiDriver, -1, true, false)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    SetEntityAsMissionEntity(taxiPed, true, true)
    PickUpFare(taxiPed, taxi, vector3(pX, pY, pZ))
end

function calculateRoadsideCoords(dest)
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

function PickUpFare(ped, veh, dest)
    circle = dest
    TriggerEvent('chat:addMessage', {
		args = { 'Pick up at ' .. dest.x .. ', ' .. dest.y .. ', ' .. dest.z  }
	})
    TaskVehicleDriveToCoord(ped, veh, dest.x, dest.y, dest.z, 20.0, 0, veh, 411, 5.0)
    -- SetPedKeepTask(ped, true)
end

function driveToAsTaxi(ped, veh, dest)
    -- local roadSide = calculateRoadsideCoords(dest)
    -- local r1, r2, roadSide, r4, r5, r6 = GetClosestRoad(dX, dY, dZ, 1.0, 0, false)
    -- groundZCoord = getGroundZCoord(dest)
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
    TaskVehicleDriveToCoord(ped, veh, dx, dy, dz, 20.0, 0, veh, 411, 10.0)
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

function endTransport()
    Wait(2000)
    RemoveBlip(taxiBlip)
    -- ClearVehicleTasks(taxi)
    ClearPedTasks(taxiPed)
    -- local _, taskSeq = OpenSequenceTask(0)
    -- TaskVehicleTempAction(0, taxi, 9, 5000)
    -- TaskVehicleDriveWander(0, taxi, 20.0, 419)
    -- CloseSequenceTask(taskSeq)
    -- TaskPerformSequence(taxiPed, taskSeq)
    SetEntityAsNoLongerNeeded(taxi)
    SetEntityAsNoLongerNeeded(taxiPed)
    taxi = nil
    taxiPed = nil
    taxiHailed = false
    hasEntered = false
    hasArrivedForPickup = false
    taxiBlip = nil
    destination = nil
end

CreateThread(function()
    local arrivalTime = 0.0
    while true do
        Wait(1)
        local playerPed = PlayerPedId()
        if taxiHailed then
            
            if taxi == nil then
                pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
                spawnTaxi(pX, pY, pZ)
            end

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
            pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
            vX, vY, vZ = table.unpack(GetEntityCoords(taxi))
            local DistanceBetweenTaxi = GetDistanceBetweenCoords(pX, pY, pZ, vX, vY, vZ, true)
            if DistanceBetweenTaxi <= 20.0 then
                if not IsPedInAnyVehicle(playerPed, false) and IsControlJustPressed(0, 23) then
                    -- experiment with SetVehicleExclusiveDriver_2 instead
                    TaskEnterVehicle(playerPed, taxi, -1, 2, 1.0, 1, 0)
                end
                if not hasArrivedForPickup then
                    hasArrivedForPickup = true
                    arrivalTime = GetGameTimer()
                end
            end
            if hasArrivedForPickup and not hasEntered and GetGameTimer() > arrivalTime + 40000 then
                endTransport()
                arrivalTime = 0.0
            end
            if IsPedSittingInVehicle(playerPed, taxi) then
                hasEntered = true
                -- check for waypoint change
                if DoesBlipExist(GetFirstBlipInfoId(8)) then
                    -- get waypoint
                    -- local wp = GetBlipCoords(GetFirstBlipInfoId(8))
                    local wp = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                    -- local wp = Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector())
                    -- check for waypoint change
                    if wp ~= nil and wp ~= destination then
                        TriggerEvent('chat:addMessage', {
                            args = { 'wp changed'  }
                        })
                        destination = wp
                        driveToAsTaxi(taxiPed, taxi, wp)
                        
                        -- is a normal wait better here?
                        Wait(1000)
                    end
                    if GetDistanceBetweenCoords() < 55.0 then
                        TaskVehicleTempAction(taxiPed, taxi, 6, 2000)
                        SetVehicleHandbrake(taxiVeh, true)
                        SetPedKeepTask(taxiPed, true)
                    end
                end
            end
            if hasEntered and not IsPedSittingInVehicle(playerPed, taxi) then
                endTransport()
            end
        else
            Wait(5000)
        end
    end
end)
