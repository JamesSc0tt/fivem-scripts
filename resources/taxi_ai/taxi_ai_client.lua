carModel = 'taxi'
hailing = false
hasArrivedForPickup = false

function log(args)
    Citizen.Trace(args .. '\n')
end

RegisterNetEvent("taxi:callAI")
AddEventHandler('taxi:callAI', function()
    if not hailing then
        hailing = true
        StartAiTaxi()
    else
        hailing = false
        Wait(1200)
        TriggerEvent('taxi:callAI')
    end
end)

AddEventHandler('taxi:cancel', function()
    endTransport()
end)

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

function StartAiTaxi()
    local playerPed = PlayerPedId()
    local pcoords = GetEntityCoords(playerPed)
    local dcoords = vector3(-900.0, -900.0, -900.0)
    local count = 400000
    local inTaxi = false
    local enroute = false
    local taxiBlip = nil
    local circle = nil
    SetWaypointOff()
    -- spawn
    local taxi, taxiPed = SpawnTaxi(pcoords)
    log('taxi spawned at ' .. pcoords)

    circle = pcoords
    TriggerEvent('chat:addMessage', {
        args = { 'Pick up at ' .. pcoords.x .. ', ' .. pcoords.y .. ', ' .. pcoords.z  }
    })
    TaskVehicleDriveToCoord(taxiPed, taxi, pcoords.x, pcoords.y, pcoords.z, 10.0, 1, carModel, 786603, 10.0, true)
    SetPedKeepTask(taxiPed, true)
    -- pick up
    while count > 0 and not IsPedDeadOrDying(taxiPed, true) and DoesEntityExist(taxiPed) and hailing do
        Wait(1)
        count = count - 1
        
        if not enroute and GetVehiclePedIsIn(playerPed, false) ~= taxi then
            local distanceToTaxi = #(GetEntityCoords(taxi) - GetEntityCoords(playerPed))
            -- only using for testing pick up location
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

        if inTaxi and not IsPedInVehicle(playerPed, taxi, true) then
            if enroute then
                log('got out')
                TriggerServerEvent('ai_taxi:payCab')
            else
                log('got out with no fare')
            end

            count = 0
            break
        end

        if GetVehiclePedIsIn(playerPed, false) == taxi then
            Wait(1000)
            log(count)

            if not inTaxi then
                inTaxi = true
                log('got in')
                RemoveBlip(taxiBlip)
                taxiBlip = nil
                -- remove blips
            end

            if not enroute and IsWaypointActive() then
                local waypoint = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                enroute = true
                dcoords = GetTaxiDropOffPoint(waypoint)
                log(dcoords)
                TaskVehicleDriveToCoordLongrange(taxiPed, taxi, dcoords.x, dcoords.y, dcoords.z, 14.0, 786603, 55.0)
                SetPedKeepTask(taxiPed, true) 
            end

            if enroute then
                local endDist = #(GetEntityCoords(taxi) - dcoords)
                
                if endDist < 150.0 or count < 100 then
                    log('final stretch')

                    while IsPedSittingInVehicle(playerPed, taxi) and GetEntitySpeed(taxi) > 1.0 and endDist > 10.0 do
                        endDist = #(GetEntityCoords(taxi) - dcoords)
                        Wait(1000)
                        if IsControlPressed(0,23) and IsControlJustReleased(0,23) then
                            endDist = 1.0
                        end
                    end
    
                    while IsPedSittingInVehicle(playerPed, taxi) and GetEntitySpeed(taxi) > 1.0 do
                        TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
                        Wait(1)
                    end

                    while IsPedSittingInVehicle(playerPed, taxi) do
                        Wait(1)
                    end

                    count = 0
                    TriggerServerEvent('ai_taxi:payCab')
                end

                if not IsWaypointActive() then
                    enroute = false
                end
            end
        else
            inTaxi = false
        end
    end
    log('taxi task finished')
    -- reset everything
    inTaxi = false
    RemoveBlip(taxiBlip)
    SetPedKeepTask(taxiPed, false)
    SetPedAsNoLongerNeeded(taxiPed)         
    SetVehicleAsNoLongerNeeded(taxi)
    FreezeEntityPosition(taxi, true)
    Citizen.Wait(1200)

    SetBlockingOfNonTemporaryEvents(taxiPed, true)      
    SetPedKeepTask(taxiPed, true) 
    
    FreezeEntityPosition(taxi, false)
    TaskVehicleDriveWander(taxiPed, taxi, 10.0, 786603)
    taxi = nil
    taxiPed = nil
    taxiBlip = nil
    circle = nil
    hailing = false
    hasArrivedForPickup = false
end
