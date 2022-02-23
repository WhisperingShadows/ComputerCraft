drive = peripheral.find('drive')
side = peripheral.getName(drive)

local args = {...}

mnt_pth = disk.getMountPath(side)

num = os.date('%F_%H-%M-%S')..'_('..os.epoch()..')'
print(num)

file_name = mnt_pth..'/tp_locs_'..num

print('WRITING TO '..file_name)

local file = fs.open(file_name, 'w')
file.write(textutils.serialise(args))
file.close()


