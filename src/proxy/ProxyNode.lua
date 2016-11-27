local LoopbackConnection = require "network.LoopbackConnection"
--local WorldProtocol = require "proto.Proxy2World"
--local NodeProtocol = require "proto.Proxy2Node"
local Message = require "network.Message"
local NodeType = require "node.NodeType"


local Proxy = require "util.Class"(function(self, node, config, listener)
	self._node = node
	self._listener = listener
end, NodeType)

function Proxy:tick()
end

return Proxy

