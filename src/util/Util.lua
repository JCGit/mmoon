return {
	pop_all = function(queue)
		return function()
			return queue:pop()
		end
	end
}
