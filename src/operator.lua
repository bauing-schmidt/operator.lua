
local op = {}

function op.identity(...)
	return ...	-- returns whatever I consume
end

function op.eternity(...)
	return op.eternity(...)	-- infinite recursion
end

function op.noop()
	-- simply do nothing
end

function op.forever(f, ...)
	while true do f(...) end
end

function op.recv (...) 
	return op.frecv(op.identity, op.noop, ...)
end

function op.frecv (f, g, s, ...)
	if not g then g = function () end end
	if s then return f(...) else return g(...) end
end

function op.add(a, b)
	return a + b
end

function op.eq(a, b)
	return a == b
end

function op.lt(a, b)
	return a < b
end

function op.le(a, b)
	return a <= b
end

function op.increment(a)
	return op.add(a, 1)
end

--------------------------------------------------------------------------------

function coroutine.const(f)

	local function C (...)
		operator.forever(coroutine.yield, f(...))
	end

	return coroutine.create(C)
end

function coroutine.mappend(...)

end

function coroutine.take (co, n)

	n = n or math.huge

	local function T ()
		local i, continue = 1, true
		while continue and i <= n do
			operator.frecv(coroutine.yield,
						   function () continue = false end,	-- simulate a break
						   coroutine.resume(co))
			i = i + 1
		end
	end

	return coroutine.create(T)
end

function coroutine.each(co, f)

	local continue = true
	local function stop () continue = false end

	while continue do
		operator.frecv(f, stop,	coroutine.resume(co))
	end

end

function coroutine.foldr (co, f, init)

	local function F (each)
		local folded = coroutine.foldr(co, f, init)
		return f(each, folded)
	end

	return operator.frecv(F, init, coroutine.resume(co))
end

function coroutine.iter (co)
	return function () return operator.recv(coroutine.resume(co)) end
end

function coroutine.nats(s)
	return coroutine.create(function ()
		local each = s or 0 -- initial value
		operator.forever(
			function ()
				coroutine.yield(each)
				each = each + 1
			end)
	end)
end

function coroutine.map(f)
	return function (co)
		return coroutine.create(
			function ()
				while true do
					local s, v = coroutine.resume(co)
					if s then coroutine.yield(f(v)) else break end
				end
			end)
	end
end

function coroutine.zip(co, another_co)
	return coroutine.create(
		function ()
			while true do
				local s, v = coroutine.resume(co)
				local r, w = coroutine.resume(another_co)
				if s and r then coroutine.yield(v, w) else break end
			end
		end)
end

function table.contains(tbl, elt)
	return tbl[elt] ~= nil
end

function table.foldr (tbl, f, init)
	for i = #tbl, 1, -1 do
		init = f(tbl[i], init)
	end
	return init
end

function table.map (tbl, f)
	mapped = {}
	for k, v in pairs(tbl) do mapped[k] = f(v) end
	return mapped
end

return op
