local util = require "util.Util"
local log = require "log.Logger"
local MessageHandler = require "network.MessageHandler"
local NodeProtocol = require "proto.Node2World"
local ServiceProtocol = require "proto.Service"
local ServiceType = require "proto.ServiceType"

local WorldServer = require"util.Class"(function(self, listener, config)
	self._listener = listener
	self._config = config

	log.notice(string.format("Starting world server on %s.", listener.endpoint.address))

	-- services
	self._proxies = {}
	self._nodes = {}

	self._pending_services = {}
	self._authenticated_services = {} -- TODO: rename

	-- message handlers
	self._handle_service_messages, self._handle_node_messages =
		MessageHandler(),
		MessageHandler()

	self._handle_service_messages[ServiceProtocol.authenticate] = self._on_authenticate
end)

function WorldServer:_on_authenticate(service, message, index)
	-- mark from deletion from pending nodes no matter what happens
	table.insert(self._authenticated_services, index)

	-- once a node has been registered, check if its key is valid and
	-- then send a welcome message to it 
	if message.key ~= self._config.security.key then
		log.warn(
			string.format(
				"Service %s:%s/%s failed authentication with key: %s",
				ServiceType.tostring(message.type),
				message.host,
				message.id,
				message.key))
		service:close()
		return
	end

	service:push(ServiceProtocol.welcome(
			0,
			tostring(self._listener.endpoint.address),
			ServiceType.WORLD
		))

	if message.type == ServiceType.NODE then
		self:_welcome_node(service, message, index);
	end

	log.info(string.format("%s %s/%s authenticated.",
			ServiceType.tostring(message.type), message.host, message.id))
end

function WorldServer:_welcome_node(node, message, index)
	-- and all nodes
	for id, other_node in pairs(self._nodes) do
		log.info(string.format("Sending address of node %s to %s/%s (%s):",
			id,
			message.host,
			message.id,
			node.endpoint.address), other_node.endpoint.address)

		node:push(NodeProtocol.node(id, other_node.endpoint.address.binary))
	end

	-- add to list of active nodes
	self._nodes[message.id] = node
end

function WorldServer:tick()
	-- accept new node connections
	for new_service in util.pop_all(self._listener) do
		log.info("New service connection: ", new_service.endpoint.address)
		table.insert(self._pending_services, new_service)
	end

	-- receive on services pending authentication
	for i, service in ipairs(self._pending_services) do
		self:_handle_service_messages(service, i)
	end

	-- remove those pending nodes that are registered
	self:_remove_authenticated_services()

	-- receive on nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end
end

-- removes processed services from the list of services pending 
-- authentication
function WorldServer:_remove_authenticated_services()
	if #self._authenticated_services then
		local length = #self._pending_services
		for _, i in ipairs(self._authenticated_services) do
			self._pending_services[i] = nil
		end

		local new_pending_services = {}
		for i=1, length do
			if self._pending_services[i] then
				new_pending_services[#new_pending_services] = self._pending_services[i]
			end
		end

		self._pending_services = new_pending_services
	end
end

return WorldServer

