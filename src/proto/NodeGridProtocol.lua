local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {
	register = Message(0x1001, "id:uint8", "host:string"),
	welcome = Message(0x2001)
}

