-- 查询排行榜脚本

-- 排行榜类型
local type = tonumber(ARGV[1])
-- uuid
local uuid = ARGV[2]


-- 获取有序集合中所有分数
local function get_all_scores(key)
    local unique_scores = {}

    -- 获取有序集合中所有成员和分数
    local all_scores = redis.call('ZREVRANGEBYSCORE', key, '+inf', '-inf', 'WITHSCORES')

    -- 遍历所有成员和分数
    for i=1,#all_scores,2 do
        local score = all_scores[i+1]
        -- 如果当前分数不等于上一个分数，则将其加入到 unique_scores 中
        if unique_scores[#unique_scores] ~= score then
            table.insert(unique_scores, score)
        end
    end

    return unique_scores
end

local function get_rank(key, uuid)
    local score = redis.call("ZSCORE", key, uuid)

    local all_scores = get_all_scores(key)
    for i = 1, #all_scores, 1 do
        if(all_scores[i] == score) then
            return i
        end
    end

    return 0
end

local ranking_type = {
    [0] = "Level",
    [1] = "Consume",
    [2] = "Kill",
    [3] = "Hunt"
}
local key = "LeaderBoard:Ranking:".. ranking_type[type]

return get_rank(key, uuid)
