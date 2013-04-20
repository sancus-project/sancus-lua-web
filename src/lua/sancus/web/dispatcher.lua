--

local utils = require"sancus.utils"
local object = require"sancus.object"
local urltemplate = require"sancus.web.urltemplate"

--
--
local function wsapi_logger(env, status, message)
	local h = env.headers
	local script_name = h["SCRIPT_NAME"]
	local path_info = h["PATH_INFO"]
	local method = h["REQUEST_METHOD"]
	local logged = false
	local prefix = "PathMapper: %s %s%s: %s"

	if script_name == "" then
		script_name = path_info
		path_info = ""
	elseif path_info ~= "" then
		path_info = " (PATH_INFO:"..path_info..")"
	end

	prefix = prefix:format(method, script_name, path_info, status)

	if message ~= nil and message ~= "" then
		for l in message:gmatch("[^\r\n]+") do
			logged = true
			utils.stderr("%s: %s\n", prefix, l)
		end
	end

	if not logged then
		utils.stderr("%s\n", prefix)
	end
end

local function wsapi_silent_logger(env, status, message)
	if status == 500 then
		return wsapi_logger(env, status, message)
	end
end

local function wsapi_traceback(env, logger, e)
	logger(env, 500, e)
	logger(env, 500, debug.traceback())
	logger(env, 500, "-- END TRACEBACK --")
	return e
end

--
--
local M = object.Class{
	compile = urltemplate.URLTemplateCompiler
}

function M:__call(wsapi_env)
	local h = self:find_handler(wsapi_env)

	if h == nil then
		self.logger(wsapi_env, 404, "Handler not found")
		return 404
	else
		local handler = function() return h(wsapi_env) end
		local traceback = function(e) return wsapi_traceback(wsapi_env, self.logger, e) end
		local success, status, headers, iter = xpcall(handler, traceback)

		if success then
			self.logger(wsapi_env, status)
			return status, headers, iter
		else
			-- already logged by traceback
			return 500
		end
	end
end

function M:find_handler(env)
	local script_name = env.headers["SCRIPT_NAME"] or ""
	local path_info = env.headers["PATH_INFO"] or ""

	for _, t in ipairs(self.patterns) do
		local regex, h, kw = unpack(t)
		local c, p = regex:match(path_info)

		if p then
			local matched_path_info = path_info:sub(1, p-1)
			local extra_path_info = path_info:sub(p)

			if #extra_path_info == 0 or
				(#extra_path_info > 0 and extra_path_info:sub(1,1) == "/") then
				-- good match

				local routing_args = env.headers["sancus.routing_args"] or {}

				-- import captures
				for k,v in pairs(c) do
					routing_args[k] = v
				end
				-- and import extra add() args
				if kw then
					for k,v in pairs(kw) do
						routing_args[k] = v
					end
				end

				env.headers["sancus.routing_args"] = routing_args
				env.headers["SCRIPT_NAME"] = script_name .. matched_path_info
				env.headers["PATH_INFO"] = extra_path_info

				return h
			end
		end
	end
end

function M:add(expr, h, kw)
	local p = assert(self.compile(expr))
	self.patterns[#self.patterns + 1] = {p, h, kw}
end

return {
	PathMapper = function (o)
		o = M(o)
		o.patterns = o.patterns or {}

		if o.logger == false then
			o.logger = wsapi_silent_logger
		elseif o.logger == true or type(o.logger) ~= "function" then
			o.logger = wsapi_logger
		end

		return o
	end
}
