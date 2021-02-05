local inService, hasCustomer, wasTaxiRented = false
local taxi, customer, customerBlip, destinationBlip, targetBlip = nil
local speed = 0.0

function startJob()
    inService = true
end

function endJob()
    inService = false
    RemoveBlip(customerBlip)
    RemoveBlip(destinationBlip)
    log('Wow...')
    if hasCustomer and IsPedSittingInVehicle(customer, taxi) then
        kickOutFare(customer, speed)
    end
    SetEntityAsNoLongerNeeded(taxi)
    SetEntityAsNoLongerNeeded(customer)
    hasCustomer, inService, isEntering = false
    customerBlip, destinationBlip, customer, cX, cY, cZ, dX, dY, dZ = nil
end

function spawnCustomer()
    local pedLocation = customerLocations[1]
    log('New ped at ' .. pedLocation)
    local pass = 's_m_o_busker_01'
    RequestModel(pass)
    while not HasModelLoaded(pass) do
        Wait(200)
    end
    return CreatePed(26, pass, 293.5, -590.2, 42.7, 3.0, false, false)
    -- return CreateRandomPed(pedLocation.x, pedLocation.y, pedLocation.z)
end

function createDestination()
    local pedDesination = vector3(253.4, -375.9, 44.1)
    log('New destination at ' .. pedDesination)
    return pedDesination
end

function customerGetOutAtStop(customer, speed)
    if speed <= 5.0 then
        Wait(2000)
        TaskLeaveVehicle(customer, taxi, 0)
    end
end

function kickOutFare(customer, speed)
    if speed <= 5.0 then
        TaskLeaveVehicle(customer, taxi, 1)
    else
        TaskLeaveVehicle(customer, taxi, 4160)
    end
end

function log(args)
    TriggerEvent('chat:addMessage', {
        args = { args }
    })
end

RegisterCommand('taxistart', function()
    --check if player is in owned taxi or maybe any taxi
    local playerPed = PlayerPedId()
    if IsPedInAnyTaxi(playerPed) then
        if not inService then
            log('You are now a cab driver!')
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
    if inService then
        log('You\'ve clocked off!')
        endJob()
    else
        log('You need to be in service to use this command')
    end
end)

-- RegisterNetEvent('taxi_job:rentCab')
-- AddEventHandler('taxi_job:rentCab', function()
--     --spawn taxi if at stand
--     --give vehicle a random decent fuel level
--     --cab plate number
--     local vehicleName = 'taxi'
--     wasTaxiRented = true
--     RequestModel(vehicleName)

--     while not HasModelLoaded(vehicleName) and not HasModelLoaded(taxiDriver) do
--         Wait(100)
--     end

--     taxi = CreateVehicle(vehicleName, sX, sY, sZ, 0, true, false)

--     taxi = GetVehiclePedIsIn(playerPed, false)
--     TriggerEvent('taxi_job:startService')
-- end)


CreateThread(function()
    local distance = 0.0
    local hasCustomer = false
    local customer = nil
    local cX, cY, cZ = nil
    local dX, dY, dZ = nil
    local isEntering = false

    while true do 

        Wait(10)
        local playerPed = PlayerPedId()
        carSpeed = GetEntitySpeed(playerPed)

        if inService then
            --show job status message
            --check if customer is not dead
            local pX, pY, pZ = table.unpack(GetEntityCoords(playerPed))
            cX, cY, cZ = table.unpack(GetEntityCoords(customer))

            if not hasCustomer then
                customer = spawnCustomer()
                customerBlip = AddBlipForEntity(customer)
                SetBlipRoute(customerBlip, true)
                SetEntityAsMissionEntity(customer, true, false)
                SetBlockingOfNonTemporaryEvents(customer, true)
                hasCustomer = true
            else
                if not IsPedSittingInVehicle(customer, taxi) then
                    local distanceToPed = CalculateTravelDistanceBetweenPoints(cX, cY, cZ, pX, pY, pZ)

                    if distanceToPed < 10.0 then
                        if not isEntering then
                            ClearPedTasks(customer)
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
                        if destinationBlip == nil then
                            dX, dY, dZ = table.unpack(createDestination())
                            RemoveBlip(customerBlip)
                            destinationBlip = AddBlipForCoord(dX, dY, dZ)
                            SetBlipRoute(destinationBlip, true)
                        end

                        carSpeed = GetEntitySpeed(taxi)
                        local distanceToDestination = CalculateTravelDistanceBetweenPoints(pX, pY, pZ, dX, dY, dZ)

                        if distanceToDestination < 10.0 then
                            TriggerServerEvent('taxi_job:success', distance)
                            distance = 0.0
                            customerGetOutAtStop(customer, speed)
                            SetEntityAsNoLongerNeeded(customer)
                            RemoveBlip(destinationBlip)
                            isEntering, hasCustomer = false
                            customer, customerBlip, destinationBlip = nil
                        end
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent('taxi_job:returnCab')
AddEventHandler('taxi_job:returnCab', function()
    --check cab is same somehow
    if wasTaxiRented then
        DeleteVehicle(taxi)
    end
end)
