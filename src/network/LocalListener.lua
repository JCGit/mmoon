local LocalConnection = require "network.LocalConnection"

local LocalListener = require"util.Class"(function(
		self, protocol
	)
	self._queue = {}
	self.protocol = protocol
end)

function LocalListener:pop()
	return table.remove(self._queue, 1)
end

function LocalListener:connect()
	local local_, remote =
		LocalConnection.create_pair(protocol)
	table.insert(self._queue, remote)
	return local_
end

return LocalListener

