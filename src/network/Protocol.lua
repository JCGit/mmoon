local Protocol = {
	new = function(messages)
		local protocol = { opcode_map = {} }

		for name,message in pairs(messages) do
			protocol[name] = message
			protocol.opcode_map[message.opcode] = message
		end

		return protocol
	end
}

return Protocol

