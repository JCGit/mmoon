local log = require "log.Logger"
local LocalListener = require "network.LocalListener"
local LocalEndpoint = require "network.LocalEndpoint"
local WorldServer = require "world.WorldServer"
local Node = require "node.Node"
local Proxy = require "proxy.Proxy"

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

local ProxyServer = {
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
local nodes = {}
local proxies = {}

for i=1,2 do
	table.insert(nodes, Node.new(i, "november", LocalListener.new(), NodeConfig))
end

for i=1,2 do
	table.insert(proxies, Proxy.new(1, LocalListener.new(), ProxyConfig))
end

log.info("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
xpcall(function()
	while true do
		world:tick()

		for i, node in ipairs(nodes) do
			node:tick()
		end

		for i, proxy in ipairs(nodes) do
			proxy:tick()
		end
	end
end, function(err)
	log.err(err)
	log.err(debug.traceback())
end)

log.info("Shutting down.")

