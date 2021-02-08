local inService, hasCustomer, wasTaxiRented, isEntering = false, false, false, false
local taxi, customer, customerBlip, destinationBlip, targetBlip = nil, nil, nil, nil, nil
local speed = 0.0

function spawnCustomer()
    local pedLocation = config.locations[math.random(1, #config.locations)]
    log('New ped at ' .. pedLocation)
    local ped = config.peds[math.random(1, #config.peds)]
    RequestModel(ped)
    while not HasModelLoaded(ped) do
        Wait(200)
    end

    return CreatePed(26, ped, pedLocation.x, pedLocation.y, pedLocation.z, 3.0, false, false)
end

function createDestination()
    local pedDesination = config.locations[math.random(1, #config.locations)]
    log('New destination at ' .. pedDesination)
    return pedDesination
end

function customerGetOutAtStop(customer, speed)
    if speed <= config.dropOffSpeed then
        -- wait a bit so player can some to full stop
        Wait(2000)
        TaskLeaveVehicle(customer, taxi, 64)
    end
end

function kickOutFare(customer, speed)
    if speed <= config.dropOffSpeed then
        TaskLeaveVehicle(customer, taxi, 256)
    else
        -- this should cause them to roll out of the car
        -- this is really only for my own satisfaction of watching a local jump out when going 100mph
        TaskLeaveVehicle(customer, taxi, 4160)
    end
end

function customerDied()
    log('Your customer has died. Please find another')
end

function spawnTaxi(zone)
    local vehicleName = 'taxi'
    wasTaxiRented = true
    RequestModel(vehicleName)

    while not HasModelLoaded(vehicleName) and not HasModelLoaded(taxiDriver) do
        Wait(100)
    end

    TriggerServerEvent('taxi_job:rentCab')
    taxi = CreateVehicle(vehicleName, zone.pos.x, zone.pos.y, zone.pos.z, zone.heading, true, false)
end

function log(args)
    TriggerEvent('chat:addMessage', {
        args = { args }
    })
end

function startJob()
    inService = true
    log('You are now a cab driver!')
end

function endJob()
    -- once the job ends, reset everything to default and kick out a customer if you had one
    inService = false
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
end

RegisterCommand('taxistart', function()
    -- Make this only work if taxi is player owned?
    local playerPed = PlayerPedId()
    if IsPedInAnyTaxi(playerPed) then
        if not inService then
            taxi = GetVehiclePedIsIn(playerPed, false)
            startJob()
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
        endJob()
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

AddEventHandler('taxi_job:enteredMarker', function(zone)
    -- spawn taxi if at stand
    -- give vehicle a random decent fuel level
    -- cab plate number
    -- show prompt
    if not IsPedSittingInAnyVehicle(PlayerPedId()) then
        if taxi == nil then
            if IsControlJustPressed(0, 38) then
                spawnTaxi(zone)
                startJob()
            end
        else
            if IsControlJustPressed(0, 38) then
                -- check if nearby first
                DeleteVehicle(taxi)
                TriggerServerEvent('taxi_job:returnCab')
                endJob()
            elseif IsControlJustPressed(0, 74) then
                spawnTaxi(zone)
            end
        end
    end
end)

-- thread to handle job circles
CreateThread(function()
    while true do
        Wait(0)
        local pedCoords = GetEntityCoords(PlayerPedId())
        local inMarker, sleep, currentZone = false, true

        for k,v in pairs(config.zones) do
            local distance = GetDistanceBetweenCoords(pedCoords, v.pos.x, v.pos.y, v.pos.z, true)

            if v.type ~= -1 and distance < config.drawDistance then
                sleep = false
                DrawMarker(v.type, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                v.size.x, v.size.y, v.size.z, v.color.r, v.color.g, v.color.b, 100,
                false, false, 2, v.rotate, nil, nil, false)
            end

            if distance < v.size.x then
                inMarker, currentZone = true, k
                TriggerEvent('taxi_job:enteredMarker', config.zones.vSpawn)
            else
                inMarker = false
                currentZone = nil
                -- log("moved out of zone")
            end
        end
        if sleep then
            Wait(500)
        end
        -- spawn vehicle from cirle
        -- return vehicle at circle if one has been pulled
        -- allow to pull another if yours has been lost, but no money back
    end
end)

-- main thread for job functions
CreateThread(function()
    local distance = 0.0
    local spawnAttempts = 0
    local cX, cY, cZ = nil
    local dX, dY, dZ = nil

    while true do 

        Wait(0)
        local playerPed = PlayerPedId()
        speed = GetEntitySpeed(playerPed) * 2.236936

        if inService then
            -- show job status message

            if not hasCustomer then
                -- add job chance and frequency here
                Wait(math.random(25000, 40000))
                spawnChance = config.jobRate * (config.rateCurve^spawnAttempts)
                log('Chance to spawn is ' .. spawnChance * 100 .. '%')
                if math.random(1, 1000) > math.floor(spawnChance * 1000) then
                    spawnAttempts = spawnAttempts + 1
                    log('Attempt # ' .. spawnAttempts)
                    local nextAttemptTime = math.random(25000, 40000)
                    log('Trying to spawn in ~' .. nextAttemptTime .. 'ms')
                    Wait(nextAttemptTime)
                else
                    spawnAttempts = 0
                    customer = spawnCustomer()
                    customerBlip = AddBlipForEntity(customer)
                    SetBlipSprite (customerBlip, 198)
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

            else
                local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
                cX, cY, cZ = table.unpack(GetEntityCoords(customer))

                if IsPedFatallyInjured(customer) then
                    customerDied()
                    SetEntityAsMissionEntity(customer, false, true)
                    SetEntityAsNoLongerNeeded(customer)
                    RemoveBlip(destinationBlip)
                    RemoveBlip(customerBlip)
                    distance = 0.0
                    isEntering, hasCustomer = false, false
                    customer, customerBlip, destinationBlip = nil, nil, nil
                    Wait(10000)
                end
                if not IsPedSittingInVehicle(customer, taxi) then
                    local distanceToPed = CalculateTravelDistanceBetweenPoints(cX, cY, cZ, pX, pY, pZ)

                    -- marker above ped head
                    if  distanceToPed < 50.0 and distanceToPed > 10.01 then
                        local pickup = config.zones.pickup
                        DrawMarker(0, cX, cY, cZ + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        pickup.size.x, pickup.size.y, pickup.size.z, pickup.color.r, pickup.color.g, pickup.color.b, 100,
                        pickup.bounce, false, 2, pickup.rotate, nil, nil, false)
                    end

                    if distanceToPed < 10.0 then
                        -- this annoying section is to stop the customer from hunting
                        -- the cab if you move out of the distance, but attempt to get
                        -- back in if you get back in range
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
                        -- If customer has gotten in the vehicle

                        local distanceToDestination = CalculateTravelDistanceBetweenPoints(pX, pY, pZ, dX, dY, dZ)

                        if destinationBlip == nil then
                            -- We only want to create the blip once, otherwise it won't actually show
                            local pedDesination = createDestination()
                            while CalculateTravelDistanceBetweenPoints(pX, pY, pZ, dX, dY, dZ) == 0.0 do
                                pedDesination = createDestination()
                            end
                            dX, dY, dZ = table.unpack(pedDesination)
                            RemoveBlip(customerBlip)
                            destinationBlip = AddBlipForCoord(dX, dY, dZ)
                            SetBlipSprite (customerBlip, 198)
                            SetBlipDisplay(customerBlip, 4)
                            SetBlipScale  (customerBlip, 0.75)
                            SetBlipColour (customerBlip, 2)
                            SetBlipAsShortRange(customerBlip, true)
                            SetBlipRoute(destinationBlip, true)

                            -- set total job distance in here since this is only called once per job
                            -- TODO: Convert to miles
                            distance = math.ceil(distanceToDestination)
                        end

                        -- marker at destination
                        if  distanceToDestination < 50.0 then
                            local dropoff = config.zones.dropoff
                            DrawMarker(23, dX, dY, dZ - 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            dropoff.size.x, dropoff.size.y, dropoff.size.z, dropoff.color.r, dropoff.color.g, dropoff.color.b, 100,
                            dropoff.bounce, false, 2, dropoff.rotate, nil, nil, false)

                            if distanceToDestination < 10.0 and speed < config.dropOffSpeed then
                                log('Total job distance: ' .. distance)
                                TriggerServerEvent('taxi_job:success', distance)
                                customerGetOutAtStop(customer, speed)
                                SetEntityAsNoLongerNeeded(customer)
                                RemoveBlip(destinationBlip)
                                distance = 0.0
                                isEntering, hasCustomer = false, false
                                customer, customerBlip, destinationBlip = nil, nil, nil
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
