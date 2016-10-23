local class = require "util.Class"

local socket = require "socket"
local json = require "cjson"

local JOT_SIGNATURE = 206

local ConnectionStatusReporter = class(function(self, host, port)
	self._socket = socket.tcp()

	-- connect and init connection
	self._socket:connect(host, port)
end)

function ConnectionStatusReporter:_send(json_object)
	local buffer = json.encode(json_object)
	-- 206 is the json-over-tcp protocol signature
	self._socket:send(string.pack("<!1I2I4", JOT_SIGNATURE, #buffer))
	self._socket:send(buffer)
end

function ConnectionStatusReporter:identify(identifier)
	self:_send { identify = identifier }
end

function ConnectionStatusReporter:shutdown(identifier)
	self:_send { shutdown = "" }
end

return ConnectionStatusReporter

