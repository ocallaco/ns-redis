local async = require 'async'
local r = require 'ns-redis'

r({domain = {host = "localhost", port = 6379}}, function(allocator) 
   local ns_1 = allocator("NAMESPACE1")

   ns_1.mset("test", "1 2 3 4 5 6", "test2", "6 5 4 3 2 1", "test3", 23456)
   
   ns_1.mget("test", "test2", "test3", function(res) print(res) end)

   ns_1.eval([[
   local a = KEYS[1]
   local b = KEYS[2]
   local c = ARGV[1]
   local d = ARGV[2]

   return {a, b, c, d}
   ]], 2, "testkey1", "testkey2", "testarg1","testarg2", function(res)
      print(res)
   end)
end)

async.go()
