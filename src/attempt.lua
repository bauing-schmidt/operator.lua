
local op = require 'operator'

local stream_mt = {}
local stream_cons_mt = {}

local empty_stream = {}

setmetatable (empty_stream, {

    __index = {
        totable = function (S, tbl) return tbl end,
    }

})

local function isempty (S) return S == empty_stream end

--[[

    data Stream a = Nil | Cons () -> (a, Stream a)

]]


local function cons (t)

    local S = { promise = op.memoize (t) }
    setmetatable (S, stream_mt)

    return S
end

stream_mt.__call = function (S) return S.promise (S) end

stream_mt.__index = {

    totable = function (S, tbl)

        local v, R = S ()
        table.insert (tbl, v)
        return R:totable (tbl)
    end,
    take = function (S, n)

        if n == 0 then 
            return empty_stream 
        else 
            return cons (function () 
                            local v, R = S ()
                            return v, R:take (n - 1)
                         end) 
        end
    end,
    map = function (S, f) return cons (function () local v, R = S (); return f (v), R:map (f) end) end,
    zip = function (S, R, f) return cons (function () local s, SS = S (); local r, RR = R (); return f(s, r), SS:zip (RR, f) end) end,
    at = function (S, i)

        local s, R = nil, S
        while i > 0 do 
            s, R = R ()
            i = i - 1
        end

        return s
    end,
    filter = function (S, p)
        -- filter :: Stream a -> (a -> boolean) -> Stream a
        local r, R = S()
        if p (r) then return cons (function () return r, R:filter (p) end)
        else return R:filter (p) end

        
    end
}

local function iterate (f, v)
    return cons (function () return v, iterate (f, f (v)) end)
end

local function constant (v)

    local vs
    vs = cons (function () return v, vs end)
    return vs

end

local function from (v, by) return cons (function () return v, from (v + by, by) end) end

local C = os.clock ()

local ones = constant (1)

local fibs
fibs = cons (function () return 0, cons (function () local zero, F = fibs (); return zero + 1, fibs:zip (F, function (a, b) return a + b end) end) end)

-- print (ones.head)
-- print (ones.tail ().head)

local tbl = ones:take (10):totable {}

op.print_table (tbl)

local tbl = fibs:take (10):totable {}

op.print_table (tbl)

local S = from (4, -1):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

-- print (S.head)
-- print (S.tail ().head)
-- print (S.tail ().tail ().head)
-- print (S.tail ().tail ().tail ().head)
print (S:at (4))

op.print_table (S:totable {})

op.print_table (fibs:take(30):totable {})

print (fibs:at (30))

local nats = iterate (function (v) return v + 1 end, 0)
op.print_table (nats:take(30):totable {})


local function P (S)

   
    local p, R = S ()
    
    local function isntmultiple (n) return n % p > 0 end

    return cons (function () return p, P (R:filter (isntmultiple)) end)
end

local primes = P (from (2, 1))

op.print_table (primes:take(500):totable {})

print ('seconds: ', os.clock () - C)