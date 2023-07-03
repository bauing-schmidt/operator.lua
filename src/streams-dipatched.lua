
local op = require 'operator'

local stream_mt = {}
local stream_cons_mt = {}

local empty_stream = {}

setmetatable (empty_stream, {

    __index = {


        totable = function (S, tbl) return tbl end,
        zip_cons = function (S, tail, head, f) return S end,

    }

})


local function isempty (S) return S == empty_stream end

--[[
    data Stream a = Nil | Cons a (Stream a) | Susp (() -> Stream a)

]]


local function susp (t)

    local S = { promise = op.memoize (t) }
    setmetatable (S, stream_mt)

    return S
end

local function cons (h, t)

    local S = { head = h, tail = t }
    setmetatable (S, stream_cons_mt)

    return S
end

stream_cons_mt.__index = {

    totable = function (S, tbl) 
        table.insert (tbl, S.head)
        return S.tail:totable (tbl)
    end,
    take = function (S, n)
        if n == 0 then return empty_stream else return cons (S.head, S.tail:take (n - 1)) end
    end,
    map = function (S, f) return cons (f (S.head), S.tail:map (f)) end,
    zip = function (S, R, f) return R:zip_cons (S.tail, S.head, f) end,
    zip_cons = function (S, tail, head, f) return cons (f (head, S.head), tail:zip (S.tail, f)) end,
    at = function (S, i)
        if i > 0 then return S.tail:at (i - 1) elseif i == 1 then return S.head else error 'negative index' end
    end,
    filter = function (S, p)
        
        local r, R = S.head, susp (function () return S.tail:filter (p) end)
        if p (r) then return cons (r, R) else return R end
    end
}



stream_mt.__call = function (S) return S.promise () end

stream_mt.__index = {

    totable = function (S, tbl) return S ():totable (tbl) end,
    take = function (S, n) if n == 0 then return empty_stream else return S ():take (n) end end,
    map = function (S, f) return S ():map (f) end,
    zip = function (S, R, f) return S ():zip (R, f) end,
    zip_cons = function (S, tail, head, f) local R = S (); return R:zip_cons (tail, head, f) end,
    at = function (S, i) return S ():at (i) end,
    filter = function (S, p) return S ():filter (p) end,
}

local function iterate (f, v)
    return cons (v, susp (function () return iterate (f, f (v)) end))
end

local function constant (v)

    local vs
    vs = cons (v, susp (function () return vs end))
    return vs

end

local function from (v, by) return cons (v, susp (function () return from (v + by, by) end)) end

local ones = constant (1)


-- print (ones.head)
-- print (ones.tail ().head)

local tbl = ones:take (10):totable {}

op.print_table (tbl)


local nats = iterate (function (v) return v + 1 end, 0)
op.print_table (nats:take(30):totable {})


local S = from (4, -1):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

-- print (S.head)
-- print (S.tail ().head)
-- print (S.tail ().tail ().head)
-- print (S.tail ().tail ().tail ().head)
-- print (S:at (4))

op.print_table (S:totable {})


local fibs
fibs = cons (0, cons (1, susp (function () return fibs:zip (fibs.tail, function (a, b) return a + b end) end)))

local tbl = fibs:take (10):totable {}

op.print_table (tbl)

op.print_table (fibs:take(30):totable {})

print (fibs:at (30))


local function P (S)

   
    local p, R = S ()
    
    local function isntmultiple (n) return n % p > 0 end

    return cons (function () return p, P (R:filter (isntmultiple)) end)
end

local primes = P (from (2, 1))

op.print_table (primes:take(500):totable {})
