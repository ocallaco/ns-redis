local redis = require 'redis-async'

-- table is COMMAND = {first key index, last key index} -- 0 in first key index means no keys in command.  
-- 0 in second index all args from start index on are keys
-- negative value means reverse index from end (ie -1 means second to last entries)
-- if #,"numkeys", it means the (#)th arg is the number of keys is passed as an argument (EVAL etc)
-- if #,"alt", it means keys are the inputs, alternating from the starting point (#)
local all_commands = {
APPEND = {1,1},
AUTH = {0,0},
BGREWRITEAOF = {0,0},
BGSAVE = {0,0},
BITCOUNT = {1,1},
BITOP = {2,0},
BITPOS = {1,1},
BLPOP = {1,-1},
BRPOP = {1,-1},
BRPOPLPUSH = {1,2},
CLIENT = {0,0},
CONFIG = {0,0},
DBSIZE = {0,0},
DEBUG = {2,2},
DECR = {1,1},
DECRBY = {1,1},
DEL = {1,0},
DISCARD = {0,0},
DUMP = {1,1},
ECHO = {0,0},
EVAL = {2,"numkeys"},
EVALSHA = {2,"numkeys"},
EXEC = {0,0},
EXISTS = {1,1},
EXPIRE = {1,1},
EXPIREAT = {1,1},
FLUSHALL = {0,0},
FLUSHDB = {0,0},
GET = {1,1},
GETBIT = {1,1},
GETRANGE = {1,1},
GETSET = {1,1},
HDEL = {1,1},
HEXISTS = {1,1},
HGET = {1,1},
HGETALL = {1,1},
HINCRBY = {1,1},
HINCRBYFLOAT = {1,1},
HKEYS = {1,1},
HLEN = {1,1},
HMGET = {1,1},
HMSET = {1,1},
HSET = {1,1},
HSETNX = {1,1},
HVALS = {1,1},
INCR = {1,1},
INCRBY = {1,1},
INCRBYFLOAT = {1,1},
INFO = {0,0},
KEYS = {1,1},
LASTSAVE = {0,0},
LINDEX = {1,1},
LINSERT = {1,1},
LLEN = {1,1},
LPOP = {1,1},
LPUSH = {1,1},
LPUSHX = {1,1},
LRANGE = {1,1},
LREM = {1,1},
LSET = {1,1},
LTRIM = {1,1},
MGET = {1,0},
MONITOR = {0,0},
MOVE = {3,3},
MSET = {1,"alt"},
MSETNX = {1,"alt"},
MULTI = {0,0},
OBJECT = {0,0}, -- object takes a full command with it, could nest
PERSIST = {1,1},
PEXPIRE = {1,1},
PEXPIREAT = {1,1},
PFADD = {1,1},
PFCOUNT = {1,0},
PFMERGE = {1,0},
PING = {0,0},
PSETEX = {1,1},
PSUBSCRIBE = {0,0},
PUBSUB = {0,0}, -- object takes a full command with it, could nest
PTTL = {1,1},
PUBLISH = {1,1},
PUNSUBSCRIBE = {0,0},
QUIT = {0,0},
RANDOMKEY = {0,0},
RENAME = {1,2},
RENAMENX = {1,2},
RESTORE = {1,1},
ROLE = {0,0},
RPOP = {1,1},
RPOPLPUSH = {1,2},
RPUSH = {1,1},
RPUSHX = {1,1},
SADD = {1,1},
SAVE = {0,0},
SCARD = {1,1},
SCRIPT = {0,0},
SDIFF = {1,0},
SDIFFSTORE = {1,0},
SELECT = {0,0},
SET = {1,1},
SETBIT = {1,1},
SETEX = {1,1},
SETNX = {1,1},
SETRANGE = {1,1},
SHUTDOWN = {0,0},
SINTER = {1,0},
SINTERSTORE = {2,0},
SISMEMBER = {1,1},
SLAVEOF = {0,0},
SLOWLOG = {0,0},
SMEMBERS = {1,1},
SMOVE = {1,2},
SORT = {1,1},
SPOP = {1,1},
SRANDMEMBER = {1,1},
SREM = {1,1},
STRLEN = {1,1},
SUBSCRIBE = {1,0},
SUNION = {1,0},
SUNIONSTORE = {1,0},
SYNC = {0,0},
TIME = {0,0},
TTL = {1,1},
TYPE = {1,1},
UNSUBSCRIBE = {1,0},
UNWATCH = {0,0},
WATCH = {1,0},
ZADD = {1,1},
ZCARD = {1,1},
ZCOUNT = {1,1},
ZINCRBY = {1,1},
ZINTERSCORE = {2,"numkeys"},
ZLEXCOUNT = {1,1},
ZRANGE = {1,1},
ZRANGEBYLEX = {1,1},
ZRANGEBYSCORE = {1,1},
ZRANK = {1,1},
ZREM = {1,1},
ZREMRANGEBYLEX = {1,1},
ZREMRANGEBYRANK = {1,1},
ZREMRANGEBYSCORE = {1,1},
ZREVRANGE = {1,1},
ZREVRANGEBYSCORE = {1,1},
ZREVRANK = {1,1},
ZSCORE = {1,1},
ZUNIONSTORE = {1,1},

SCAN = {0,0},
SSCAN = {1,1},
HSCAN = {1,1},
ZSCAN = {1,1},

}

