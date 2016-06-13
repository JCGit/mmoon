local util = require "util.Util"
local log = require "log.Logger"
local Protocol = require "proto.NodeGridProtocol"
local MessageHandler = require "network.MessageHandler"

local Node = require "util.Class"(function(self, id, host, grid_endpoint)
	self.id = id
	self.host = host
	self._log_id = { string.format("%s/%s", host, id) }

	self._grid_conn = grid_endpoint:connect(Protocol)
	
	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self._grid_conn:push(Protocol.register(id, host))

	self._handle_messages = MessageHandler(Protocol)
	self._handle_messages[Protocol.welcome] = function(_, c, msg)
		log.success(self._log_id, "Connected to grid system.")
	end
end)

function Node:tick()
	self:_handle_messages(self._grid_conn)
end

return Node

