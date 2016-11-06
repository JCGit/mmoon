local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {

	--= Node -> World =--
	register = Message(0x1001, "id:uint8", "host:string", "key:string"),

	--= World -> Node =--
	welcome = Message(0x2001),

	-- connect to node
	node = Message(0x2002, "id:uint16", "address:uint32"),
	-- connect to proxy
	proxy = Message(0x2003, "address:uint32")

}