local namespace_clients = {}

local function get_modified_func(com, v, namespace, client)

   local redis_func = client[com] or function() error("Function", com, "not defined in your version of redis-async") end
   local com_func

   
   if v[1] == 0 then
      com_func = redis_func
   elseif v[2] == "numkeys" then
      com_func = function(...) 
         local args = {...}
         local numkeys = args[2]

         if numkeys > 0 then
            for i=3,(2+numkeys) do
               if type(args[i]) == 'string' then
                  args[i] = namespace .. ":" .. args[i]
               else
                  error("Invalid arg -- redis key expected:", args[i])
               end
            end
         end

         redis_func(unpack(args))
      end
   elseif v[2] == "alt" then
      com_func = function(...) 
         local args = {...}
         local numkeys = args[2]

         for i=v[1],#args,2 do
            if type(args[i]) == 'string' then
               args[i] = namespace .. ":" .. args[i]
            else
               -- could be a callback
               if i == #args and type(args[i]) == 'function' then 
                  break 
               end
               error("Invalid arg -- redis key expected:", args[i])
            end
         end

         redis_func(unpack(args))
      end
   else
      local st = v[1]
      local en = v[2]

      com_func = function(...)
         local args = {...}

         if en == 0 then 
            en = #args 
         end

         for i =st,en,1 do
            if type(args[i]) == 'string' then
               args[i] = namespace .. ":" .. args[i]
            else
               -- could be a callback
               if i == #args and type(args[i]) == 'function' then 
                  break 
               end
               error("Invalid arg -- redis key expected:", args[i])
            end
         end

         redis_func(unpack(args))
      end
   end

   return com_func
end

return function(options, callback)
   if options.domain then
      local domain = options.domain 

      redis.connect(domain, function(client)
         callback(function(namespace)

            local meta = {}

            function meta:__index(key)
               local com = key:upper()

               local v = all_commands[com]

               if v then 
                  return get_modified_func(key, v, namespace, client)
               else
                  return client[key]
               end
            end

            local namespaced_client = {}
            setmetatable(namespaced_client, meta) 

            return namespaced_client
         end)
      end)
   elseif options.client then
      local client = options.client
      callback(function(namespace)

         local meta = {}

         function meta:__index(key)
            local com = key:upper()

            local v = all_commands[com]

            if v then 
               return get_modified_func(key, v, namespace, client)
            else
               return client[key]
            end
         end

         local namespaced_client = {}
         setmetatable(namespaced_client, meta) 

         return namespaced_client
      end)
   else
      error("options require client or domain")
   end
end

