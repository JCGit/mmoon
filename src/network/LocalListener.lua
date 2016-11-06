local LocalEndpoint = require "network.LocalEndpoint"
local LocalConnection = require "network.LocalConnection"

local LocalListener = require"util.Class"(function(
		self, endpoint
	)
	self._queue = {}
	self.endpoint = endpoint or LocalEndpoint.new(self)
	self.endpoint._listener = self
end)

function LocalListener:pop()
	return table.remove(self._queue, 1)
end

function LocalListener:connect(from_endpoint)
	local local_, remote =
		LocalConnection.create_pair(self.endpoint, from_endpoint)
	table.insert(self._queue, remote)
	return local_
end

return LocalListener

