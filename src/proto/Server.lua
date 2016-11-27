local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {
	authenticate = Message(0x1001,
		"id:uint8",
		"host:string", -- TODO(deox): not sure about this one
		"type:uint8",
		"key:string"),
	welcome = Message(0x1002,
		"id:uint8",
		"host:string",
		"type:uint8")
}

