require('utils')

rednet.open('back')

rednet.host('port_net', 'port_host')

local locations = {}

function split(inputstr, sep)
    if sep == nil then
        sep = ' '
    end
    
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do 
        if str ~= nil then
            table.insert(t, str)
        end
    end

    return t
end


function save_tp_locs(args)
    local drive = peripheral.find('drive')
    if drive == nil then 
        print('Could not find drive. Locations not saved.')
        return {}
    end

    local side = peripheral.getName(drive)

    if disk.isPresent(side) and disk.hasData(side) then
        local mnt_pth = disk.getMountPath(side)
    else
        print('No disk media inserted. Locations not saved.')
        return {}
    end

    local num = os.epoch()..os.date('_(%F_%H-%M-%S)')
    print(num)

    local file_name = mnt_pth..'/tp_locs/'..num

    print('SAVING LOCS')

    local file = fs.open(file_name, 'w')
    file.write(textutils.serialise(args))
    file.close()
end

function load_tp_locs(rollback)
    if rollback == nil then
        rollback = 0
    end
    local drive = peripheral.find('drive')
    if drive == nil then 
        print('Could not find drive. No saves loaded.')
        return {}
    end

    local side = peripheral.getName(drive)

    if disk.isPresent(side) and disk.hasData(side) then
        local mnt_pth = disk.getMountPath(side)
    else
        print('No disk media inserted. No saves loaded.')
        return {}
    end
    local file_path = mnt_pth..'/tp_locs/'

    local files = fs.list(file_path)

    if #files == 0 then
        print('Could not find any save files. No saves loaded.')
        return {}
    end

    table.sort(files)

    local file_name = file_path..files[1+rollback]

    print('LOADING LOCS')

    local file = fs.open(file_name, 'r')
    local locs = textutils.unserialise(file.readAll())
    file.close()

    return locs
end

function ask_loc(id, user)
    rednet.send(id, {'ask_loc', user}, 'port_net')
    local ret_id, message, proto = rednet.receive('port_net')

    --local coords, dim = message[1], message[2]
    return message
end

function get_user(id)
    rednet.send(id, 'ask_user', 'port_net')
    local ret_id, message, proto = rednet.receive('port_net')
    return message
end

function confirm(id, message)
    if id == nil then
        return nil
    end

    if message == nil then
        message = 'Confirm (Y/N) : '
    else
        message = message..' (Y/N) : '
    end

    rednet.send(id, {'confirm', message}, 'port_net')
    local ret_id, message, proto = rednet.receive('port_net')

    if contains(message:lower(), {'y', 'yes'}) then
        return true
    elseif contains(message:lower(), {'n', 'no'}) then
        return false
    else
        return confirm(message, id)
    end
end

function loc_add(name, data, id)
    if id ~= nil and locations[name] ~= nil and not confirm(id, 'Overwrite location?') then
        return false
    end

    locations[name] = data
    return true
end

function loc_remove(name, id)
    if id ~= nil and locations[name] ~= nil and not confirm(id, 'Delete location?') then
        return false
    end

    locations[name] = nil
    return true
end

function teleport(loc, dim, entity, id)
    if entity == nil then
        entity = get_user(id)
    end

    
    exec('execute in '..dim..' run tp '..entity..' '..loc)
    -- exec('tp '..entity..' '..loc)
end

function process_incoming(id, message)
    local chunks = split(message)
        
        if contains(chunks[1],{'silent', 's'}) then  
            table.remove(chunks, 1)
        else
            print('=========')
            print('COMMAND: '..message)
        end
                                                    
            
        if chunks[1] == 'add' then
            print('ADDING LOC')
                
            if #chunks == 5 then
                --locations[chunks[2]] = {chunks[3]..' '..chunks[4]..' '..chunks[5], ask_loc(id)[2]}
                loc_add(chunks[2], {chunks[3]..' '..chunks[4]..' '..chunks[5], ask_loc(id)[2]}, id)
            else
                --locations[chunks[2]] = ask_loc(id)
                loc_add(chunks[2], ask_loc(id), id)
            end 

            save_tp_locs(locations)

            write('NEW LOC LIST: ')
            pdump(locations)

        elseif contains(chunks[1], {'remove', 'rmv', 'rm'}) then
            loc_remove(chunks[2], id)
            save_tp_locs(locations)

            write('NEW LOC LIST: ')
            pdump(locations)
        
        elseif chunks[1] == 'loc' then
            print('FETCHING LOC')
                
            local output = ''
                
            for k,v in pairs(locations) do
               output = output..tostring(k)..': '..tostring(v[1])..' ('..tostring(v[2])..')\n' 
            end
            output = output:gsub('\n'..'$', '')
            
            -- use #locations instead?
            if next(locations) == nil then
                print('Here')
                output = 'None'
            end
            rednet.send(id, output, 'port_net')
            print(output)

        elseif chunks[1] == 'rename' then
            local old = chunks[2]
            local new = chunks[3]

            loc_add(new, locations[old], id)
            loc_remove(old)


        elseif contains(chunks[1], {'teleport', 'tp'}) then
            print(chunks[2])
            print(locations[chunks[2]][1])
            print('TELEPORTING to '..chunks[2]..' ('..locations[chunks[2]][1]..')')
            teleport(locations[chunks[2]][1], locations[chunks[2]][2], chunks[3], id)            
        end
end

function handle_incoming(client_id, message_first)
    process_incoming(client_id, message_first)

    while true do
        if connection_list['id'..client_id] == nil then
            print('exiting handler '..client_id)
            return false
        end

        local id, message, proto = rednet.receive('port_net')

        if id == client_id and connection_list['id'..id] ~= nil then
            process_incoming(id, message)        
        end
    end
end

-- function handle_server_status()
--     while true do
--         local id, message, proto = rednet.receive('port_net')
--         if message == 'silent ping' then
--             rednet.send(id, 'pong', 'port_net')
--         end
--     end
-- end

local locations = load_tp_locs()

connection_list = {}
resp_list = {}

function is_connected()
    while true do
        local id, message, proto = rednet.receive('port_net', 5)
        if message == 'silent ping' then
            rednet.send(id, 'pong', 'port_net')
            resp_list['id'..id] = id

        -- perhaps rather than using a 5 second timer, just check for connection list staleness?
        -- would have to modify ping to use different protocol for each connection though
        -- if id == nil and message == nil then 
        --     connection_list[client_id] = nil
        end
    end
end

function cleaner()
    while true do
        sleep(6)
        local inter_list = connection_list
        for k,v in pairs(connection_list) do
            if resp_list['id'..v] == nil then
                print(tostring(v)..' disconnected')
                inter_list[k] = nil
            end
        end
        connection_list = inter_list
        resp_list = {}
    end
end

function new_connection(client_id, message)
    if connection_list['id'..client_id] == nil then
        print(tostring(client_id)..' connected')
        connection_list['id'..client_id] = client_id
        os.startThread(function () handle_incoming(client_id, message) end)
    end
end

function threadMain() 
    
    os.startThread(cleaner)
    os.startThread(is_connected)

    while true do
        local id, message, proto = rednet.receive('port_net')

        new_connection(id, message)
    end
end

require('threading')
