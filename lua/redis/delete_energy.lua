-- 删除玩家的抽奖能量
-- 获取 game.entity:record_key 集合中的所有成员
local keysToDelete = redis.call('SMEMBERS', 'game.entity:record_key')

-- 遍历集合中的每个键并设置过期时间
for i, key in ipairs(keysToDelete) do
    -- 设置过期时间, 7天后过期
    redis.call("EXPIRE", key, 7*24*60*6)
end

-- 删除完成后, 设置 game.entity:record_key 集合的过期时间
redis.call("EXPIRE", 'game.entity:record_key', 7*24*60*6)
