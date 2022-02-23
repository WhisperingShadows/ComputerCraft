
function save_tp_locs(args)
	local drive = peripheral.find('drive')
	local side = peripheral.getName(drive)

	local mnt_pth = disk.getMountPath(side)

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
	local side = peripheral.getName(drive)

	local mnt_pth = disk.getMountPath(side)
	local file_path = mnt_pth..'/tp_locs/'

	local files = fs.list(file_path)

	table.sort(files)

	local file_name = file_path..files[1+rollback]

	print('LOADING LOCS')

	local file = fs.open(file_name, 'r')
	local locs = textutils.unserialise(file.readAll())
	file.close()

	return locs
end