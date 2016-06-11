local function create_timestamp()
	return os.date("%H:%M:%S")
end

local function format(message, identifier, color)
	local info = debug.getinfo(3, "nSl")

	return string.format("\x1B[37m%s %s@%s:%s%s | \x1B[%sm%s\x1B[0m",
		create_timestamp(),
		info.name, info.short_src, info.currentline,
		identifier and "/" .. identifier or "",
		color, message)
end

local function logger(stream, color)
	return function(...)
		local message = {...}

		-- if an argument is a table, use its first element as an intance
		-- identifier
		local identifier = nil
		for i, str in ipairs(message) do
			if type(str) == "table" then
				identifier = str[1]
				table.remove(message, i)
				break
			end
		end

		stream:write(format(table.concat(message, "\t") .. "\n", identifier,
			color))
		stream:flush()
	end
end

return {
	info = logger(io.stdout, 39),
	success = logger(io.stdout, 32),
	warn = logger(io.stderr, 33),
	err = logger(io.stderr, 31)
}

