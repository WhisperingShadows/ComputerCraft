function is_powered()
    for _,v in pairs(redstone.getSides()) do
       if redstone.getInput(v) then
           return true 
       end
    end
    
    return false
end

