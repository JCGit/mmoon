local function create_timestamp()
	return os.date("%H:%M:%S")
end

local function format(message, color)
	if not color then color = 39 end -- default
	return string.format("\x1B[37m%s \x1B[%sm%s\x1B[0m",
		create_timestamp(), color, message)
end

local function logger(stream, color)
	return function(...)
		stream:write(format(table.concat({...}, "\t") .. "\n", color))
		stream:flush()
	end
end

return {
	info = logger(io.stdout),
	success = logger(io.stdout, 32),
	warn = logger(io.stderr, 33),
	err = logger(io.stderr, 31)
}
