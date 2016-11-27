local LoopbackConnection = require "network.LoopbackConnection"
--local WorldProtocol = require "proto.Proxy2World"
--local NodeProtocol = require "proto.Proxy2Node"
local Message = require "network.Message"
local Node = require "node.Node"


local Proxy = require "util.Class"(function(self, listener, config)
	self._listener = listener
end, Node)

function Proxy:tick()
	Node.tick(self)
end

return Proxy

