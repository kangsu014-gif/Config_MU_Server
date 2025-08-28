-- 1 账号id 实体uuid 服务器id 服务器名字
if redis.call('hsetnx',KEYS[1],'entity_uuid',ARGV[1]) == 1 then
	redis.call('expire',KEYS[1],120)
	redis.call('hmset',KEYS[1],'server_id',ARGV[2],'server_name',ARGV[3])
	-- 可以登录
	return {KEYS[1],1}
else
	redis.call('expire',KEYS[1],120)
	-- 账户已登录
	return {KEYS[1],0}
end