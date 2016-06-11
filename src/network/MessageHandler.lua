local util = require "util.Util"

return function(protocol)
	local handler = {}

	setmetatable(handler, {
		__call = function(_, self, conn)
			assert(conn)
			for opcode, message in util.pop_all(conn) do
				if rawget(handler, opcode) then
					handler[opcode](self, conn, message)
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

