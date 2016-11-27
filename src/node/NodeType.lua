local class = require "util.Class"

local NodeType = class (function(self)
end)

NodeType.tick = class.VIRTUAL

function NodeType:on_connected(world_server)
end

return NodeType

