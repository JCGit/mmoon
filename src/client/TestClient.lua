local util = require "util.Util"
local log = require "log.Logger"
local Protocol = require "proto.ClientProtocol"

local TestClient = require "util.Class"(function(
		self, proxy_endpoint)

	self._connection = proxy_endpoint:connect(Protocol)

end
