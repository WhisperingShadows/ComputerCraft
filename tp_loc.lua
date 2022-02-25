require('utils')

function connect()
    rednet.open('back')
    local id = rednet.lookup('port_net', 'port_host')
    print(id)
    return id
end

function assign_pocket()
    rednet.send(server, 'silent get_online', 'port_net')
    local id, message, proto = rednet.receive('port_net')
    user_completion = message
    
    print('To facilitate mobile global positioning you must assign this device to a specific user. Please input your username.')
    write('Username: ')
    local input = read(nil, nil, user_completion)
    
    settings.set('user', input)
    settings.save()
    
    return input
end

function get_pos()
    local x,y,z = commands.getBlockPosition()
    return x..' '..y..' '..z
end

function get_dim()
    local _, out, _ = exec('data get entity @p Dimension')
    res = string.match(out[1], [["([^"]+)]])
    return res
end

function get_user()
    local user =''
    if pocket then
        user = settings.get('user')
        if user == nil then
            user = assign_pocket()
        end
    else
        user = '@p'
    end

    return user
end

function get_loc_pocket(user)
    if user == nil then
        user = settings.get('user')
        if user == nil then
            user = assign_pocket()
        end
    end
    
    rednet.open('back')
    local host = rednet.lookup('user_pos', 'host')
    rednet.send(host, user, 'user_pos')
    local id, message, proto = rednet.receive('user_pos')
    
    --local coords, dim = message[1], message[2]
    return message
end

if pocket then
    get_loc = get_loc_pocket
else
    get_loc = function() return {get_pos(), get_dim()} end
end

function handle_incoming()
    while true do
        local id, message, proto = rednet.receive('port_net')
        if message[1] == 'ask_loc' then
            rednet.send(id, get_loc(message[2]), 'port_net')
        elseif message == 'ask_user' then
            rednet.send(id, get_user(), 'port_net')
        elseif message[1] == 'confirm' then
            write(message[2])
            local input = read()
            rednet.send(id, input, 'port_net')
        elseif message == 'pong' then
        
        else
            print(message)
        end
    end
end        


rednet.send(server, 'silent get_comp_func', 'port_net')
local id, message, proto = rednet.receive('port_net')
input_completion_func = message

function handle_outgoing(server)
    local history = {}
    
    while true do
        local input = read(nil, history, input_completion_func, nil)
        -- TODO: Autocompletion
        
        if input ~= history[1] then
            table.insert(history, 1, input)
        end
        
        if contains(input, {'quit', 'exit', 'q'}) then
            return
        end        
        rednet.send(server, input, 'port_net')
    end
end

function is_connected(server)
    while true do
        rednet.send(server, 'silent ping', 'port_net')
        local id, message, proto = rednet.receive('port_net', 5)
    
        if id == nil and message == nil then
            print('Connection to server lost.')
            return
        else    
            sleep(5)
        end
    end
end

if settings.get('user') == nil then
    assign_pocket()
end

local server = connect()

parallel.waitForAny(handle_incoming, function() handle_outgoing(server) end, function() is_connected(server) end)

print('Shutting down')
