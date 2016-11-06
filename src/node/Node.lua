local util = require "util.Util"
local log = require "log.Logger"
local WorldProtocol = require "proto.Node2World"
local NodeProtocol = require "proto.Node2Node"
local MessageHandler = require "network.MessageHandler"
local IPv4Address = require "network.IPv4Address"
local EndpointResolver = require "network.EndpointResolver"

local Node = require "util.Class"(function(
		self, id, host, listener, config)
	self.id = id
	self.host = host
	self._log_id = { log_id = string.format("%s/%s", host, id) }
	self._config = config

	self._listener = listener
	self._nodes = {}
	self._pending_nodes_in = {}
	self._pending_nodes_out = {}
	self._authenticated_nodes = {}

	log.notice(self._log_id, string.format("Starting node %s/%s on %s.", host, id, listener.endpoint.address))

	self._world_conn = EndpointResolver.resolve(config.world.address):connect(self._listener.endpoint)	
	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self._world_conn:push(WorldProtocol.register(id, host, config.security.key))

	-- message handlers
	self._handle_node_in_messages,
	self._handle_node_out_messages,
	self._handle_node_messages,
	self._handle_world_messages =
		MessageHandler(), MessageHandler(), MessageHandler(), MessageHandler()

	-- register message handlers
	self._handle_world_messages[WorldProtocol.welcome] = function(_, c, msg)
		log.success(self._log_id, "Connected to world server.")
	end

	self._handle_world_messages[WorldProtocol.node] = function(_, c, msg)
		log.info(self._log_id, "Address to node received: ", IPv4Address.new(msg.address))

		-- connect to this node
		assert(self._config.security.key)

		local remote_node = EndpointResolver.resolve(msg.address):connect()

		-- authenticate and push to pending list
		remote_node:push(NodeProtocol.authenticate(self.id, self.host, self._config.security.key))
		self._pending_nodes_out[msg.id] = remote_node

		log.info(self._log_id, string.format("Connecting to %s...", remote_node.endpoint.address))
	end

	-- nodes that are pending authentication
	self._handle_node_in_messages[NodeProtocol.authenticate] = function(_, c, msg, index)
		if msg.key == self._config.security.key then
			log.info(self._log_id, string.format("Node %s/%s authenticated.",
					msg.host, msg.id))
			c:push(NodeProtocol.welcome())
		else
			log.warn(self._log_id, string.format("Node %s/%s failed authentication with key: %s", msg.host, msg.id, msg.key))
			c:close()
		end
		-- either way, remove from pending
		table.insert(self._authenticated_nodes, index)
	end

	-- nodes that we're waiting to receive confirmation from
	self._handle_node_out_messages[NodeProtocol.welcome] = function(_, c, msg, i)
		log.success(self._log_id, "Successfully connected to node: ", c.endpoint.address)
	end
end)

function Node:tick()
	-- accept new node connections
	for new_node in util.pop_all(self._listener) do
		log.info(self._log_id, "New inter-node connection:", new_node.endpoint.address)
		table.insert(self._pending_nodes_in, new_node)
	end

	-- receive on pending incoming node connections
	for i, node in ipairs(self._pending_nodes_in) do
		self:_handle_node_in_messages(node, i)
	end

	-- remove those marked for removal
	self:_remove_authenticated_nodes()

	-- receive on pending outgoing node connections
	for id, node in pairs(self._pending_nodes_out) do
		self:_handle_node_out_messages(node, id)
	end

	-- receive on connected nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end

	-- receive on world server
	self:_handle_world_messages(self._world_conn)
end

function Node:_remove_authenticated_nodes()
	if #self._authenticated_nodes then
		local length = #self._pending_nodes_in
		for _, i in ipairs(self._authenticated_nodes) do
			self._pending_nodes_in[i] = nil
		end

		local new_pending_nodes_in = {}
		for i=1, length do
			if self._pending_nodes_in[i] then
				new_pending_nodes_in[#new_pending_nodes_in] = self._pending_nodes_in[i]
			end
		end

		self._pending_nodes_in = new_pending_nodes_in
	end
end

function Node:_handle_messages()
end

return Node

