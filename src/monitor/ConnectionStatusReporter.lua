local class = require "util.Class"

local socket = require "socket"
local json = require "cjson"

local ConnectionStatusReporter = class(function(self, host, port)
	self._socket = socket.tcp()

	-- connect and init connection
	self._socket:connect(host, port)
	self._socket:send(string.pack("<!1I2", 206))
end)

function ConnectionStatusReporter:_send(json_object)
	local buffer = json.encode(json_object)
	self._socket:send(string.pack("<!1I4", #buffer))
	self._socket:send(buffer)
end

return ConnectionStatusReporter

