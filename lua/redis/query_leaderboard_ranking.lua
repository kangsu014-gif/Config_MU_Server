-- 查询排行榜脚本

-- 排行榜类型
local type = tonumber(ARGV[1])
-- 最小排名
local min_rank = tonumber(ARGV[2])
-- 最大排名
local max_rank = tonumber(ARGV[3])
-- 最大的数据条数 -1:不限制
local max_data_num = tonumber(ARGV[4])
-- 分数是否重复 0:不重复 1:重复
local repeat_score = tonumber(ARGV[5])

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

-- 获取指定排名范围内的分数
local function get_top_scores(key, min_rank, max_rank)
    local all_scores = get_all_scores(key)
    local top_scores = {}

    if(min_rank > max_rank or min_rank < 1 ) then
        return top_scores
    end

    for i=min_rank, max_rank, 1 do
        if i <= #all_scores then
            table.insert(top_scores, all_scores[i])
        end
    end
    return top_scores

end

-- 获取指定排名范围内的排名
local function get_rankings(key, min_rank, max_rank)
    local top_scores = get_top_scores(key, min_rank, max_rank)
    local ranking  = {}
    local rank = min_rank
    for i=1,#top_scores, 1 do
        local scores_str = tostring(top_scores[i])
        local member = redis.call('ZRANGEBYSCORE', key, scores_str, scores_str, 'WITHSCORES')
        if(member and #member > 0) then
            for j=1,#member,2 do
                if(member[j] and member[j+1]) then
                    table.insert(ranking, {member[j], member[j+1], rank})
                end
            end
            rank = rank + 1
        end
    end
    return ranking
end


local function get_ranking_info_repeat_score(key, min_rank, max_rank, max_data_num)
    local ranking = get_rankings(key, min_rank, max_rank)
    -- return ranking
    local result = {}
    for i = 1, #ranking, 1 do
        local uuid = ranking[i][1]
        local amount = ranking[i][2]
        local rank = ranking[i][3]

        local player_key = "LeaderBoard:PlayerInfo:" .. uuid
        -- 查询玩家相关信息
        local info = redis.call("HMGET", player_key, "name", "profession")

        if(info[1] and info[2]) then
            table.insert(result, uuid)
            table.insert(result, info[1])
            table.insert(result, info[2])
            table.insert(result, tostring(amount))
            table.insert(result, tostring(rank))
        end
        if(#result >= max_data_num * 5 and max_data_num > 0) then
            break
        end
    end

    return result
end

local function get_ranking_info_not_repeat_score(key, min_rank, max_rank, max_rank_num)
    -- 查询排行榜
    local ranking = redis.call("ZREVRANGE", key, tostring(min_rank-1), tostring(max_rank-1), "WITHSCORES")

    local result = {}
    local rank = min_rank
    for i = 1, #ranking, 2 do
        local uuid = ranking[i]
        local amount = ranking[i+1]

        local player_key = "LeaderBoard:PlayerInfo:" .. uuid
        -- 查询玩家相关信息
        local info = redis.call("HMGET", player_key, "name", "profession")

        if(info[1] and info[2]) then
            table.insert(result, uuid)
            table.insert(result, info[1])
            table.insert(result, info[2])
            table.insert(result, tostring(amount))
            table.insert(result, tostring(rank))
            rank = rank + 1
        end
        if(#result >= max_rank_num * 5 and max_rank_num > 0) then
            break
        end
    end

    return result
end



local ranking_type = {
    [0] = "Level",
    [1] = "Consume",
    [2] = "Kill",
    [3] = "Hunt"
}
local key = "LeaderBoard:Ranking:".. ranking_type[type]

if(repeat_score == 0) then
    return get_ranking_info_not_repeat_score(key, min_rank, max_rank, max_data_num)
else
    return get_ranking_info_repeat_score(key, min_rank, max_rank, max_data_num)
end
