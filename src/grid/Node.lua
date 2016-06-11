local util = require "util.Util"
local log = require "log.Logger"
local NodeProtocol = require "grid.NodeProtocol"

local Node = require "util.Class"(function(self, id, host, grid_endpoint)
	self.id = id
	self.host = host
	self._log_id = { string.format("%s/%s", host, id) }

	self._grid_conn = grid_endpoint:connect(NodeProtocol)
	
	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self._grid_conn:push(NodeProtocol.register(id, host))
end)

function Node:tick()
	for opcode, message in util.pop_all(self._grid_conn) do
		if opcode == NodeProtocol.welcome.opcode then
			log.success(self._log_id, "Connected to grid system.")
		end
	end
end

return Node

