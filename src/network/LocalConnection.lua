local LocalConnection = require("util.Class")(function(self)
	self._queue = {}
end)

function LocalConnection.create_pair()
	local conn1, conn2 = LocalConnection.new(), LocalConnection.new()
	conn1._remote = conn2
	conn2._remote = conn1
	return conn1, conn2
end

function LocalConnection:push(message)
	table.insert(self._remote._queue, message)
end

function LocalConnection:pop()
	local message = table.remove(self._queue)
	if not message then return nil end
	return message.type.opcode, message.type.associate_values(message.values)
end

return LocalConnection

