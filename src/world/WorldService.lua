local util = require "util.Util"
local log = require "log.Logger"
local MessageHandler = require "network.MessageHandler"
local NodeProtocol = require "proto.Node2World"
local ServerProtocol = require "proto.Server"
local ServerType = require "proto.ServerType"
local Console = require "world.Console"
local IPv4Address = require "network.IPv4Address"

local WorldService = require"util.Class"(function(self, listener, config)
	self._listener = listener
	self._config = config

	log.notice(string.format("Starting world server on %s.",
		listener.endpoint.address))

	-- servers
	self._proxies = {}
	self._nodes = {}

	self._pending_servers = {}
	self._authenticated_servers = {} -- TODO: rename

	-- message handlers
	self._handle_server_messages, self._handle_node_messages =
		MessageHandler(),
		MessageHandler()

	self._handle_server_messages[ServerProtocol.authenticate] =
		self._on_authenticate

	self._handle_node_messages[NodeProtocol.register_proxy] =
		self._on_register_proxy

	-- admin command line (port 4444)
	self._console = Console.new(
		{ world = self })
end)

function WorldService:_on_authenticate(server, message, index)
	-- mark from deletion from pending nodes no matter what happens
	table.insert(self._authenticated_servers, index)

	-- once a node has been registered, check if its key is valid and
	-- then send a welcome message to it 
	if message.key ~= self._config.security.key then
		log.warn(
			string.format(
				"Service %s:%s/%s failed authentication with key: %s",
				ServerType.tostring(message.type),
				message.host,
				message.id,
				message.key))
		server:close()
		return
	end

	server:push(ServerProtocol.welcome(
			0,
			tostring(self._listener.endpoint.address),
			ServerType.WORLD
		))

	if message.type == ServerType.NODE then
		self:_welcome_node(server, message, index);
	end

	log.info(string.format("%s %s/%s authenticated.",
			ServerType.tostring(message.type), message.host, message.id))
end

function WorldService:_on_register_proxy(c, msg)
	table.insert(self._proxies, IPv4Address.new(msg.address))
	log.info(string.format("Proxy registered: %s",
		IPv4Address.new(msg.address)))
end

function WorldService:_welcome_node(node, message, index)
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

function WorldService:tick()
	-- accept new node connections
	for new_server in util.pop_all(self._listener) do
		log.info("New server connection: ", new_server.endpoint.address)
		table.insert(self._pending_servers, new_server)
	end

	-- receive on servers pending authentication
	for i, server in ipairs(self._pending_servers) do
		self:_handle_server_messages(server, i)
	end

	-- remove those pending nodes that are registered
	self:_remove_authenticated_servers()

	-- receive on nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end

	-- admin command line
	self._console:update()
end

-- removes processed servers from the list of servers pending 
-- authentication
function WorldService:_remove_authenticated_servers()
	if #self._authenticated_servers then
		local length = #self._pending_servers
		for _, i in ipairs(self._authenticated_servers) do
			self._pending_servers[i] = nil
		end

		local new_pending_servers = {}
		for i=1, length do
			if self._pending_servers[i] then
				new_pending_servers[#new_pending_servers] =
					self._pending_servers[i]
			end
		end

		self._pending_servers = new_pending_servers
	end
end

return WorldService

