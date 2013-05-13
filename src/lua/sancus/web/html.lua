-- This file is part of sancus-lua-template
-- <https://github.com/sancus-project/sancus-lua-template>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local utils = require"sancus.utils"
local lpeg = require"lpeg"

local type, tostring, ipairs = type, tostring, ipairs
local getmetatable = getmetatable
local tconcat = table.concat

local _M = { _NAME = ... }
setfenv(1, _M)

-- html escape strings
--
local html_escape

do
	local escaped = {
		["&"] = "&amp;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		['"'] = "&quot;",
		["'"] = "&#39;",
	}
	local risky = lpeg.S"&<>'\""
	local safe = lpeg.P(1) - risky

	safe = lpeg.C(safe^1)
	risky = lpeg.C(risky)/escaped

	html_escape = lpeg.Ct((safe + risky)^0) * -1
end

function html_encoded_string(v)
	local t

	if not v then
		v = ""
	elseif v~= "" then
		t = html_escape:match(v)
		if not t or #t == 0 then
			utils.stderr_prefixed_lines("html_encoded_string",
				utils.pformat(t, v))
			v = ""
		elseif #t == 1 then
			v = t[1]
		else
			v = tconcat(t, "")
		end
	end

	return v
end

-- Generic Encoder
--
function encode(v)
	local t = type(v)
	local s

	if t == "nil" then
		s = ""
	elseif t == "boolean" or t == "number" then
		s = tostring(v)
	elseif t == "string" then
		s = html_encoded_string(v)
	elseif v.html_encoded then
		s = v:html_encoded()
	else
		local mt = getmetatable(v)
		if mt and mt.__tostring then
			s = encode(tostring(v))
		elseif #v > 0 then
			local t = {}
			for i,sv in ipairs(v) do
				t[i] = encode(sv)
			end
			s = tconcat(t, "")
		else
			s = ""
		end
	end
	return s
end

return _M
