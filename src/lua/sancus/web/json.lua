-- This file is part of sancus-lua-template
-- <https://github.com/sancus-project/sancus-lua-template>
--
-- Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
--

local type, tostring, pairs, ipairs = type, tostring, pairs, ipairs
local select = select
local setmetatable, getmetatable = setmetatable, getmetatable
local tconcat = table.concat

local _M = { _NAME = ... }
setfenv(1, _M)

-- String
--
local function quote(s)
	-- TODO: replace with lpeg
	return s:gsub("\\","\\\\"):gsub("\"", '\\"'):gsub("\n", "\\n"):gsub("\t","\\t")
end

local function json_encode_string(v)
	return "\"" .. quote(v) .. "\""
end

-- Array
--
local function json_encode_array(o)
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

local json_array_mt = {
	__tostring = function(self)
		return json_encode_array(self)
	end,
}

function Array(...)
	local l = select('#', ...)
	local o

	if l == 0 then
		o = {}
	elseif l > 1 then
		o = { ... }
	else
		o = select(1, ...)
		if type(o) ~= 'table' then
			o = { o }
		end
	end
	setmetatable(o, json_array_mt)
	return o
end

-- Object
--
local function json_encode_object(o)
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

local json_object_mt = {
	__tostring = function(self)
		return json_encode_object(self)
	end,
}

function Object(...)
	local l = select('#', ...)
	local o

	if l == 0 then
		o = {}
	elseif l > 1 then
		o = { ... }
	else
		o = select(1, ...)
		if type(o) ~= 'table' then
			o = { o }
		end
	end
	setmetatable(o, json_object_mt)
	return o
end

-- Null
--
local json_null_mt = {
	__tostring = function(self)
		return "null"
	end,
	__call = function(self)
		return self
	end,
}
Null = {}
setmetatable(Null, json_null_mt)

-- Generic Encoder
--
function json_encode(v)
	local t = type(v)
	local s
	if t == "nil" then
		s = "null"
	elseif t == "boolean" or t == "number" then
		s = tostring(v)
	elseif t == "string" then
		s = json_encode_string(v)
	else
		local mt = getmetatable(v)
		if mt ~= nil and mt.__tostring ~= nil then
			s = tostring(v)
		elseif #v > 0 then
			s = json_encode_array(v)
		else
			s = json_encode_object(v)
			-- prefer empty arrays instead of empty objects
			if s == "{}" then
				s = "[]"
			end
		end
	end
	return s
end

return _M