local Chunk = require "grid.Chunk"

local Grid = require"util.Class"(function(self)
	self._chunks = {}
end)

function Grid:get_chunk(x, y)
	return Chunk.new(x, y)
end

function Grid:assign_node(node_id, x, y)
	local chunk = self._chunks[y][x]
	if chunk then
		local current_owner = chunk.owner
		chunk.owner = node_id
		return current_owner
	else
		self._chunks[y][x] = Chunk.new(x, y, node_id)
		return nil
	end
end

return Grid

