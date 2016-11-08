local util = require "util.Util"

return function()
	local handler = {}

	setmetatable(handler, {
		__call = function(_, self, conn, id)
			assert(conn)
			for opcode, message in util.pop_all(conn) do
				if rawget(handler, opcode) then
					-- TODO: document
					-- if a truthy value is returned, stop handling any more
					-- messages for this connection (so that we can switch
					-- handlers -- and thus protocols -- as response to
					-- a message)
					if handler[opcode](self, conn, message, id) then
						return
					end
				end
			end
		end,
		__newindex = function(_, message, func)
			assert(message)
			assert(func)
			rawset(handler, message.opcode, func)
		end
	})

	return handler
end

