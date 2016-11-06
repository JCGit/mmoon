local log = require "log.Logger"
local LocalListener = require "network.LocalListener"
local LocalEndpoint = require "network.LocalEndpoint"
local WorldServer = require "world.WorldServer"
local Node = require "node.Node"

log.info("Starting full server stack...")

-- Network endpoints/listeners
local world_listener = LocalListener.new()
local world_endpoint = world_listener.endpoint
local node1Listener = LocalListener.new()
local node2Listener = LocalListener.new()

-- Config
local NodeConfig = {
	world = {
		address = world_endpoint.address
	},
	security = {
		key = "1234567890"
	}
}

local WorldConfig = {
	security = {
		key = "1234567890"
	}
}

-- Servers & nodes
local world = WorldServer.new(world_listener, WorldConfig)
local nodes = {
	Node.new(1, "november", node1Listener, NodeConfig),
	Node.new(2, "november", node2Listener, NodeConfig)
}

log.info("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
xpcall(function()
	while true do
		world:tick()

		for i, node in ipairs(nodes) do
			node:tick()
		end
	end
end, function(err)
	log.err(err)
	log.err(debug.traceback())
end)

log.info("Shutting down.")

