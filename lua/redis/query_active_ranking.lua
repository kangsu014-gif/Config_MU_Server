-- 查询活动排行榜脚本

-- 活动id
local active_id = ARGV[1]
-- 排行榜类型
local type = tonumber(ARGV[2])
-- 最小排名
local min_rank = ARGV[3]
-- 最大排名
local max_rank = ARGV[4]

local amount_field = ""
local ranking_type = ""

if(type == 1)
then
    amount_field = "recharge_amount"
    ranking_type = "Recharge"
elseif(type == 2)
then
    amount_field = "spending_amount"
    ranking_type = "Spending"
elseif(type == 3)
then    
    amount_field = "charm_amount"
    ranking_type = "Charisma"
end

local ranking_key = "ActiveEvents:ID" .. active_id .. ":Ranking:" .. ranking_type
-- 查询排行榜
local ranking = redis.call("ZREVRANGE", ranking_key, min_rank, max_rank)

local result = {}
local rank = tonumber(min_rank) + 1
for i = 1, #ranking, 1 do
    local account_id = ranking[i]

    local player_key = "ActiveEvents:ID" .. active_id .. ":PlayerInfo:" .. account_id
    -- 查询玩家相关信息
    local info = redis.call("HMGET", player_key, amount_field, "uuid", "name", "level", "profession")

    if(#info == 5)
    then
        table.insert(result, account_id)
        table.insert(result, info[1])
        table.insert(result, info[2])
        table.insert(result, info[3])
        table.insert(result, info[4])
        table.insert(result, info[5])
        table.insert(result, tostring(rank))
        
        rank = rank + 1
    end 
end

return result