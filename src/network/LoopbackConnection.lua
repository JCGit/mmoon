local BinarySerializer = require "network.BinarySerializer"

local LoopbackConnection = require("util.Class")(function(self, protocol)
	self.protocol = protocol
	self._queue = {}
end)

local function dump_buffer(buffer)
	for i, byte in ipairs({buffer:byte(1,#buffer)}) do
		io.write(("%02x"):format(byte) .. " ")
	end
	io.write("\n")
end

local function serialize(message)
	return string.pack(">!1I2", message.type.opcode)
		.. BinarySerializer.serialize(message)
end

local function deserialize(buffer, protocol)
	local opcode, offset = string.unpack(">!1I2", buffer)
	local message_type = protocol.opcode_map[opcode]
	assert(message_type)

	return opcode, BinarySerializer.deserialize(message_type, buffer, offset)
end

function LoopbackConnection:push(message)
	assert(message, "tried to send nil")

	local buffer = serialize(message)
	dump_buffer(buffer)
	table.insert(self._queue, buffer)
end

function LoopbackConnection:pop()
	if #self._queue == 0 then
		return nil
	else
		return deserialize(table.remove(self._queue, 1), self.protocol)
	end
end


return LoopbackConnection

