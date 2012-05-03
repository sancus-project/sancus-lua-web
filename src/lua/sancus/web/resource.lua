--

local Class = assert(require"sancus.object").Class
local request = assert(require"wsapi.request")

local C = Class{
	_methods = {'GET', 'HEAD', 'POST', 'PUT', 'DELETE'}
}

function C:find_supported_methods(d)
	local l = {}
	if #d > 0 then
		for _, k in ipairs(d) do
			if type(self[k]) == 'function' then
				l[k] = k
			end
		end
	else
		for l, v in pairs(d) do
			if type(self[v]) == 'function' then
				l[k] = v
			end
		end
	end
	if l['GET'] and not l['HEAD'] then
		l['HEAD'] = l['GET']
	end
	return l
end

function C:supported_methods(environ)
	local cls = getmetatable(self)
	local l = cls._supported_methods
	if not l then
		l = self:find_supported_methods(cls._methods)
		cls._supported_methods = l
	end
	return l
end

function C:__call(environ)
	local handlers, handler_name, handler
	local args

	handlers = self:supported_methods(environ)
	handler_name = handlers[environ.REQUEST_METHOD]
	if not handler_name then
		return 405, { Allow = handlers }
	end
	handler = self[handler_name]

	args = environ["sancus.routing_args"] or {}

	environ["sancus.handler_name"] = handler_name
	environ["sancus.handler"] = handler
	environ["sancus.named_args"] = args

	self.status = 200
	self.headers = {}
	self.body = {}
	self.req = request.new(environ)

	function self.app_iter()
		if type(self.body) == "string" then
			coroutine.yield(self.body)
		else
			for _,v in ipairs(self.body) do
				coroutine.yield(v)
			end
		end
	end

	local status, headers, iter = handler(self, req, args)
	if status ~= nil then
		return status, headers, iter
	end
	return self.status, self.headers, coroutine.wrap(self.app_iter)
end

--
--
function MinimalMiddleware(app)
	local function nop() end

	return function(env)
		local status, headers, iter = app(env)
		if headers == nil then
			headers = { ['Content-Type'] = 'plain/text' }
		end
		for k,v in pairs(headers) do
			if type(v) == 'table' then
				local t
				if #v > 0 then
					t = v
				else
					t = {}
					for kv,_ in pairs(v) do
						t[#t+1] = kv
					end
				end
				headers[k] = table.concat(t, ", ")
			end
		end
		if iter == nil then
			iter = coroutine.wrap(nop)
		end

		return status, headers, iter
	end
end

return {
	Resource = C,
	MinimalMiddleware = MinimalMiddleware,
}
