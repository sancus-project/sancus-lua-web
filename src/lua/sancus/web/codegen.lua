--

local CodeGen = require"CodeGen"
local lfs = require "lfs"

local sformat, fopen = string.format, io.open
local assert, pairs = assert, pairs

function loaddir_raw(dir, prefix, out)
	prefix = prefix or ""
	out = out or {}

	for fn in lfs.dir(dir) do
		if not fn:match("^[.]") then
			local ffn = sformat("%s/%s", dir, fn)
			if lfs.attributes(ffn, "mode") == "directory" then
				loaddir_raw(ffn, sformat("%s%s_", prefix, fn), out)
			else
				local bn = fn:match("^(.*)[.]([^.]+)$") or fn
				local f = assert(fopen(ffn, "r"))

				out[prefix..bn] = f:read("*all") --trim(f:read("*all"))
				f:close()
			end
		end
	end

	return out
end

function loaddir(dir, prefix, out)
	return CodeGen(loaddir_raw(dir, prefix or '', out or {}))
end

function renderer(env, default_headers)
	return function (res, template, data)
		data = data or {}

		for k,v in pairs(default_headers) do
			if not res.headers[k] then
				res.headers[k] = v
			end
		end

		res.app_iter = function()
			local s = CodeGen(data, env)(template)
			if #s > 0 then
				coroutine.yield(s)
			else
				error(sformat("failed to render %s", template))
			end
		end
	end
end

return {
	loaddir = loaddir,
	renderer = renderer,
}
