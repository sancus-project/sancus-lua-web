-- This file is part of sancus-lua-template
-- <https://github.com/sancus-project/sancus-lua-template>
--
-- Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
--

local type, tostring, pairs, ipairs = type, tostring, pairs, ipairs
local tconcat = table.concat

local _M = { _NAME = ... }
setfenv(1, _M)

local function quote(s)
	-- TODO: replace with lpeg
	return s:gsub("\\","\\\\"):gsub("\"", '\\"'):gsub("\n", "\\n"):gsub("\t","\\t")
end

function json_encode(v)
	local t = type(v)
	local s
	if t == "nil" then
		s = "null"
	elseif t == "boolean" or t == "number" then
		s = tostring(v)
	elseif t == "string" then
		s = json_encode_string(v)
	elseif #v > 0 then
		s = json_encode_array(v)
	else
		s = json_encode_object(v)
		-- prefer empty arrays instead of empty objects
		if s == "{}" then
			s = "[]"
		end
	end
	return s
end

function json_encode_string(v)
	return "\"" .. quote(v) .. "\""
end

function json_encode_array(o)
	local t = {}
	for _, v in ipairs(o) do
		t[#t+1] = json_encode(v)
	end

	if #t > 0 then
		return "[" .. tconcat(t, ", ") .. "]"
	else
		return "[]"
	end
end

function json_encode_object(o)
	local t = {}
	local fmt = "%s: %s"

	for k, v in pairs(o) do
		k = json_encode_string(k)
		v = json_encode(v)
		t[#t+1] = fmt:format(k, v)
	end
	if #t > 0 then
		return "{" .. tconcat(t, ", ") .. "}"
	else
		return "{}"
	end
end

return _M
