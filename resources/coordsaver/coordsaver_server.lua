
RegisterServerEvent('SaveCoords')
AddEventHandler('SaveCoords', function(x, y, z, h )
 file = io.open(GetPlayerName(source) .. '-Coords.txt', 'a')
    if file then
        file:write('vector4(' .. x .. ',' .. y .. ',' .. z .. ',' .. h .. '),\n')
    end
    file:close()
end)
