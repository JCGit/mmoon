local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {

	authenticate = Message(0x1001, "id:uint8", "host:string", "key:string"),
	welcome = Message(0x1002),

}

