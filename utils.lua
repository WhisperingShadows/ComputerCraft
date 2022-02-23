function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function pdump(o)
    print(dump(o))
end

function concat(t, sep)
    if sep == nil then
        sep = ''
    end
    str = ''
    for k,v in pairs(t) do
        str = str..sep..tostring(v)
    end
    return str
end

function contains(x, l)
    for _,v in pairs(l) do
        if v == x then return true end
    end
    return false
end

function is_powered()
    for _,v in pairs(redstone.getSides()) do
        if redstone.getInput(v) then
            return true
        end
    end
    
    return false
end

