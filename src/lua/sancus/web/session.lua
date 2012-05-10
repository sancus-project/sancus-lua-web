--
local lfs = assert(require"lfs")
local utils = require"sancus.utils"
local stderr, pformat = utils.stderr, utils.pformat

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

local function gen_session_id(dir)
	while true do
		local lock = lfs.lock_dir(dir)
		if not lock then
			stderr("session: failed to lock %s\n", dir)
		else
			local id = string.format("%x", math.random(2147483647)) -- MAX_INT32
			local fn = string.format("%s/%s", dir, id)
			local st = lfs.attributes(fn)
			if not st then
				local f = assert(io.open(fn, "w+"))
				f:close()
				lock:free()
				return id
			end
			lock:free()
		end
	end
end

local function restore_session(dir, id)
	local fn = dir .. '/' .. id
	local f, err  = io.open(fn)
	local s
	if f then
		s, err = f:read("*a")
		f:close()
		if s then
			return loadstring(s)()
		end
	end
	stderr("session: %s\n", err)
end

local function delete_session(dir, id)
	os.remove(dir .. '/' .. id)
end

local function save_session(dir, id, t)
	local fn = dir .. '/' .. id
	local f = assert(io.open(fn, "w+"))
	f:write("return " .. pformat(t))
	f:close()
end

--
--
function SessionMiddleware(app, t)
	local count = 1
	t = t or {}
	t.session_dir = t.session_dir or "sessions"
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
				session = restore_session(t.session_dir, session_id)
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
				session_id=gen_session_id(t.session_dir)

				append_header(headers, 'Set-Cookie',
						string.format('%s=%s;', t.session_id, session_id))
			end
			save_session(t.session_dir, session_id, session)
		elseif session_id then
			append_header(headers, 'Set-Cookie',
					t.session_id .. '=deleted; Expires=Thu, 01 Jan 1970 00:00:01 GMT')
			delete_session(t.session_dir, session_id)
		end
		return status, headers, iter
	end
end

return {
	SessionMiddleware = SessionMiddleware,
}
