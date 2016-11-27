local util = require "util.Util"
local log = require "log.Logger"
local ServerType = require "proto.ServerType"
local ServerProtocol = require "proto.Server"
local WorldProtocol = require "proto.Node2World"
local NodeProtocol = require "proto.Node2Node"
local MessageHandler = require "network.MessageHandler"
local IPv4Address = require "network.IPv4Address"
local EndpointResolver = require "network.EndpointResolver"

local Node = require "util.Class"(function(
		self, id, host, listener, config, node_type, ...)
	self.id = id
	self.host = host
	self._log_id = { log_id = string.format("%s/%s", host, id) }
	self._config = config
	self._implementation = node_type.new(self, ...)

	self._listener = listener
	self._nodes = {}
	self._pending_servers_in = {}
	self._pending_servers_out = {}
	self._authenticated_servers = {}

	-- startup notice
	log.notice(
		self._log_id,
		string.format("Starting node %s/%s on %s.",
			host,
			id,
			listener.endpoint.address)
		)

	self.world_service = EndpointResolver.resolve(config.world.address):connect(self._listener.endpoint)	

	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self.world_service:push(ServerProtocol.authenticate(id, host, ServerType.NODE, config.security.key))

	-- message handlers
	self._handle_server_messages_in,
	self._handle_server_messages_out,
	self._handle_node_messages = 
		MessageHandler(), MessageHandler(), MessageHandler()
	self._handle_world_messages = self._handle_server_messages_out

	-- register message handlers
	self._handle_server_messages_out[ServerProtocol.welcome] = self._on_welcome
	self._handle_server_messages_in[ServerProtocol.authenticate] = self._on_authenticate
end)

function Node:_on_authenticate(server, message, index)
	-- mark for deletion from pending nodes no matter what happens
	table.insert(self._authenticated_servers, index)

	-- once a node has been registered, check if its key is valid and
	-- then send a welcome message to it 
	if message.key ~= self._config.security.key then
		log.warn(
			string.format(
				self._log_id,
				"Service %s:%s/%s failed authentication with key: %s",
				ServerType.tostring(message.type),
				message.host,
				message.id,
				message.key))
		server:close()
		return
	end

	server:push(ServerProtocol.welcome(self.id, self.host, ServerType.NODE))

	if message.type == ServerType.NODE then
		self:_welcome_node(server, message, index);
	end

	log.info(self._log_id, string.format("%s %s/%s authenticated.",
			ServerType.tostring(message.type), message.host, message.id))
	
	-- returning true here makes the current message handler skip the
	-- rest of the messages in the queue so that it doesn't consume
	-- subsequent messages, meant for the new protocol
	return true
end

function Node:_on_welcome(server, message, id)
	self._pending_servers_out[id] = nil

	if message.type == ServerType.WORLD then
		log.success(self._log_id, "Connected to world service.")

		self._handle_world_messages = MessageHandler()
		self._handle_world_messages[WorldProtocol.node] = function(_, c, msg)
			log.info(self._log_id, "Address to node received: ", IPv4Address.new(msg.address))

			-- connect to this node
			assert(self._config.security.key)

			local remote_node = EndpointResolver.resolve(msg.address):connect()

			-- authenticate and push to pending list
			remote_node:push(ServerProtocol.authenticate(self.id, self.host, ServerType.NODE, self._config.security.key))
			self._pending_servers_out[msg.id] = remote_node

			log.info(self._log_id, string.format("Connecting to %s...", remote_node.endpoint.address))
		end

		self._implementation:on_connected(server)
	elseif message.type == ServerType.NODE then
		log.success(self._log_id, "Successfully connected to node: ", server.endpoint.address)
		table.insert(self._nodes, server)
	end

	return true
end

function Node:_welcome_node(node, message, index)
	table.insert(self._nodes, node)
end

function Node:tick()
	-- accept new node connections
	for new_server in util.pop_all(self._listener) do
		log.info(self._log_id, "New server connection:", new_server.endpoint.address)
		table.insert(self._pending_servers_in, new_server)
	end

	-- receive on pending incoming node connections
	for i, server in ipairs(self._pending_servers_in) do
		self:_handle_server_messages_in(server, i)
	end

	-- remove those marked for removal
	self:_remove_authenticated_servers()

	-- receive on pending outgoing node connections
	for id, server in pairs(self._pending_servers_out) do
		self:_handle_server_messages_out(server, id)
	end

	-- receive on connected nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end

	-- receive on world server
	self:_handle_world_messages(self.world_service, 0)

	-- run node implementation
	self._implementation:tick() -- TODO(deox): (self._event_queue)
end

function Node:_remove_authenticated_servers()
	if #self._authenticated_servers then
		local length = #self._pending_servers_in
		for _, i in ipairs(self._authenticated_servers) do
			self._pending_servers_in[i] = nil
		end

		local new_pending_servers_in = {}
		for i=1, length do
			if self._pending_servers_in[i] then
				new_pending_servers_in[#new_pending_servers_in] = self._pending_servers_in[i]
			end
		end

		self._pending_servers_in = new_pending_servers_in
	end
end

function Node:_handle_messages()
end

return Node

