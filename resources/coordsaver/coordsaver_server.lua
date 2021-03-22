
RegisterServerEvent('SaveCoords')
AddEventHandler('SaveCoords', function(x, y, z)
 file = io.open(GetPlayerName(source) .. '-Coords.txt', 'a')
    if file then
        file:write('vector3(' .. x .. ',' .. y .. ',' .. z .. '),\n')
    end
    file:close()
end)
