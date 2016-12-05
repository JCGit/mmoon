local util = require "util.Util"
local log = require "log.Logger"
local Server = require "server.Server"
local MessageHandler = require "network.MessageHandler"
local NodeProtocol = require "proto.Node2World"
local ServerType = require "proto.ServerType"
local Console = require "world.Console"
local IPv4Address = require "network.IPv4Address"

local WorldService = require"util.Class"(function(self, listener, config)
	self._config = config

	log.notice(string.format("Starting world server on %s.",
		listener.endpoint.address))

	self._server = Server.new(ServerType.WORLD, listener, config)
	self._server.on_established = util.bind(self._on_server_established, self)

	-- servers
	self._nodes = {}
	self._proxies = {}

	-- message handlers
	self._handle_node_messages = MessageHandler()
	self._handle_node_messages[NodeProtocol.register_proxy] =
		self._on_register_proxy

	-- admin command line (port 4444)
	self._console = Console.new(
		{ world = self })
end)

function WorldService:_on_server_established(server_type, server, message)
	if server_type == ServerType.NODE then
		self:_welcome_node(server, message)
	end
end

function WorldService:_on_register_proxy(c, msg)
	table.insert(self._proxies, IPv4Address.new(msg.address))
	log.success(string.format("Proxy registered: %s",
		IPv4Address.new(msg.address)))
end

function WorldService:_welcome_node(node, message)
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
	self._server:tick()

	-- receive on nodes
	for id, node in pairs(self._nodes) do
		self:_handle_node_messages(node, id)
	end

	-- admin command line
	self._console:update()
end

return WorldService

