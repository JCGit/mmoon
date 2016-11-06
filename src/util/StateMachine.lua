local StateMachine = require "util.Class"(function(
		self, initial_state)
	self._state = initial_state

	
end

function StateMachine:on_enter()
	if type(self._state) == "table" then
		self._state:enter()
	end
end

function StateMachine:on_exit()
	if type(self._state) == "table" then
		self._state:exit()
	end
end

function StateMachine:update(...)
	local new_state
	if type(self._state) == "function" then
		new_state = self._state(...)
	else
		new_state = self._state:update(...)
	end

	if new_state then
		self:on_exit()
		self._state = new_state
		self:on_enter()
	end
end



