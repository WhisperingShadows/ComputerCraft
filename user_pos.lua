
function assign_pocket()
    print('To facilitate mobile global positioning you must assign this device to a specific user. Please input your username.')
    write('Username: ')
    local input = read()
    
    settings.set('user', input)
    
    return input
end

function get_pos(user)

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

while true do
    print(get_pos())
end

