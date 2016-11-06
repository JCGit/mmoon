--- IPv4 address class
-- @classmod IPv4Address

local class = require "util.Class"

--- Constructor.
-- @function IPv4Address
-- @int binary 32-bit integer representing the address.
local IPv4Address = class(function(self, binary)
	self.binary = binary or 0
end)

--- Returns a string representation of the address.
function IPv4Address:to_string()
	return string.format("%d.%d.%d.%d", self:octets())
end

--- Returns the four octets of the address, as separate return values.
function IPv4Address:octets()
	return bit32.extract(self.binary, 24, 8),
	       bit32.extract(self.binary, 16, 8),
	       bit32.extract(self.binary, 8,  8),
	       bit32.extract(self.binary, 0,  8)
end

function IPv4Address:__tostring()
	return self:to_string()
end

function IPv4Address:__eq(other)
	return self.binary == other.binary
end

--- Check wether the address is a valid netmask.
--
-- Netmasks consist of a number of ones, followed by a number of zeros.
-- @treturn bool true if the address is a valid netmask, false otherwise
function IPv4Address:is_valid_netmask()
end

function IPv4Address:is_in_network(network, mask)
end

--- Constructs an address from a string containing four decimal octets
-- separated by dots.
-- @string str string representation of address
function IPv4Address.from_string(str)
	local octets = { str:match("(%d+)%.(%d+)%.(%d+)%.(%d+)") }
	if #octets ~= 4 then
		error("invalid IPv4 address string")
	end

	return IPv4Address.new(bit32.bor(
		bit32.lshift(tonumber(octets[1]), 24),
		bit32.lshift(tonumber(octets[2]), 16),
		bit32.lshift(tonumber(octets[3]), 8),
		bit32.lshift(tonumber(octets[4]), 0)
	))
end

--- Constructs a netmask with the first n bits set to 1.
-- @int n number of bits to be set to 1
function IPv4Address.from_bits(n)
end

return IPv4Address

