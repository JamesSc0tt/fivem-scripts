--[[
    This holds all the server events for the taxi job. I've left it stubbed out so you can add your own service calls
]]
RegisterServerEvent('taxi_job:rentCab')
AddEventHandler('taxi_job:rentCab', function()
    --config.rentalPrice
    --remove money from player
end)

RegisterServerEvent('taxi_job:returnCab')
AddEventHandler('taxi_job:returnCab', function()
    --config.returnPrice
    --add money to player
end)

RegisterServerEvent('taxi_job:signOn')
AddEventHandler('taxi_job:signOn', function()
    -- add user to job database to receive player calls
end)

RegisterServerEvent('taxi_job:signOff')
AddEventHandler('taxi_job:signOff', function()
    -- remove user to job database to receive player calls
end)

RegisterServerEvent('taxi_job:success')
AddEventHandler('taxi_job:success', function()
    local tip = math.random(config.payment.tip.min, config.payment.tip.max)
    local payment = math.random(config.payment.min, config.payment.max)
    TriggerClientEvent('chat:addMessage', {
        args = { 'Total Payment: ' .. payment }
    })
end)
