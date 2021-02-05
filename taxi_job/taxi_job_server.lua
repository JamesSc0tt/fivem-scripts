pricePerMile = 1
priceMultiplier = 1

RegisterServerEvent('taxi_job:rentCab')
AddEventHandler('taxi_job:rentCab', function(distance)
    --remove money
end)

RegisterServerEvent('taxi_job:success')
AddEventHandler('taxi_job:success', function(distance)
    local payment = distance * pricePerMile * priceMultiplier
    --Pay player with db call
end)
