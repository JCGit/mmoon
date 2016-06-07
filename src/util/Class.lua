local function Class(constructor, parent)
	local class = {}

	if parent then
		class = parent.new()
	end

	class.__index = class

	function class.new(...)
		local object = {}
		setmetatable(object, class)
		
		if constructor then
			constructor(object, ...)
		end

		return object
	end

	return class
end

return Class

