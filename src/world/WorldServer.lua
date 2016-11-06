local util = require "util.Util"
local log = require "log.Logger"
local MessageHandler = require "network.MessageHandler"
local Protocol = require "proto.Node2World"

local WorldServer = require"util.Class"(function(self, listener, config)
	self._listener = listener
	self._config = config

	log.notice(string.format("Starting world server on %s.", listener.endpoint.address))

	-- services
	self._proxies = {}
	self._nodes = {}

	self._pending_nodes = {}
	self._registered_nodes = {}

	self._handle_messages = MessageHandler()
	self._handle_messages[Protocol.register] = self._on_register
end)

function WorldServer:_on_register(node, message, index)
	-- mark from deletion from pending nodes no matter what happens
	table.insert(self._registered_nodes, index)

	-- once a node has been registered, check if its key is valid and
	-- then send a welcome message to it 
	if message.key ~= self._config.security.key then
		log.warn(string.format("Node %s/%s failed authentication with key: %s",
				message.host, message.id, message.key))
		node:close()
		return
	end

	node:push(Protocol.welcome())

	-- now send the addresses of all the proxies
	for _, proxy in ipairs(self._proxies) do
		node:push(Protocol.proxy(proxy.endpoint.address.binary))
	end

	-- and all nodes
	for id, other_node in pairs(self._nodes) do
		log.info(string.format("Sending address of node %s to %s/%s (%s):",
			id,
			message.host,
			message.id,
			node.endpoint.address), other_node.endpoint.address)

		node:push(Protocol.node(id, other_node.endpoint.address.binary))
	end

	-- add to list of active nodes
	self._nodes[message.id] = node

	log.info(string.format("Node %s/%s registered.",
			message.host, message.id))
end

function WorldServer:tick()
	-- accept new node connections
	for new_node in util.pop_all(self._listener) do
		log.info("New connection: ", new_node.endpoint.address)
		table.insert(self._pending_nodes, new_node)
	end

	-- receive on nodes pending authentication
	for i, node in ipairs(self._pending_nodes) do
		self:_handle_messages(node, i)
	end

	-- remove those pending nodes that are registered
	self:_remove_registered_nodes()

	for id, node in pairs(self._nodes) do
		self:_handle_messages(node, id)
	end
end

function WorldServer:_remove_registered_nodes()
	if #self._registered_nodes then
		local length = #self._pending_nodes
		for _, i in ipairs(self._registered_nodes) do
			self._pending_nodes[i] = nil
		end

		local new_pending_nodes = {}
		for i=1, length do
			if self._pending_nodes[i] then
				new_pending_nodes[#new_pending_nodes] = self._pending_nodes[i]
			end
		end

		self._pending_nodes = new_pending_nodes
	end
end

return WorldServer

