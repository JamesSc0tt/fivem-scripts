local hasAlreadyEnteredMarker, inService, hasCustomer, wasTaxiRented, isEntering = false, false, false, false, false
local taxi, customer, customerBlip, destinationBlip, targetBlip, currentAction, currentStatus = nil, nil, nil, nil, nil, nil, nil
local speed = 0.0

function getCustomer(playerPed)
    local ped = getRandomPed(GetEntityCoords(playerPed))
    while ped == nil do
        log('cannot find a nearby ped. searching again')
        Wait(30000)
        ped = getRandomPed(GetEntityCoords(playerPed))
    end
    return ped
end

function getRandomPed(playerCoords)
    local search = {}
    local searchDistance = config.job.searchDistance

    for i=1, 250, 1 do
        local ped = GetRandomPedAtCoord(playerCoords.x, playerCoords.y, playerCoords.z, searchDistance, searchDistance, searchDistance, 26)
        if DoesEntityExist(ped) and IsPedHuman(ped) and IsPedWalking(ped) and not IsPedAPlayer(ped) then
            table.insert(search, ped)
        end
    end

    if #search > 0 then
		return search[GetRandomIntInRange(1, #search)]
	end
    
end

function table.copy(org)
    return {table.unpack(org)}
end

function customerGetOutAtStop(customer, speed)
    if speed <= config.job.dropSpeed then
        -- wait a bit so player can some to full stop
        Wait(2000)
        TaskLeaveVehicle(customer, taxi, 0)
        Wait(1000)
        SetVehicleDoorShut(taxi, 3, false)
    end
end

function kickOutFare(customer, speed)
    if speed <= config.job.dropSpeed then
        TaskLeaveVehicle(customer, taxi, 256)
    else
        -- this should cause them to roll out of the car
        -- this is really only for my own satisfaction of watching a local jump out when going 100mph
        TaskLeaveVehicle(customer, taxi, 4160)
    end
end

function spawnTaxi(zone)
    local vehicleName = 'taxi'
    wasTaxiRented = true
    RequestModel(vehicleName)

    while not HasModelLoaded(vehicleName) do
        Wait(100)
    end

    TriggerServerEvent('taxi_job:rentCab')
    taxi = CreateVehicle(vehicleName, zone.pos.x, zone.pos.y, zone.pos.z, zone.heading, true, false)
end

function log(args)
    Citizen.Trace(args .. '\n')
end

function startJob()
    inService = true
    TriggerServerEvent('taxi_job:signOn')
end

function endJob()
    -- once the job ends, reset everything to default and kick out a customer if you had one
    inService = false
    TriggerServerEvent('taxi_job:signOff')
    log('You\'ve clocked off!')
    RemoveBlip(customerBlip)
    RemoveBlip(destinationBlip)
    SetEntityAsNoLongerNeeded(taxi)
    SetEntityAsNoLongerNeeded(customer)
    if hasCustomer and IsPedSittingInVehicle(customer, taxi) then
        kickOutFare(customer, speed)
    end
    hasCustomer, inService, isEntering = false, false, false
    customerBlip, destinationBlip, customer, taxi = nil, nil, nil, nil
    TriggerEvent('taxi_job:updateStatus', '', false)
end

function isPlayerTaxi()
    -- logic to check if player owned vehicle

    return false
end

RegisterCommand('taxistart', function()
    -- Make this only work if taxi is player owned?
    local playerPed = PlayerPedId()
    if IsPedInAnyTaxi(playerPed)then
        if not inService then
            taxi = GetVehiclePedIsIn(playerPed, false)
            if isPlayerTaxi(taxi) then
                startJob()
            else
                log('This command only works in an owned taxi')
            end
        else
            log('You\'re already in service...')
        end
    else
        log('You need to be in a taxi to use this command')
    end
end)

RegisterCommand('taxistop', function()
    -- Make this only work if taxi is player owned?
    if inService then
        if isPlayerTaxi(taxi) then
            endJob()
        else
            log('This command only works in an owned taxi')
        end
    else
        log('You need to be in service to use this command')
    end
end)

RegisterCommand('rejectfare', function()
    if inService then
        kickOutFare(customer, speed)
        hasCustomer = false
        RemoveBlip(customerBlip)
        RemoveBlip(destinationBlip)
        SetEntityAsNoLongerNeeded(customer)
        hasCustomer, isEntering = false, false
        customerBlip, destinationBlip, customer = nil, nil, nil
    else
        log('You need to be in service to use this command')
    end
end)

RegisterNetEvent('taxi_job:updateStatus')
AddEventHandler('taxi_job:updateStatus', function(status, display, args)
    if status ~= currentStatus then
        currentStatus = status
        SendNUIMessage({
            type = 'status',
            display = display,
            status = status,
            args = args
        })
    end
end)

AddEventHandler('taxi_job:enteredMarker', function(zone)
    if zone == 'JobSite' then
        if not IsPedSittingInAnyVehicle(PlayerPedId()) then
            if taxi == nil then
                SendNUIMessage({
                    type = 'prompt',
                    display = true,
                    inService = false,
                    rentalPrice = config.job.rentalPrice
                })
                currentAction = 'taxi_spawn'
            else -- if not playerowned
                SendNUIMessage({
                    type = 'prompt',
                    display = true,
                    inService = true,
                    rentalPrice = config.job.rentalPrice,
                    returnPrice = config.job.returnPrice
                })
                currentAction = 'taxi_delete'
            end
        end
    end
end)

AddEventHandler('taxi_job:exitedMarker', function(zone)
    SendNUIMessage({
        type = 'prompt',
        display = false
    })
    currentAction = nil
end)

-- thread to handle job circles
CreateThread(function()
    while true do
        Wait(0)
        local pedCoords = GetEntityCoords(PlayerPedId())
        local inMarker, sleep, currentZone = false, true

        -- do I even need this loop?
        for k,v in pairs(config.zones) do
            local distance = #(pedCoords - vector3(v.pos.x, v.pos.y, v.pos.z))

            if v.type ~= -1 and distance < config.drawDistance then
                sleep = false
                DrawMarker(v.type, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                v.size.x, v.size.y, v.size.z, v.color.r, v.color.g, v.color.b, 100,
                false, false, 2, v.rotate, nil, nil, false)
            end

            if distance <= v.size.x then
                inMarker, currentZone = true, k
            end
        end

        if (inMarker and not hasAlreadyEnteredMarker) or (inMarker and lastZone ~= currentZone) then
            hasAlreadyEnteredMarker, lastZone = true, currentZone
            TriggerEvent('taxi_job:enteredMarker', currentZone)
        end

        if not inMarker and hasAlreadyEnteredMarker then
            hasAlreadyEnteredMarker = false
            TriggerEvent('taxi_job:exitedMarker', lastZone)
        end

        if sleep then
            Wait(500)
        end
    end
end)

-- thread for controls
CreateThread(function()
    while true do
        Wait(0)
        if currentAction then
            local reset = false
            if currentAction == 'taxi_spawn' then
                if IsControlJustPressed(0, 38) then
                    spawnTaxi(config.zones.VehicleSpawner)
                    startJob()
                    reset = true
                end
            elseif currentAction == 'taxi_delete' then
                if IsControlJustPressed(0, 38) then
                    -- check if nearby first
                    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(taxi)) then
                        DeleteVehicle(taxi)
                    else
                        -- no taxi to return 
                    end
                    TriggerServerEvent('taxi_job:returnCab')
                    endJob()
                    reset = true
                elseif IsControlJustPressed(0, 74) then
                    spawnTaxi(config.zones.VehicleSpawner)
                    reset = true
                end
            end

            -- force update for NUI prompt when control is pressed and conditions change
            if reset == true then
                hasAlreadyEnteredMarker = false
                currentAction = nil
                reset = false
            end
        end
    end
end)

-- main thread for job functions
CreateThread(function()
    local spawnAttempts, nextAttemptTime, timer = 0, 0, 0
    local destVect

    while true do 

        Wait(0)
        local playerPed = PlayerPedId()
        speed = GetEntitySpeed(playerPed) * 2.236936

        if inService then
            -- show job status message

            -- check for customer or player death
            if (customer ~= nil and IsPedDeadOrDying(customer)) or IsPedDeadOrDying(playerPed) then
                if IsPedDeadOrDying(playerPed) then
                    if IsPedSittingInVehicle(customer, taxi) then
                        TaskLeaveVehicle(customer, taxi, 0)
                    end
                    endJob()
                else
                    TriggerEvent('taxi_job:updateStatus', 'CustDead', true)
                end
                SetEntityAsMissionEntity(customer, false, true)
                SetEntityAsNoLongerNeeded(customer)
                RemoveBlip(destinationBlip)
                RemoveBlip(customerBlip)
                isEntering, hasCustomer = false, false
                customer, customerBlip, destinationBlip = nil, nil, nil
                Wait(10000)
            end

            if taxi ~= nil and not IsPedSittingInVehicle(playerPed, taxi) then
                -- end job when out of vehicle too long and maybe instantly when too far
                local taxiDistance = #(GetEntityCoords(playerPed) - GetEntityCoords(taxi))
                if taxiDistance >= 30.0 then
                    if timer == 0.0 then
                        timer = GetGameTimer() + config.job.idle
                    end
                    if not IsPedSittingInVehicle(playerPed, taxi) then
                        TriggerEvent('taxi_job:updateStatus', 'WillFire', true)
                        if GetGameTimer() >= timer or taxiDistance >= 100.0 then
                            endJob()
                            break
                        end
                    end
                else
                    TriggerEvent('taxi_job:updateStatus', 'OutVeh', true)
                    timer = 0.0
                end
            elseif not hasCustomer then
                TriggerEvent('taxi_job:updateStatus', 'Waiting', true)
                if nextAttemptTime == 0 then
                    nextAttemptTime = GetGameTimer() + math.random(config.job.freq.min, config.job.freq.max)
                end
                if GetGameTimer() >= nextAttemptTime then
                    spawnChance = config.job.rate * (config.job.curve^spawnAttempts)
                    -- spawnChance = 1
                    log('Chance to spawn is ' .. spawnChance * 100 .. '%')
                    if math.random(1, 1000) > math.floor(spawnChance * 1000) then
                        nextAttemptTime = GetGameTimer() + math.random(config.job.freq.min, config.job.freq.max)
                        spawnAttempts = spawnAttempts + 1
                        log('Attempt # ' .. spawnAttempts)
                    else
                        spawnAttempts = 0
                        nextAttemptTime = 0
                        customer = getCustomer(playerPed)
                        customerBlip = AddBlipForEntity(customer)
                        SetBlipSprite (customerBlip, 480)
                        SetBlipDisplay(customerBlip, 4)
                        SetBlipScale  (customerBlip, 0.75)
                        SetBlipColour (customerBlip, 2)
                        SetBlipAsShortRange(customerBlip, true)
                        SetBlipRoute(customerBlip, true)
                        SetEntityAsMissionEntity(customer, true, false)
                        ClearPedTasksImmediately(customer)
                        SetBlockingOfNonTemporaryEvents(customer, true)
                        hasCustomer = true
                    end
                end
            else
                local taxiVect = GetEntityCoords(taxi)
                local custVect = GetEntityCoords(customer)
                
                if not IsPedSittingInVehicle(customer, taxi) then
                    local distanceToPed = #(taxiVect - custVect)
                    TriggerEvent('taxi_job:updateStatus', 'PickUp', true)

                    -- marker above ped head
                    if  distanceToPed < 50.0 and distanceToPed > 5.01 then
                        local pickup = config.markers.pickup
                        DrawMarker(pickup.type, custVect.x, custVect.y, custVect.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        pickup.size.x, pickup.size.y, pickup.size.z, pickup.color.r, pickup.color.g, pickup.color.b, 100,
                        pickup.bounce, false, 2, pickup.rotate, nil, nil, false)
                    end

                    if distanceToPed < 5.0 then
                        -- this section is to stop the customer from hunting the cab
                        -- if you move out of the distance, but attempt to get back
                        -- in if you get back in range
                        if not isEntering then
                            ClearPedTasks(customer)
                            Wait(1000)
                            TaskEnterVehicle(customer, taxi, -1, 2, 1.0, 0)
                            SetEntityAsMissionEntity(customer, false, true)
                            isEntering = true
                        end
                    else
                        ClearPedTasks(customer)
                        isEntering = false
                    end
                else
                    if IsPedSittingInVehicle(customer, taxi) then
                        local distanceToDestination
                        TriggerEvent('taxi_job:updateStatus', 'DropOff', true)

                        -- We only want to create the blip once, otherwise it won't actually show
                        if destinationBlip == nil then
                            local tempTable = table.copy(config.locations)
                            -- make sure we don't grab the same point or a point that's too close
                            while destVect == nil or distanceToDestination <= config.job.minDistance or distanceToDestination >= config.job.maxDistance do
                                Citizen.Wait(5)
                                if (#tempTable ~= 0) then
                                    local pos = math.random(1, #tempTable)
                                    destVect = tempTable[pos]
                                    distanceToDestination = #(taxiVect - destVect)
                                    table.remove(tempTable, pos)
                                else
                                    log('No destinations found within max distance. Getting random drop off')
                                    destVect = config.locations[math.random(1, #config.locations)]
                                    distanceToDestination = #(taxiVect - destVect)
                                    break
                                end
                            end
                            log('New destination at ' .. destVect)
                            RemoveBlip(customerBlip)
                            destinationBlip = AddBlipForCoord(destVect.x, destVect.y, destVect.z)
                            SetBlipSprite (customerBlip, 198)
                            SetBlipDisplay(customerBlip, 4)
                            SetBlipScale  (customerBlip, 0.75)
                            SetBlipColour (customerBlip, 2)
                            SetBlipAsShortRange(customerBlip, true)
                            SetBlipRoute(destinationBlip, true)
                        else
                            distanceToDestination = #(taxiVect - destVect)
                        end

                        -- marker at destination
                        if  distanceToDestination ~= nil and distanceToDestination < 50.0 then
                            local dropoff = config.markers.dropoff
                            DrawMarker(dropoff.type, destVect.x, destVect.y, destVect.z - 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            dropoff.size.x, dropoff.size.y, dropoff.size.z, dropoff.color.r, dropoff.color.g, dropoff.color.b, 100,
                            dropoff.bounce, false, 2, dropoff.rotate, nil, nil, false)

                            if distanceToDestination < 5.0 and speed < config.job.dropSpeed then
                                TriggerServerEvent('taxi_job:success')
                                customerGetOutAtStop(customer, speed)
                                SetEntityAsNoLongerNeeded(customer)
                                RemoveBlip(destinationBlip)
                                isEntering, hasCustomer = false, false
                                customer, customerBlip, destinationBlip, destVect = nil, nil, nil, nil
                                Wait(5000)
                            end
                        end
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)
