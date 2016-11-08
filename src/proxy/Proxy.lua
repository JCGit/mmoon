local LoopbackConnection = require "network.LoopbackConnection"
--local WorldProtocol = require "proto.Proxy2World"
--local NodeProtocol = require "proto.Proxy2Node"
local Message = require "network.Message"


local Proxy = require "util.Class"(function(self, listener, config)
	self._listener = listener
end)

function Proxy:tick()
end

return Proxy

