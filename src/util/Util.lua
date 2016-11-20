local util = {}

function util.pop_all(queue)
	return function()
		return queue:pop()
	end
end

function util.bind(func, ...)
	local bound_args = {...}
	return function(...)
		return func(unpack(bound_args), ...)
	end
end

function util.switch(a, b)
	return b, a
end

function util.range(i, j)
	return function()
		if i > j then
			return nil
		end
		local val = i
		i = i + 1
		return val
	end
end

function util.many(n, f, ...)
	local results = {}
	for i=1,n do
		table.insert(results, f(...))
	end
	return unpack(results)
end

function util.map(xs, f, ...)
	local results = {}
	for k, x in pairs(xs) do
		results[k] = f(x, ...)
	end
	return results
end

function util.each(xs, f, ...)
	for k, x in pairs(xs) do
		f(x, ...)
	end
	return xs
end

function util.copy(x)
	if type(x) ~= "table" then
		return x
	end

	local c = {}
	for k, y in pairs(x) do
		c[k] = util.copy(y)
	end

	return c
end

function util.findfirst(xs, x)
	for i,y in ipairs(xs) do
		if x == y then return i end
	end
	return -1
end

function util.shallow_copy(x)
	local c = {}
	for k, y in pairs(x) do
		c[k] = y
	end
	return c
end


function util.filter(xs, f)
	if type(f) ~= "function" then
		local val = f
		f = function(x)
			return x == val
		end
	end
	
	local results = {}
	for i, x in ipairs(xs) do
		if not f(x) then
			table.insert(results, x)
		end
	end
	return results
end

function util.filter_map(xs, f)
	if type(f) ~= "function" then
		local val = f
		f = function(x)
			return x == val
		end
	end
	
	local results = {}
	for k, x in pairs(xs) do
		if not f(x) then
			results[k] = x
		end
	end
	return results
end

function util.zip_with(f, xs, ys)
	local results = {}
	for i, x in ipairs(xs) do
		table.insert(results, f(x, ys[i]) or util.Empty)
	end
	return results
end

function util.and_(xs)
	for _, x in ipairs(xs) do
		if not x then return false end
	end
	return true
end

function util.all(xs, f, ...)
	return util.and_(util.map(xs, f, ...))
end

function util.first(x, _)
	return x
end

function util.second(_, x)
	return x
end

function util.concat(t1, t2)
	for i, x in ipairs(t2) do
		table.insert(t1, x)
	end
	return t1
end

-- Returns an array of array t divided into groups of n
function util.groups(t, n)
	local r = {}
	for o = 1,#t,n do
		table.insert(r, {})
		for i = o, o+n-1 do
			table.insert(r[#r], t[i])
		end
	end
	return r
end

function util.replicate(x, n)
	local xs = {}
	for i=1,n do
		table.insert(xs, x)
	end
	return xs
end

function util.hexdump(data, chunk)
	chunk = chunk or 12
	local octets = util.groups({data:byte(1, data:len())}, chunk)
	for i, group in ipairs(octets) do
		log.info(("%04x: %s"):format((i-1) * chunk,
			table.concat(util.map(group, util.bind(string.format, "%02x")),
				" ")))
	end
end

function util.keys(xs)
	local keys = {}
	for key, _ in pairs(xs) do
		table.insert(keys, key)
	end
	return keys
end

return util

