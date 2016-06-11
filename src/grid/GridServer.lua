local GridServer = require"util.Class"(function(self, listener)
	self._listener = listener
end)

function GridServer:tick()
end

return GridServer

