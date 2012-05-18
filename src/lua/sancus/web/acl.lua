-- Copyright (C) 2012 Alejandro Mery <amery@geeks.cl>
--
-- this file is part of sancus-lua-web

local Class = assert(require"sancus.object").Class

local C = Class()

function C:user_authenticated(env)
	return env.session.user ~= nil
end

function C:user_groups(env)
	local user = env.session.user
	local g
	if user then
		g = user.groups
	end
	return g or {}
end

local function is_one_of(t, r)
	for _, x in ipairs(t) do
		for _, y in ipairs(r) do
			if x == y then
				return true
			end
		end
	end
end

function C:__call(h, x)
	local f
	if x == nil then
		-- any authenticated user counts
		f = function() return true end
	elseif type(x) == 'function' then
		f = x
	else
		if type(x) ~= 'table' then
			x = { x }
		end
		f = function(env)
			return is_one_of(x, self:user_groups(env))
		end
	end

	return function(env)
		if not self:user_authenticated(env) then
			return 401
		elseif f(env) then
			return h(env)
		else
			return 403
		end
	end
end
return {
	ACL = C,
}
