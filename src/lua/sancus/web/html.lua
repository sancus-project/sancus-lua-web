-- This file is part of sancus-lua-template
-- <https://github.com/sancus-project/sancus-lua-template>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local utils = require"sancus.utils"
local html = require"sancus.text.html"
local Class = require"sancus.object.Class"

local type, tostring = type, tostring
local error = utils.error

local _M = { _NAME = ... }
setfenv(1, _M)

html_encoded_string = html.encode_string
encode = html.encode

-- HTML friendly string
--
Raw = Class{
	init = function(cls, s)
		-- flatten
		local t = type(s)
		if t == "table" then
			if #s == 1 then
				s = s[1]
				t = type(s)
			else
				if #s == 0 then
					s = ""
				else
					s = tconcat(s, "")
				end
				t = "string"
			end
		end
		if s == nil then
			s = ""
		elseif t == "number" or t == "boolean" then
			s = tostring(s)
		elseif t ~= "string" then
			error("html.Raw:%s: Invalid data type", 1, t)
		end

		return { s }
	end,
	html_encoded = function(self)
		return self[1] or ""
	end,
	__tostring = function(self)
		return self:html_encoded()
	end,
}

return _M
