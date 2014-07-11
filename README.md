ns-redis
========

A layer over redis-async to allow easy use of namespace prefixes on redis keys

Example Use
-------

```lua
local async = require 'async'
local r = require 'ns-redis'

r({host = "localhost", port = 6379}, function(allocator) 
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
```

Output:

```
{
  1 : "1 2 3 4 5 6"
  2 : "6 5 4 3 2 1"
  3 : "23456"
}
{
  1 : "NAMESPACE1:testkey1"
  2 : "NAMESPACE1:testkey2"
  3 : "testarg1"
  4 : "testarg2"
}
```

from the redis client:
```
redis 127.0.0.1:6379> get NAMESPACE1:test
"1 2 3 4 5 6"
redis 127.0.0.1:6379> get NAMESPACE1:test2
"6 5 4 3 2 1"
redis 127.0.0.1:6379> get NAMESPACE1:test3
"23456"

redis 127.0.0.1:6379> get test
(nil)
redis 127.0.0.1:6379> get test2
(nil)
redis 127.0.0.1:6379> get test23
(nil)
```

License
-------

MIT License


