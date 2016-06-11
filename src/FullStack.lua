local LocalListener = require "network.LocalListener"
local GridServer = require "grid.GridServer"

print("Starting full server stack...")

local grid = GridServer.new(LocalListener.new())

print("Initialized.")

-- Protected call to catch ctrl-c and perform graceful shutdown
pcall(function()
	while true do
		grid:tick()
	end
end)

print("Shutting down.")

