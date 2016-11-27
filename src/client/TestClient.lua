local util = require "util.Util"
local log = require "log.Logger"
local Protocol = require "proto.Client"
local MessageHandler = require "network.MessageHandler"

local TestClient = require "util.Class"(function(
		self, proxy_endpoint)

	self._connection = proxy_endpoint:connect(Protocol)
	self._connection:send(Protocol.authenticate("xyz123"))

	self._message_handler = MessageHandler()

	self._message_handler[Protocol.welcome] = self._on_welcome
	self._message_handler[Protocol.joined_world] = self._on_joined_world
	self._message_handler[Protocol.spawn_entity] = self._on_spawn_entity
end

function TestClient:on_welcome

function TestClient:update()
end

