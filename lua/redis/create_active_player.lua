-- 创建活动的玩家信息
-- 如果玩家的信息存在, 则返回0, 否则创建, 并设置过期时间, 返回1
local key = KEYS[1]
local exists = redis.call("EXISTS", key)

if exists == 1 then
    return 0
else
    redis.call("HMSET", key,
        "uuid", 0,
        "name", 0,
        "level", 0,
        "profession", 0,
        "recharge_amount", 0,
        "spending_amount", 0,
        "charm_amount", 0,
        "recharge_rebate_receive_id", 0,
        "cumulative_recharge_receive_id", 0,
        "cumulative_spending_receive_id", 0,
        "charm_receive_id", 0,
        "is_up_ranking_recharge", 1,
        "is_up_ranking_spending", 1,
        "is_up_ranking_charm", 1
    )
    -- 设置过期时间, 30天后过期
    redis.call("EXPIRE", key, 30*24*60*60)
    return 1
end
