local VirtualAddress = require "network.VirtualAddress"

local LocalEndpoint = require"util.Class"(function(self, listener, address)
	self._listener = listener

	if address then
		self.address = address
	else
		self.address = VirtualAddress.claim(self)
	end
end)

function LocalEndpoint:connect(from_endpoint)
	assert(self._listener, "endpoint doesn't point to a listener")
	return self._listener:connect(from_endpoint)
end

return LocalEndpoint

