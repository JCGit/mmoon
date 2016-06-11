local Chunk = require "Chunk"

local Grid = require"util.Class"(function(self)
	self._owners = {}
end)

function Grid:get_chunk(x, y)
	return Chunk.new(x, y)
end

return Grid

