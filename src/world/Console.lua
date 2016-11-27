local socket = require "socket"
local util = require "util.Util"
local IPv4Address = require "network.IPv4Address"

local Console = require "util.Class"(function(self, env)
	self._env = env

	self._env.list = function(list)
		for i, item in ipairs(list) do
			env.print("*", tostring(item))
		end
	end

	self._listener = socket.tcp()
	self._listener:setoption("reuseaddr", true)
	self._listener:bind("127.0.0.1", 4444)
	self._listener:listen(5)
	self._listener:settimeout(0)

	self._clients = {}
end)

function Console:update()
	local socket, err = self._listener:accept()
	if socket then
		socket:settimeout(0)
		self:_welcome(socket)
		self:_prompt(socket)
		table.insert(self._clients, { socket = socket, buffer = "" })
	elseif err ~= "timeout" then
		error(err)
	end


	table.insert(self._clients, client)

	for i, client in ipairs(self._clients) do
		local line, err
		line, err, client.buffer =
			client.socket:receive("*l", client.buffer)

		if line then
			self:_command(client, line)
		elseif err == "closed" then
			client.closed = true
		elseif err ~="timeout" then
			error(err)
		end
	end

	self._clients = util.filter(self._clients, function(client)
		return client.closed
	end)
end

function Console:_command(client, command)
	if command:sub(1,1) == "=" then
		command = string.format("return (%s)", command:sub(2))
	end

	self._env.print = function (...) client.socket:send(table.concat({...}, " ") .. "\n") end

	local f, err = load(command, "command", "t", self._env)
	if not f then
		client.socket:send("error: "..err.."\n")
	else
		local success, result = pcall(f, client.socket)
		if success then
			if result then
				client.socket:send(tostring(result))
				client.socket:send("\n")
			end
		else
			client.socket:send("error: "..result.."\n")
		end
	end

	self:_prompt(client.socket)
end

function Console:_prompt(socket)
	socket:send("> ")
end

function Console:_welcome(socket)
	socket:send("\x1B[37m")
	socket:send("Welcome to the mmoon admin Lua interpreter console.\n")
	socket:send("\x1B[0m")
end

return Console

