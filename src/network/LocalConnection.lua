local LocalEndpoint = require "network.LocalEndpoint"

local LocalConnection = require("util.Class")(function(self,
		endpoint)
	self._queue = {}
	self.endpoint = endpoint
end)

function LocalConnection.create_pair(endpoint1, endpoint2)
	if not endpoint1 then
		endpoint1 = LocalEndpoint.new(nil)
	end
	if not endpoint2 then
		endpoint2 = LocalEndpoint.new(nil)
	end

	local conn1, conn2 =
		LocalConnection.new(endpoint1),
		LocalConnection.new(endpoint2)
	conn1._remote = conn2
	conn2._remote = conn1
	return conn1, conn2
end

function LocalConnection:push(message)
	table.insert(self._remote._queue, message)
end

function LocalConnection:pop()
	local message = table.remove(self._queue, 1)
	if not message then return nil end
	return message.type.opcode, message.type.associate_values(message.values)
end

function LocalConnection:close()
end

return LocalConnection

