carModel = `taxi` -- using ` gets the hash during compiling
hailing = false
hasArrivedForPickup = false

local datastore = {} -- use a table to store script variables to clean up code.

local debug_mode = false -- add debug_mode so production doesn't get many useless prints
function log(args)
    if debug_mode then
        if type(args) == 'table' then
            for k,v in pairs(args) do
               print(args) 
            end
        else
            print(args)
        end
    end
    return debug_mode
end

RegisterNetEvent("taxi:callAI")
AddEventHandler('taxi:callAI', function()
    if not hailing then
        hailing = true
        StartAiTaxi()
    else
        hailing = false
        Wait(1200)
        TriggerEvent('taxi:callAI') -- This would create a loop if the player was to try cancel their booking, remove
        -- Need to add stuff here to clean up entities created by script
    end
end)

-- might be good to put in utils and pass in vehicle model and ped model as well
-- [VT] Keep this in this script, there is a util to spawn a vehicle, this script should be changed to use it
function SpawnTaxi(coords)
    -- different ped?
    local taxiDriver = `s_m_o_busker_01` -- using ` gets the hash during compiling
    local spawn, h = GetTaxiSpawnPoint(coords)

    RequestModel(carModel)
    while not HasModelLoaded(carModel) do
        Wait(0)
    end

    local taxi = CreateVehicle(carModel, spawn.x, spawn.y, spawn.z, h, true, false)
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

    log('taxi spawned at ' .. spawn)

    return taxi, taxiPed
end

-- move to utils to use for any vehicle spawn?
-- [VT] We could probably do this differently using the random coords finder we have in boosting
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

-- [VT] This is good enough
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

-- [VT] This needs reworking, can be massively streamlined
function StartAiTaxi()
    Citizen.CreateThread(function() -- This needs to be moved to it's own thread so StartAiTaxi() can be called anywhere.
        -- a lot of these need moving to a datastore
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)
        local dcoords = vector3(-900.0, -900.0, -900.0)
        local count = 400000 -- not sure on the point of this, creates while true do.
        local inTaxi = false -- move to datastore
        local enroute = false  -- move to datastore
        local taxiBlip = nil -- move to datastore
        local circle = nil -- move to datastore
        SetWaypointOff()
        -- spawn
        local taxi, taxiPed = SpawnTaxi(pcoords)
        circle = pcoords
        log('Pick up at ' .. pcoords)
        TaskVehicleDriveToCoord(taxiPed, taxi, pcoords.x, pcoords.y, pcoords.z, 10.0, 1, carModel, 786603, 10.0, true)
        SetPedKeepTask(taxiPed, true)
        -- pick up
        
        -- [VT] refactor script to use 'stages' with comments to clearly outline what part of the script does what 
        while calledTaxi do Citizen.Wait(0)
            if datastore['stage'] == 1 then
                -- create vehicle
            elseif datastore['stage'] == 2 then
                -- set vehicle en route
            elseif datastore['stage'] == 3 then
                -- wait for player to get in vehicle
            elseif datastore['stage'] == 4 then
                -- wait for player to set waypoint
            elseif datastore['stage'] ==  5 then
                -- task drive to waypoint
            elseif datastore['stage'] == 6 then
                -- wait for arrival
            elseif datastore['stage'] == 7 then
                -- wait for player to confirm
            elseif datastore['stage'] == 8 then
                -- wait for player to leave vehicle
            elseif datastore['stage'] == 100 then
               -- end & pay
            end
        end
        
        while count > 0 and not IsPedDeadOrDying(taxiPed, true) and DoesEntityExist(taxiPed) and hailing do
            Wait(1)
            count = count - 1

            if not enroute and GetVehiclePedIsIn(playerPed, false) ~= taxi then
                local distanceToTaxi = #(GetEntityCoords(taxi) - GetEntityCoords(playerPed))
                -- only using for testing pick up location
                -- use debug_mode to stop dev code on production
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
                    TaskVehicleTempAction(taxiPed, taxi, 27, 25.0)
                end

                if distanceToTaxi < 10.0 then
                    if not IsPedInAnyVehicle(playerPed, false) and IsControlJustPressed(0,23) then
                        TaskEnterVehicle(playerPed, taxi, -1, 2, 1.0, 1, 0)
                    end
                end
            end

            if inTaxi and not IsPedInVehicle(playerPed, taxi, true) then
                if enroute then
                    log('got out: pay fare')
                    TriggerServerEvent('ai_taxi:payCab')
                else
                    log('got out with no fare')
                end

                count = 0
                break
            end

            if GetVehiclePedIsIn(playerPed, false) == taxi then
                Wait(1000)

                if not inTaxi then
                    inTaxi = true
                    log('got in')
                    RemoveBlip(taxiBlip)
                    taxiBlip = nil
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
                        log('pay fare')
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
    end)
end
