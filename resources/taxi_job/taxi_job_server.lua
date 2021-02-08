--[[
    This holds all the server events for the taxi job. I've left it stubbed out so you can add your own service calls
]]
RegisterServerEvent('taxi_job:rentCab')
AddEventHandler('taxi_job:rentCab', function(distance)
    --config.rentalPrice
    --remove money
end)

RegisterServerEvent('taxi_job:returnCab')
AddEventHandler('taxi_job:returnCab', function(distance)
    --config.returnPrice
    --add money
end)

RegisterServerEvent('taxi_job:success')
AddEventHandler('taxi_job:success', function(distance)
    local payment = math.ceil(distance * config.pricePerMile * config.priceMultiplier)
    --pay player
end)
