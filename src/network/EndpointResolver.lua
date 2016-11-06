local VirtualAddress = require "network.VirtualAddress"
local IPv4Address = require "network.IPv4Address"
local LocalEndpoint = require "network.LocalEndpoint"

local EndpointResolver = {}

function EndpointResolver.resolve(address)
	if type(address) == "string" then
		address = IPv4Address.from_string(address) --parse_string(address)
	end
	if type(address) == "table" then
		address = address.binary
	end

	local local_listener = VirtualAddress.resolve(address)
	if local_listener then
		return LocalEndpoint.new(local_listener)
	end

	error("not implemented")
	return nil
end

return EndpointResolver

