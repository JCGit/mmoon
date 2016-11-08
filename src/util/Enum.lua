return function(...)
	local enum = {}
	local reverse = {}

	local names = {...}
	for i, name in ipairs(names) do
		enum[name] = i
		reverse[i] = name
	end

	enum.tostring = function(e)
		return reverse[e]
	end

	return enum
end
