
local op = require 'operator'

local stream_mt = {}

local empty_stream = {}

local function isempty (S) return S == empty_stream end

local function cons (h, t)

    if t ~= empty_stream then t = op.memoize (t) end

    local S = { head = h, tail = t }
    setmetatable (S, stream_mt)

    return S
end

stream_mt.__add = function (S, R) return cons (S.head, function () return R + S:tail () end) end

stream_mt.__index = {

    totable = function (S) 

        local tbl = {}

        while not isempty (S) do

            table.insert (tbl, S.head)
            S = S:tail ()

        end

        return tbl
    end,
    take = function (S, n)

        if n == 0 then 
            return empty_stream 
        else 
            return cons (S.head, 
                         function () 
                            local m = n - 1
                            if m == 0 then return empty_stream 
                            else return S.tail ():take (m) end
                         end) 
        end
    end,
    map = function (S, f) return cons (f (S.head), function () return S:tail ():map (f) end) end,
    zip = function (S, R, f) return cons (f (S.head, R.head), function () return S:tail ():zip (R:tail (), f) end) end,
    at = function (S, i)

        while i > 1 do 
            S = S:tail ()
            i = i - 1
        end

        return S.head
    end,

}

local function iterate (f, v)
    return cons (v, function () return iterate (f, f (v)) end)
end

local function constant (v)

    local vs
    vs = cons (v, function () return vs end)
    return vs

end

local function from (v, by) return cons (v, function () return from (v + by, by) end) end

local ones = constant (1)

local fibs
fibs = cons (0, function () return cons (1, function () return fibs:zip (fibs:tail (), function (a, b) return a + b end) end) end)

print (ones.head)
print (ones:tail ().head)

local tbl = ones:take (10):totable ()

op.print_table (tbl)

local S = from (4, -1):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

print (S.head)
print (S:tail ().head)
print (S:tail ():tail ().head)
print (S:tail ():tail ():tail ().head)
print (S:at (4))

op.print_table (S:totable ())

op.print_table (fibs:take(30):totable ())

print (fibs:at (30))

local nats = iterate (function (v) return v + 1 end, 0)
op.print_table (nats:take(30):totable ())
