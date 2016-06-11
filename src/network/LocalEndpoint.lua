local LocalConnection = require "LocalConnection"

local LocalEndpoint = require"util.Class"(function(self, listener)
	self._listener = listener
end)

function LocalEndpoint:connect()
	local local_, remote = LocalConnection.create_pair()
	table.insert(self._listener._queue, remote)
	return local_
end

return LocalEndpoint

