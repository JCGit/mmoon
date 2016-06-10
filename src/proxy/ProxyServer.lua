local LoopbackConnection = require "network.LoopbackConnection"
local Protocol = require "network.Protocol"
local Message = require "network.Message"

local protocol = Protocol.new({
	authenticate = Message(0x1001, "key:string", "time:uint32"),
	say          = Message(0x1002, "name:string", "message:string")
})

local conn = LoopbackConnection.new(protocol)

conn:push(protocol.authenticate("abc123", 12345678))

local op, msg = conn:pop()
if op then
	print("{")
	for field, value in pairs(msg) do
		print(string.format("  %s: %s", field, value))
	end
	print("}")
end

