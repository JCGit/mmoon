local BinarySerializer = {}

local TypeNames = {
	int8   = "b",
	uint8  = "B",
	int16  = "i2",
	uint16 = "I2",
	int32  = "i4",
	uint32 = "I4",
	string = "s2"
}

local function build_format_string(fields)
	local types = {}
	for i, arg in ipairs(fields) do
		table.insert(types, TypeNames[arg.type]
			or error("invalid type: " .. arg.type))
	end
	return table.concat(types)
end

function BinarySerializer.serialize(message)
	return string.pack(
		">!1" .. build_format_string(message.type.fields),
			unpack(message.values))
end

function BinarySerializer.deserialize(message, buffer, offset)
	-- Unpack values in buffer
	local values = {
		string.unpack(">!1" .. build_format_string(message.fields),
			buffer, offset)
		}

	local new_offset = table.remove(values)
	return message.associate_values(values), new_offset
end

return BinarySerializer
