local function create_timestamp()
	return os.date("%H:%M:%S")
end

local function format(message, identifier, color)
	local info = debug.getinfo(3, "nSl")

	local header = string.format("\x1B[37m%s %s@%s:%s%s",
		create_timestamp(),
		info.name, info.short_src, info.currentline,
		identifier and "/" .. identifier or "")

	return string.format("%-60s -- \x1B[%sm%s\x1B[0m",
		header, color, message)
end

local function logger(stream, color)
	return function(...)
		local message = {...}

		-- if an argument is a table that contains a "log_id" field, use that
		-- field as an instance identifier
		local identifier = nil
		for i, str in ipairs(message) do
			if type(str) == "table" and str.log_id then
				identifier = str.log_id
				table.remove(message, i)
				break
			end
		end

		-- convert all parameters to their string representations
		for i, str in ipairs(message) do
			message[i] = tostring(str)
		end

		stream:write(format(table.concat(message, "\t") .. "\n", identifier,
			color))
		stream:flush()
	end
end

return {
	info = logger(io.stdout, "39"),
	notice = logger(io.stdout, "34"),
	success = logger(io.stdout, "32"),
	warn = logger(io.stderr, "33"),
	err = logger(io.stderr, "31")
}

