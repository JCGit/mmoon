local type_names = {
	int8   = "b",
	uint8  = "B",
	int16  = "i2",
	uint16 = "I2",
	int32  = "i4",
	uint32 = "I4",
	string = "s2"
}

local function parse_fields(args)
	local fields = {}
	for i, str in ipairs(args) do
		local name, t = str:match("(.+):(.+)")
		table.insert(fields, { name = name, type = type_names[t] or t })
	end
	return fields
end

local function build_format_string(fields)
	local types = {}
	for i, arg in ipairs(fields) do
		table.insert(types, arg.type)
	end
	return table.concat(types)
end

local function Message(opcode, ...)
	-- Save args in array
	local args = {...}

	-- Parse args as fields
	local fields = parse_fields(args)

	-- Build format string with fields and prepend
	-- settings for big endian (network byte order), alignment and an opcode
	-- TODO: encoding opcode here but decoding it in Protocol.lua is wierd.
	local format_string = ">!1I2" .. build_format_string(fields)

	-- Save values for future reference
	local object = {
		opcode = opcode,
		decode = function(buffer)
			-- Unpack values in buffer
			local values = { string.unpack(format_string, buffer) }
			local opcode = table.remove(values, 1)
			table.remove(values, #values)

			-- Create table with fields[i] = values[i] 
			local msg = {}
			for i,field in ipairs(fields) do
				msg[field.name] = values[i]
			end
			return msg
		end
	}

	-- Set meta table to be able to call message object with arguments to
	-- encode a message
	setmetatable(object,
	{
		__call = function(_, ...)
			return string.pack(format_string, opcode, ...)
		end
	})

	return object
end

return Message

