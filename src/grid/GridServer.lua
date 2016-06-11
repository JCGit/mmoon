local util = require "util.Util"
local log = require "log.Logger"
local NodeProtocol = require "grid.NodeProtocol"
local Grid = require "grid.Grid"

local GridServer = require"util.Class"(function(self, listener)
	self._listener = listener
	self._grid = Grid.new()
	self._nodes = {}
	self._pending_nodes = {}
end)

function GridServer:tick()
	for new_node in util.pop_all(self._listener) do
		log.info("New connection")
		table.insert(self._pending_nodes, new_node)
	end

	for i, node in ipairs(self._pending_nodes) do
		for opcode, message in util.pop_all(node) do
			if opcode == NodeProtocol.register.opcode then
				self._nodes[message.id] = node
				log.info(string.format("Node %s/%s registered.",
						message.host, message.id))
				node:push(NodeProtocol.welcome())
			end
		end
	end

	for id, node in pairs(self._nodes) do
		for opcode, message in util.pop_all(node) do
		end
	end
end

return GridServer

