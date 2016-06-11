local log = require "log.Logger"
local LocalListener = require "network.LocalListener"
local GridServer = require "grid.GridServer"

log.info("Starting full server stack...")

local grid = GridServer.new(LocalListener.new())

log.info("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
pcall(function()
	while true do
		grid:tick()
	end
end)

log.info("Shutting down.")

