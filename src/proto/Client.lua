local Protocol, Message =
	require "network.Protocol", require "network.Message"

return Protocol.new {
	-- CLIENT TO SERVER
	authenticate = Message(0x1001,
		"key:string" -- from login server
	),
	join_world = Message(0x1002),
	
	-- chat
	send_chat_message = Message(0x1501,
		"text:string"
	),


	-- SERVER TO CLIENT
	welcome = Message(0x8002),
	joined_world = Message(0x8003,
		"id:string"
	),
	chat_message = Message(0x8501,
		"text:string"
	),

	-- events
	spawn_entity = Message(0x8101,
		"id:string",
		"color:string",
		"node:string",
		"x:int32",
		"y:int32"
	)
}

