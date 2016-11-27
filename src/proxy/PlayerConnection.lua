local class = require "util.Class"
local Protocol = require "proto.Client"
local MessageHandler = require "network.MessageHandler"
local log = require "log.Logger"

local State = {}

function State.HANDSHAKE(connection)
	local handler = MessageHandler()

	handler[Protocol.authenticate] = function(_, c, msg, set_state)
		if msg.key == "xyz123" then
			return set_state(State.LOBBY)
		else
			c:close()
		end
	end

	return handler
end
function State.LOBBY(connection)
	connection:push(Protocol.welcome())

	local handler = MessageHandler()

	handler[Protocol.join_world] = function(_, c, msg, set_state)
		return set_state(State.GAME)
	end

	return handler
end
function State.GAME(connection)
	connection:push(Protocol.joined_world("some_id"))

	local handler = MessageHandler()

	handler[Protocol.send_chat_message] = function(_, c, msg)
		log.info("chat message: ", msg.text)
	end

	return handler
end


local PlayerConnection = class (function(self, connection)
	self._connection = connection

	self._state = State.HANDSHAKE(self)
end)

function PlayerConnection:push(message)
	self._connection:push(message)
end

function PlayerConnection:close()
	self._connection:close()
end

function PlayerConnection:tick()
	local new_state = nil

	self:_state(self._connection, function(state)
		new_state = state(self)
		return true
	end)

	if new_state then
		self._state = new_state
	end
end


return PlayerConnection

