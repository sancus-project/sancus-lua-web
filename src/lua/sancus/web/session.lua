--
local utils = require"sancus.utils"
local stdout, pp = utils.stdout, utils.pprint

--
--
local function append_header(h, k, v)
	local ov = h[k]
	local t = type(ov)

	if t == 'nil' then
		h[k] = v
	elseif t == 'table' then
		ov[#ov+1] = v
	elseif t == 'string' then
		h[k] = { ov, v }
	else
		error(("invalid value %r (%s) in key %r"):format(ov, t, k))
	end
end

--
--
local function new_session()
	return {}
end

local function gen_session_id()
	return 1234
end

local function restore_session(id)
	return {}
end

local function delete_session(id)
end

local function save_session(id, t)
		local f = function() return t end
		local s = string.dump(f)
end

--
--
function SessionMiddleware(app, t)
	local count = 1
	t = t or {}
	t.session_id = t.session_id or 'session-id'

	return function(env)
		local session_id, session
		local status, headers, iter

		-- detect
		for k,v in env.HTTP_COOKIE:gmatch("([%w_-]+)=([^;]+)") do
			if k == t.session_id then
				session_id = v
				break
			end
		end

		-- load
		if session_id then
			if session_id:match("^%x+$") then
				session = restore_session(session_id)
			end
		end

		if not session then
			session_id = nil
			session = new_session()
		end

		env.session = session
		env.headers['sancus.session'] = session

		-- call
		status, headers, iter = app(env)

		-- save or delete
		if next(session) then
			if not session_id then
				session_id=gen_session_id()

				append_header(headers, 'Set-Cookie',
						string.format('%s=%x;', t.session_id, session_id))
			end
			save_session(session_id, session)
		elseif session_id then
			append_header(headers, 'Set-Cookie',
					t.session_id .. '=deleted; Expires=Thu, 01 Jan 1970 00:00:01 GMT')
			delete_session(session_id)
		end
		return status, headers, iter
	end
end

return {
	SessionMiddleware = SessionMiddleware,
}
