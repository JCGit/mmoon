local LoopbackConnection = require "network.LoopbackConnection"
local log = require "log.Logger"
local util = require "util.Util"
--local WorldProtocol = require "proto.ProxyNode2World"
--local NodeProtocol = require "proto.ProxyNode2Node"
local PlayerConnection = require "proxy.PlayerConnection"
local Message = require "network.Message"
local NodeType = require "node.NodeType"


local ProxyNode = require "util.Class"(function(self, node, config, listener)
	self._node = node
	self._listener = listener
	self._log_id = { log_id = string.format("%s/%s", node.host, node.id) }

	self._clients = {}

	-- startup notice
	log.notice(
		self._log_id,
		string.format("Starting proxy %s/%s on %s.",
			node.host,
			node.id,
			listener.endpoint.address)
		)
	
end, NodeType)

function ProxyNode:tick()
	for new_client in util.pop_all(self._listener) do
		log.info(self._log_id, "New client connection:", new_client.endpoint.address)
		table.insert(self._clients, PlayerConnection.new(new_client))
	end

	for i, client in ipairs(self._clients) do
		client:tick()
	end
end

return ProxyNode

