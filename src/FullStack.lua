local log = require "log.Logger"
local LocalListener = require "network.LocalListener"
local LocalEndpoint = require "network.LocalEndpoint"
local WorldService = require "world.WorldService"
local Node = require "node.Node"
local SimulationNode = require "node.SimulationNode"
local ProxyNode = require "proxy.ProxyNode"
local TestClient = require "client.TestClient"

log.info("Starting full server stack...")

-- Network endpoints/listeners
local world_listener = LocalListener.new()
local world_endpoint = world_listener.endpoint

-- Config
local NodeConfig = {
	world = {
		address = world_endpoint.address
	},
	security = {
		key = "1234567890"
	}
}

local ProxyConfig = {
}

local WorldConfig = {
	security = {
		key = "1234567890"
	}
}

-- Servers & nodes
local world = WorldService.new(world_listener, WorldConfig)
local nodes = {}
--local proxies = {}

for i=1,2 do
	table.insert(nodes, Node.new(
		i,
		"november",
		LocalListener.new(),
		NodeConfig,
		SimulationNode
		))
end

local proxy_listener = LocalListener.new()
local proxy_endpoint = proxy_listener.endpoint

table.insert(nodes, Node.new(
	3,
	"november",
	LocalListener.new(),
	NodeConfig,
	ProxyNode,
	ProxyConfig,
	proxy_listener))

--[[for i=1,2 do
	table.insert(nodes, Node.new(
		i+2,
		"november",
		LocalListener.new(),
		NodeConfig,
		ProxyNode,
		ProxyConfig,
		LocalListener.new()
		))
end]]

local test_client = TestClient.new(proxy_endpoint)

log.info("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
local exit_code = 0
xpcall(function()
	while true do
		world:tick()

		for i, node in ipairs(nodes) do
			node:tick()
		end

		test_client:tick()
	end
end, function(err)
	log.err(err)
	log.err(debug.traceback())
	exit_code = 1
end)

log.info("Shutting down.")
os.exit(exit_code)

