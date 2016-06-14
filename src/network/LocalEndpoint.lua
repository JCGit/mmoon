local LocalEndpoint = require"util.Class"(function(self, listener)
	self._listener = listener
end)

function LocalEndpoint:connect()
	return self._listener:connect()
end

return LocalEndpoint

