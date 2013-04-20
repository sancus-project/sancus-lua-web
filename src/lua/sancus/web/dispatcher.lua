--

local object = require"sancus.object"
local urltemplate = require"sancus.web.urltemplate"

local M = object.Class{
	compile = urltemplate.URLTemplateCompiler
}

function M:__call(wsapi_env)
	local h = self:find_handler(wsapi_env)

	if h then
		return h(wsapi_env)
	else
		return 404
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
		return o
	end
}
