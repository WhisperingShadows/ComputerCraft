rednet.open('back')

local args = {...}

if #args < 1 then
    args[1] = read()
end

local id = rednet.lookup('port_net', 'port_host')

local x,y,z = commands.getBlockPosition()

rednet.send(id, 'net add '..args[1]..' '..x..' '..y..' '..z, 'port_net')


--TODO: FIX FOR PORTABLE