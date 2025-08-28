local code = ARGV[1]
local accountID = ARGV[2]
local roleID = ARGV[3]
local accountReceiveCodeList = 'AccountReciCode:' .. accountID --玩家账号已经接收的激活码列表
--local roleReceiveCodeList = 'RoleReciCode:' .. accountID --玩家账号已经接收的激活码列表
local codeConfigHMap = 'ActivationCode:' .. code --激活码配置和状态信息
local anchorInviteCodeSet = 'AnchorInviteCodeSet' --主播激活码集合，账号不可重复领取
local anchorCodeInviteAccountSet = 'AnchorCode:'..code --主播码邀请账号集合


local checkAccountHasReceiveCode = function(code)
    return redis.call('SISMEMBER',accountReceiveCodeList, code)
end
local accountReceiveCode = function(code)
    redis.call('SADD',accountReceiveCodeList, code)
end

local updateCodeCount = function(key,field,delta)
    redis.call('HINCRBY',codeConfigHMap,field, delta)
end

local addAnchorCode = function(code)
    redis.call('SADD',anchorInviteCodeSet, code)
end

local addAnchorCodeAccount = function(accountID)
    redis.call('SADD',anchorCodeInviteAccountSet, accountID)
end

local checkAccountHasAnchorCode = function(accountID)
    local result = redis.call('SINTER',anchorInviteCodeSet, accountReceiveCodeList)
    return #result > 0
end

if redis.call('EXISTS', codeConfigHMap) == 1 then
    local vec = redis.call('HMGET',codeConfigHMap,'Type','Status','TotalAmount','CurAmount')
    local size = #vec
    local Type = tonumber(vec[1])
    local Status = tonumber(vec[2])
    local TotalAmount = tonumber(vec[3])
    local CurAmount = tonumber(vec[4]) or 0
    if Status == 0 then
        return 1500
    end
    if (Type == 1)  then
        if (CurAmount >= TotalAmount) then --次数限制码
            return 1501
        end
        if checkAccountHasReceiveCode(code) == 1 then
            return 1502
        end
        updateCodeCount(codeConfigHMap,'CurAmount',1)
        accountReceiveCode(code)
        return 0
    elseif (Type == 2) then --主播码
        addAnchorCode(code)
        if checkAccountHasReceiveCode(code) == 1 then
            return 1502
        end
        if checkAccountHasAnchorCode(accountID) then
            return 1502
        end
        accountReceiveCode(code)
        addAnchorCodeAccount(accountID)
        return 0
    end
    return 1500
else
	-- 激活码不存在
	return 1500
end

