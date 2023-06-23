
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

stream_mt.__index = {

    cdr = function (S) return S.tail () end,
    totable = function (S) 

        local tbl = {}

        while not isempty (S) do

            table.insert (tbl, S.head)
            S = S:cdr ()

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
    map = function (S, f)

        return cons (f (S.head), function () return S:cdr ():map (f) end)
    
    end,
    zip = function (S, R, f)

        return cons (f (S.head, R.head), function () return S:cdr ():zip (R:cdr (), f) end)
    
    end

}


local function constant (v)

    local vs
    vs = cons (v, function () return vs end)
    return vs

end

local function from (v, by)

    return cons (v, function () return from (v + by, by) end)

end


local ones = constant (1)

local fibs
fibs = cons (0, function () return cons (1, function () return fibs:zip (fibs:cdr (), function (a, b) return a + b end)   end) end)

print (ones.head)
print (ones:cdr ().head)

local tbl = ones:take (10):totable ()

op.print_table (tbl)

local S = from (4, -1):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

print (S.head)
print (S:cdr ().head)
print (S:cdr ():cdr ().head)
print (S:cdr ():cdr ():cdr ().head)

op.print_table (S:totable ())

op.print_table (fibs:take(30):totable ())