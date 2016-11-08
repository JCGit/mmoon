local util = require "util.Util"
local log = require "log.Logger"
local ServiceType = require "proto.ServiceType"
local ServiceProtocol = require "proto.Service"
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
	self._pending_services_in = {}
	self._pending_services_out = {}
	self._authenticated_services = {}

	-- startup notice
	log.notice(
		self._log_id,
		string.format("Starting node %s/%s on %s.",
			host,
			id,
			listener.endpoint.address)
		)

	self._world_server = EndpointResolver.resolve(config.world.address):connect(self._listener.endpoint)	

	-- either we have to wait for some connected event here or I suppose
	-- the send queue could be processed in the networking thread as soon
	-- as it connects
	self._world_server:push(ServiceProtocol.authenticate(id, host, ServiceType.NODE, config.security.key))

	-- message handlers
	self._handle_service_messages_in,
	self._handle_service_messages_out,
	self._handle_node_messages = 
		MessageHandler(), MessageHandler(), MessageHandler()
	self._handle_world_messages = self._handle_service_messages_out

	-- register message handlers
	self._handle_service_messages_out[ServiceProtocol.welcome] = self._on_welcome
	self._handle_service_messages_in[ServiceProtocol.authenticate] = self._on_authenticate
end)

function Node:_on_authenticate(service, message, index)
	-- mark from deletion from pending nodes no matter what happens
	table.insert(self._authenticated_services, index)

	-- once a node has been registered, check if its key is valid and
	-- then send a welcome message to it 
	if message.key ~= self._config.security.key then
		log.warn(
			string.format(
				self._log_id,
				"Service %s:%s/%s failed authentication with key: %s",
				ServiceType.tostring(message.type),
				message.host,
				message.id,
				message.key))
		service:close()
		return
	end

	service:push(ServiceProtocol.welcome(self.id, self.host, ServiceType.NODE))

	if message.type == ServiceType.NODE then
		self:_welcome_node(service, message, index);
	end

	log.info(self._log_id, string.format("%s %s/%s authenticated.",
			ServiceType.tostring(message.type), message.host, message.id))
	
	-- returning true here makes the current message handler skip the
	-- rest of the messages in the queue so that it doesn't consume
	-- subsequent messages, meant for the new protocol
	return true
end

function Node:_on_welcome(service, message, id)
	self._pending_services_out[id] = nil

	if message.type == ServiceType.WORLD then
		log.success(self._log_id, "Connected to world server.")

		-- TODO: we can't switch like this: the current message handler
		-- pops ALL messages and when processing this one, the node messages
		-- are already in the queue
		self._handle_world_messages = MessageHandler()
		self._handle_world_messages[WorldProtocol.node] = function(_, c, msg)
			log.info(self._log_id, "Address to node received: ", IPv4Address.new(msg.address))

			-- connect to this node
			assert(self._config.security.key)

			local remote_node = EndpointResolver.resolve(msg.address):connect()

			-- authenticate and push to pending list
			remote_node:push(ServiceProtocol.authenticate(self.id, self.host, ServiceType.NODE, self._config.security.key))
			self._pending_services_out[msg.id] = remote_node

			log.info(self._log_id, string.format("Connecting to %s...", remote_node.endpoint.address))
		end
	elseif message.type == ServiceType.NODE then
		log.success(self._log_id, "Successfully connected to node: ", service.endpoint.address)
		table.insert(self._nodes, service)
	end

	return true
end

function Node:_welcome_node(node, message, index)
	table.insert(self._nodes, node)
end

function Node:tick()
	-- accept new node connections
	for new_service in util.pop_all(self._listener) do
		log.info(self._log_id, "New service connection:", new_service.endpoint.address)
		table.insert(self._pending_services_in, new_service)
	end

	-- receive on pending incoming node connections
	for i, service in ipairs(self._pending_services_in) do
		self:_handle_service_messages_in(service, i)
	end

	-- remove those marked for removal
	self:_remove_authenticated_services()

	-- receive on pending outgoing node connections
	for id, service in pairs(self._pending_services_out) do
		self:_handle_service_messages_out(service, id)
	end

	-- receive on connected nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end

	-- receive on world server
	self:_handle_world_messages(self._world_server, 0)
end

function Node:_remove_authenticated_services()
	if #self._authenticated_services then
		local length = #self._pending_services_in
		for _, i in ipairs(self._authenticated_services) do
			self._pending_services_in[i] = nil
		end

		local new_pending_services_in = {}
		for i=1, length do
			if self._pending_services_in[i] then
				new_pending_services_in[#new_pending_services_in] = self._pending_services_in[i]
			end
		end

		self._pending_services_in = new_pending_services_in
	end
end

function Node:_handle_messages()
end

return Node

