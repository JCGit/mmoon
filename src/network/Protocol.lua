local Protocol = {
	new = function(messages)
		local protocol = { _opcode_map = {} }

		for name,message in pairs(messages) do
			protocol[name] = message
			protocol._opcode_map[message.opcode] = message
		end

		-- TODO: decoding opcode here but encoding it in Message.lua is wierd.
		function protocol.decode(buffer)
			local opcode = string.unpack(">!1I2", buffer)

			if not protocol._opcode_map[opcode] then
				error("invalid opcode " .. opcode)
			end

			return opcode, protocol._opcode_map[opcode].decode(buffer)
		end

		return protocol
	end
}

return Protocol

