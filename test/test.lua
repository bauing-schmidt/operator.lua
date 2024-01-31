
local op = require "operator"
local unittest = require "unittest"

local tests = {}

function tests:etest_callcc ()

    -- Usage
    local co = coroutine.create(function()
        local _, val = callcc(function(cc)
            for i=1,5 do
                cc(i)
            end
        end)
        print(val)
    end)
    
    while coroutine.status(co) ~= 'dead' do
        coroutine.resume(co)
    end

end

function tests:test_callcc_nohop ()
   
    local called, expected = false, 1

    local C = op.callcc (function (hop) return expected end)
    
    unittest.assert.equals 'No return values expected' 'world' (C (function (v)
        called = true
        unittest.assert.equals 'Should no hop' (expected) (v)
        return 'world'
    end))

    unittest.assert.istrue 'Continuation called' (called)

end

function tests:test_callcc_hop ()

    local called = false
    local C = op.callcc (function (hop) return 1 + hop ('hello', 'world'), 0 end)

    unittest.assert.equals 'Return value expected' 'another' (C (function (h, w)
        called = true
        unittest.assert.equals 'Should hop' ('hello', 'world') (h, w)
        return 'another'
    end))    
    unittest.assert.istrue 'Continuation called' (called)

end

print (unittest.api.suite(tests))
