local IPv4Address = require "network.IPv4Address"


local addresses = {}

local SUBNET      = 0x7fff0000
local SUBNET_MASK = 0xffff0000


local VirtualAddress = {}

function VirtualAddress.claim(listener)
	local i = 1
	while addresses[i] ~= nil do
		i = i + 1
	end
	
	addresses[i] = listener

	return IPv4Address.new(SUBNET + i)
end

function VirtualAddress.resolve(address)
	if bit32.band(address, SUBNET_MASK) == SUBNET then
		-- if this address is in the virtual subnet, return a LocalEndpoint
		-- pointing to the listener assigned to that virtual address
		local virtual_host = bit32.band(address,
			bit32.bnot(SUBNET_MASK))
		return addresses[virtual_host],
			IPv4Address.new(address)
	end

	return nil
end

return VirtualAddress

