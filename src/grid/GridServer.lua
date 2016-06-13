local util = require "util.Util"
local MessageHandler = require "network.MessageHandler"
local log = require "log.Logger"
local NodeProtocol = require "grid.NodeProtocol"
local Grid = require "grid.Grid"

local GridServer = require"util.Class"(function(self, listener)
	self._listener = listener
	self._grid = Grid.new()
	self._nodes = {}
	self._pending_nodes = {}

	self._handle_messages = MessageHandler(NodeProtocol)
	self._handle_messages[NodeProtocol.register] = self._on_register
end)

function GridServer:_assign_node(node, x, y)
	local last_owner = self._grid:assign_node(node, x, y)
end

function GridServer:_on_register(node, message)
	self._nodes[message.id] = node
	log.info(string.format("Node %s/%s registered.",
			message.host, message.id))
	node:push(NodeProtocol.welcome())
end

function GridServer:tick()
	for new_node in util.pop_all(self._listener) do
		log.info("New connection")
		table.insert(self._pending_nodes, new_node)
	end

	for i, node in ipairs(self._pending_nodes) do
		self:_handle_messages(node)
	end

	for id, node in pairs(self._nodes) do
		self:_handle_messages(node)
	end
end

return GridServer

