
-- local spawnPos = vector3(282.5254, -345.319, 44.91988)
local spawnPos = vector3(893.1422, -134.7816, 77.32869)
local Keys = {
    ['X'] = 73
}

AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawnCallback(function()
        exports.spawnmanager:spawnPlayer({
            x = spawnPos.x,
            y = spawnPos.y,
            z = spawnPos.z,
            model = 'a_m_m_skater_01'
        })
    end)

    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)

RegisterCommand('car', function(source, args)
    -- account for the argument not being passed
    local vehicleName = args[1] or 'adder'

    -- check if the vehicle actually exists
    if not IsModelInCdimage(vehicleName) or not IsModelAVehicle(vehicleName) then
        TriggerEvent('chat:addMessage', {
            args = { 'It might have been a good thing that you tried to spawn a ' .. vehicleName .. '. Who even wants their spawning to actually ^*succeed?' }
        })

        return
    end

    -- load the model
    RequestModel(vehicleName)

    -- wait for the model to load
    while not HasModelLoaded(vehicleName) do
        Wait(500) -- often you'll also see Citizen.Wait
    end

    -- get the player's position
    local playerPed = PlayerPedId() -- get the local player ped
    local pos = GetEntityCoords(playerPed) -- get the position of the local player ped

    -- create the vehicle
    local vehicle = CreateVehicle(vehicleName, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)

    -- set the player ped into the vehicle's driver seat
    SetPedIntoVehicle(playerPed, vehicle, -1)

    -- give the vehicle back to the game (this'll make the game decide when to despawn the vehicle)
    SetEntityAsNoLongerNeeded(vehicle)

    -- release the model
    SetModelAsNoLongerNeeded(vehicleName)

    -- tell the player
    TriggerEvent('chat:addMessage', {
		args = { 'Woohoo! Enjoy your new ^*' .. vehicleName .. '!' }
	})
end, false)

RegisterCommand('head', function()
    local head = GetEntityHeading(PlayerPedId())
    TriggerEvent('chat:addMessage', {
        args = { head }
    })
end)

RegisterCommand('door', function(source, args)
    SetVehicleDoorOpen(GetVehiclePedIsIn(PlayerPedId(), false), tonumber(args[1]), false, false)
end)

RegisterCommand('autodrive', function(source, args)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed)

    TaskVehicleDriveWander(playerPed, vehicle, 20.0, 536871299)
end, false)

RegisterCommand('tp', function(source, args)
    local waypoint = GetFirstBlipInfoId(8)
   
    if DoesBlipExist(waypoint) then
        local waypointCoord = GetBlipInfoIdCoord(waypoint)
        local trash, z = GetGroundZFor_3dCoord(waypointCoord.x, waypointCoord.y, waypointCoord.z + 99999.0, 1)
        SetEntityCoords(PlayerPedId(), vector3(waypointCoord.x + .0, waypointCoord.y + .0, z + .0))
    else 
        -- waypoint isn't set
    end
end, false)

RegisterCommand('taxi', function()
   TriggerEvent('taxi:hail')
end)

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, Keys['X']) then
            ClearPedTasks(PlayerPedId())
        end
    end
end, false)

CreateThread(function()
    while true do
        Wait(0)
        GetEntitySpeed(PlayerPedId())
    end
end)
