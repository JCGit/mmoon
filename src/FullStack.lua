local log = require "log.Logger"
local LocalListener = require "network.LocalListener"
local LocalEndpoint = require "network.LocalEndpoint"
local GridServer = require "grid.GridServer"
local Node = require "node.Node"

log.info("Starting full server stack...")

local grid_listener = LocalListener.new()
local grid_endpoint = LocalEndpoint.new(grid_listener)
local grid = GridServer.new(grid_listener)

local node1Listener = LocalListener.new()
local node2Listener = LocalListener.new()

local nodes = {
	Node.new(1, "november", node1Listener, grid_endpoint),
	Node.new(2, "november", node2Listener, grid_endpoint)
}

log.info("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
xpcall(function()
	while true do
		grid:tick()

		for i, node in ipairs(nodes) do
			node:tick()
		end
	end
end, function(err)
	log.err(err)
	log.err(debug.traceback())
end)

log.info("Shutting down.")

