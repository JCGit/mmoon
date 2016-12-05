local util = require "util.Util"
local log = require "log.Logger"
local class = require "util.Class"
local ServerProtocol = require "proto.Server"
local ServerType = require "proto.ServerType"
local IPv4Address = require "network.IPv4Address"
local MessageHandler = require "network.MessageHandler"

local Server = class(function(self, server_type, listener, config)
	self._server_type = server_type
	self._config = config
	self._listener = listener

	self._pending_servers = {}
	self._authenticated_servers = {}

	self._handle_server_messages = MessageHandler()

	self._handle_server_messages[ServerProtocol.authenticate] =
		self._on_authenticate
end)

function Server:connect(address)
end

function Server:_on_authenticate(server, message, index)
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
		return true
	end

	server:push(ServerProtocol.welcome(
			0,
			tostring(self._listener.endpoint.address),
			self._server_type
		))

	if self.on_established then
		self.on_established(message.type, server, message)
	end

	log.info(string.format("%s %s/%s authenticated.",
			ServerType.tostring(message.type), message.host, message.id))

	return true
end

function Server:tick()
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

end

-- removes processed servers from the list of servers pending 
-- authentication
function Server:_remove_authenticated_servers()
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


return Server


