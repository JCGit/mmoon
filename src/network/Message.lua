local function parse_fields(args)
	local fields = {}
	for i, str in ipairs(args) do
		local name, t = str:match("(.+):(.+)")
		table.insert(fields, { name = name, type = t })
	end
	return fields
end

local function Message(opcode, ...)
	-- Save args in array
	local args = {...}

	-- Parse args as fields
	local fields = parse_fields(args)

	-- Save values for future reference
	local object = {
		opcode = opcode,
		fields = fields,

		associate_values = function(values)
			local msg = {}
			for i,field in ipairs(fields) do
				msg[field.name] = values[i]
			end
			return msg
		end
	}

	-- Set meta table to be able to call message object with field values as
	-- arguments to build a message instance
	setmetatable(object,
	{
		__call = function(_, ...)
			return { type = object, values = {...} }
		end
	})

	return object
end

return Message

