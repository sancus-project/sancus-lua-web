-- This file is part of sancus-lua-template
-- <https://github.com/sancus-project/sancus-lua-template>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local type, tostring, ipairs = type, tostring, ipairs
local getmetatable = getmetatable
local tconcat = table.concat

local _M = { _NAME = ... }
setfenv(1, _M)

function html_encoded_string(v)
	-- TODO: Implement ;-)
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
			s = tostring(v)
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
