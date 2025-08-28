-- 创建排行榜的玩家信息
-- 如果玩家的信息存在, 则返回0, 否则创建, 并设置过期时间, 返回1
local uuid = ARGV[1]
local name = ARGV[2]
local profession = ARGV[3]

local key = "LeaderBoard:PlayerInfo:".. uuid
local exists = redis.call("EXISTS", key)

if exists == 1 then
    return 0
else
    redis.call("HMSET", key,
        "name", name,
        "profession", profession
    )
    return 1
end