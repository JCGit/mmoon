return {
	pop_all = function(queue)
		return function()
			return queue:pop()
		end
	end,
	bind = function(func, ...)
		local bound_args = {...}
		return function(...)
			return func(unpack(bound_args), ...)
		end
	end
}
