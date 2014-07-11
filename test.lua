local async = require 'async'
local r = require 'ns-redis'

local verify = function(res, expectedres)
   local t1 = type(res)
   local t2 = type(expectedres)

   if t1 == "table" and t2 == "table" then
      for i=1,#res do
         if tostring(res[i]) ~= tostring(expectedres[i]) then
            print("FAILED TEST", res[i], expectedres[i])
         end
      end
   elseif tostring(res) ~= tostring(expectedres) then
      print("FAILED TEST", res, expectedres)
   end
   print("SUCCESS", res, expectedres)
end

r({host = "localhost", port = 6379}, function(allocator) 
   print("READY")
   local ns_1 = allocator("NAMESPACE1")
   local ns_2 = allocator("OTHERNAMESPACE")

   ns_1.mset("test", "1 2 3 4 5 6", "test2", "6 5 4 3 2 1", "test3", 23456)
   ns_2.mset("test", "Some Text")

   ns_1.mget("test", "test2", "test3", function(res) 
      verify(res, {"1 2 3 4 5 6", "6 5 4 3 2 1", 23456}) 
   end)

   ns_2.get("test", function(res) verify(res, "Some Text") end)

   -- test numkeys style
   ns_1.eval([[
   local a = KEYS[1]
   local b = KEYS[2]
   local c = ARGV[1]
   local d = ARGV[2]

   return {a, b, c, d}
   ]], 2, "testkey1", "testkey2", "testarg1","testarg2", function(res)
      verify(res, {"NAMESPACE1:testkey1" , "NAMESPACE1:testkey2", "testarg1", "testarg2"})
   end)

end)

async.go()
