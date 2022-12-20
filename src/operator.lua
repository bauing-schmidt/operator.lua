
local op = {}

function op.identity(...) return ... end
function op.eternity(...) return op.eternity(...) end	-- via tail-recursion.
function op.noop(...) end
function op.forever(f, ...) while true do f(...) end end
function op.precv (f, g) return function (s, ...) if s then return f(...) else return g(...) end end end
function op.add(a, b) return a + b end
function op.eq(a, b) return a == b end
function op.lt(a, b) return a < b end
function op.le(a, b) return a <= b end
function op.increment(a) return op.add(a, 1) end
function op.apply (f, ...) return f(...) end
function op.o (funcs) return function (...) return table.foldr (funcs, op.apply, ...) end end

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

function table.foldr (tbl, f, ...)
	local init = table.pack (...)
	for i = #tbl, 1, -1 do init = table.pack(f(tbl[i], table.unpack (init))) end
	return table.unpack(init)
end

function table.map (tbl, f)
	mapped = {}
	for k, v in pairs(tbl) do mapped[k] = f(v) end
	return mapped
end

function math.random_uniform(a, b)
	a = a or 0
	b = b or 1
	return a + (b - a) * math.random()
end

function math.random_bernoulli (p)

	if math.random() < p then return 1 else return 0 end
end

function math.random_bernoulli_boolean (p)

	return math.random_bernoulli(p) == 1
end

function math.random_binomial (n, p)

	local s, B = 0, math.random_bernoulli
	for i = 1, n do s = s + B (p) end
	return s
end

function math.random_geometric (p)
	
	local w, B = -1, math.random_bernoulli_boolean
	repeat w = w + 1 until B (p)
	return w
end

--[[
	def triangular(self, low=0.0, high=1.0, mode=None):
        """Triangular distribution.

        Continuous distribution bounded by given lower and upper limits,
        and having a given mode value in-between.

        http://en.wikipedia.org/wiki/Triangular_distribution

        """
        u = self.random()
        try:
            c = 0.5 if mode is None else (mode - low) / (high - low)
        except ZeroDivisionError:
            return low
        if u > c:
            u = 1.0 - u
            c = 1.0 - c
            low, high = high, low
        return low + (high - low) * _sqrt(u * c)

]]

function math.random_triangular (low, high, mode)
	local u, c = math.random(), 0.5

	if mode then c = (mode - low) / (high - low) end

	if c == math.huge then return low end

	if u > c then
		u = 1.0 - u
		c = 1.0 - c
		low, high = high, low
	end

	return low + (high - low) * math.sqrt(u * c)
end

--[[

    def normalvariate(self, mu, sigma):
        """Normal distribution.

        mu is the mean, and sigma is the standard deviation.

        """
        # Uses Kinderman and Monahan method. Reference: Kinderman,
        # A.J. and Monahan, J.F., "Computer generation of random
        # variables using the ratio of uniform deviates", ACM Trans
        # Math Software, 3, (1977), pp257-260.

        random = self.random
        while True:
            u1 = random()
            u2 = 1.0 - random()
            z = NV_MAGICCONST * (u1 - 0.5) / u2
            zz = z * z / 4.0
            if zz <= -_log(u2):
                break
        return mu + z * sigma
]]

local NV_MAGICCONST = 4 * math.exp(-0.5) / math.sqrt(2.0)
local LOG4 = math.log(4.0)
local SG_MAGICCONST = 1.0 + math.log(4.5)
local BPF = 53        		-- Number of bits in a float
local RECIP_BPF = 2 ^ (-BPF)

function math.random_normal (mu, sigma)

	local random, log, z = math.random, math.log, nil

    while true do
		local u1 = random()
		local u2 = 1.0 - random()
		z = NV_MAGICCONST * (u1 - 0.5) / u2
		local zz = z * z / 4.0
		if zz <= -log(u2) then break end
	end

	return mu + z * sigma

end

--[[
	def lognormvariate(self, mu, sigma):
        """Log normal distribution.

        If you take the natural logarithm of this distribution, you'll get a
        normal distribution with mean mu and standard deviation sigma.
        mu can have any value, and sigma must be greater than zero.

        """
        return _exp(self.normalvariate(mu, sigma))
]]
function math.random_lognormal(mu, sigma)

	assert (sigma > 0)

	return math.exp (math.normal (mu, sigma))
end

--[[
	def expovariate(self, lambd):
        """Exponential distribution.

        lambd is 1.0 divided by the desired mean.  It should be
        nonzero.  (The parameter would be called "lambda", but that is
        a reserved word in Python.)  Returned values range from 0 to
        positive infinity if lambd is positive, and from negative
        infinity to 0 if lambd is negative.

        """
        # lambd: rate lambd = 1/mean
        # ('lambda' is a Python reserved word)

        # we use 1-random() instead of random() to preclude the
        # possibility of taking the log of zero.
        return -_log(1.0 - self.random()) / lambd
]]
function math.random_exponential (lambd, mean)
	
	if mean then 
		-- in this case, `lambd` is the mean, so go transform it to an actual ratio.
		lambd = 1 / lambd 
	end

	return -math.log(1.0 - math.random()) / lambd
end

return op
