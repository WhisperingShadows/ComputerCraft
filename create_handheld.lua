drive = peripheral.find('drive')

side = peripheral.getName(drive)

local function getRunningPath()
    local runningProgram = shell.getRunningProgram()
    local programName = fs.getName(runningProgram)
    if programName == runningProgram then
        return '.'
    else
        return runningProgram:sub(1, #runningProgram - #programName - 1)
    end
end

if disk.isPresent(side) and disk.hasData(side) then
    
    mnt_pth = disk.getMountPath(side)..'/port_net'
    run_pth = getRunningPath()

    if fs.exists(mnt_pth) then
        print('RMV OLD')
        fs.delete(mnt_pth)
    end
    
    fs.copy(run_pth, mnt_pth)
    
    print('COPIED '..run_pth..' TO '..mnt_pth)
                        
end
