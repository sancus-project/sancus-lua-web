--

local Class = assert(require"sancus.object").Class
local request = assert(require"wsapi.request")
local mimeparse = require"mimeparse"

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
	local l = self._supported_methods
	if not l then
		l = self:find_supported_methods(self._methods)
		self._supported_methods = l
	end
	return l
end

function C:__call(environ)
	local method = environ.REQUEST_METHOD
	local h = environ.headers
	local handlers, handler_name, handler
	local args

	handlers = self:supported_methods(environ)
	handler_name = handlers[method]

	if not handler_name then
		return 405, { Allow = handlers }
	end
	handler = self[handler_name]

	if self._accepted_types ~= nil then
		local content_type = mimeparse.best_match(self._accepted_types,
				h.HTTP_ACCEPT or "*/*")

		if content_type == "" then
			return 406
		else
			h["sancus.content_type"] = content_type
		end
	end

	args = h["sancus.routing_args"] or {}

	h["sancus.handler_name"] = handler_name
	h["sancus.handler"] = handler
	h["sancus.named_args"] = args

	self.status = 200
	self.headers = {}
	self.body = {}

	if method ~= 'POST' then
		self.req = request.new(environ, { delay_post = true })
	else
		self.req = request.new(environ)
	end

	function self.app_iter()
		if type(self.body) == "string" then
			coroutine.yield(self.body)
		else
			for _,v in ipairs(self.body) do
				coroutine.yield(v)
			end
		end
	end

	local status, headers, iter

	if self._pre_handler then
		status, headers, iter = self._pre_handler(self, self.req, args)
	end
	if not status then
		status, headers, iter = handler(self, self.req, args)
	end
	if status ~= nil then
		return status, headers, iter
	end
	return self.status, self.headers, coroutine.wrap(self.app_iter)
end

--
--
function MinimalMiddleware(app, interceptor)
	local function nop() end

	interceptor = interceptor or {}

	return function(env)
		local status, headers, iter = app(env)
		if interceptor[status] then
			_, headers, iter = interceptor[status](env)
		end

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

function RemoveTrailingSlashMiddleware(app)
	return function(env)
		local path_info = env.headers["PATH_INFO"]
		if #path_info > 1 and path_info:sub(-1) == '/' then
			local headers = { Location = path_info:sub(0, -2) }
			local function iter()
				return
			end
			return 301, headers, coroutine.wrap(iter)
		else
			return app(env)
		end
	end
end

return {
	Resource = C,
	MinimalMiddleware = MinimalMiddleware,
	RemoveTrailingSlashMiddleware = RemoveTrailingSlashMiddleware,
}
