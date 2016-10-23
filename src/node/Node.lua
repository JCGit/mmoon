local util = require "util.Util"
local log = require "log.Logger"
local Protocol = require "proto.NodeGridProtocol"
local MessageHandler = require "network.MessageHandler"

local Node = require "util.Class"(function(
		self, id, host, listener, grid_endpoint)
	self.id = id
	self.host = host
	self._log_id = { string.format("%s/%s", host, id) }

	self._listener = listener
	self._nodes = {}
	self._pending_nodes = {}

	self._grid_conn = grid_endpoint:connect(Protocol)	
	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self._grid_conn:push(Protocol.register(id, host))

	self._handle_node_messages, self._handle_grid_messages =
		MessageHandler(), MessageHandler()

	self._handle_grid_messages[Protocol.welcome] = function(_, c, msg)
		log.success(self._log_id, "Connected to grid system.")
	end
end)

function Node:tick()
	-- accept new node connections
	for new_node in util.pop_all(self._listener) do
		table.insert(self._pending_nodes, new_node)
	end

	-- receive on pending nodes
	for node in ipairs(self._pending_nodes) do
		self:_handle_node_messages(node)
	end

	-- receive on connected nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node)
	end

	-- receive on grid server
	self:_handle_messages(self._grid_conn)
end

function Node:_handle_messages()
end

return Node

