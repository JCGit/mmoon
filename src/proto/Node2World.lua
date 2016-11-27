local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {
	-- connect to node
	node = Message(0x2002, "id:uint16", "address:uint32"),

	register_proxy = Message(0x3001, "address:uint32")
}

