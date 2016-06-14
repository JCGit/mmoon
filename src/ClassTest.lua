local class = require "util.Class"

local Base = class(function(self)
	self.var = 14
end)

function Base:print()
	print(self:format())
end

Base.format = class.VIRTUAL

local Child = class(function(self)
end, Base)

function Child:format()
	return string.format("%02x", self.var)
end


local otherthing = Base.new()
local thing = Child.new()

thing:print()
otherthing:print()
thing.var = 59
otherthing.var = 59
thing:print()
otherthing:print()

