local LocalListener = require"util.Class"(function(self)
	self._queue = {}
end)

function LocalListener:pop()
	return table.remove(self._queue, 1)
end

return LocalListener

