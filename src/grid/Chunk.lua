local Chunk = require"util.Class"(function(self, x, y, owner)
	self.x, self.y = x, y
	self._owner = owner
end)
