local class = require "util.Class"
local NodeType = require "node.NodeType"

local SimulationNode = class (function(self)
end, NodeType)

function SimulationNode:tick()
end

return SimulationNode

