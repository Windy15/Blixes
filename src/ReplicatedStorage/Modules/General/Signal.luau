--!native
--!strict

--[[
	may need to store thread queue or array to deal with race conditions
	O(1) connect, disconnect
	O(n) fire
]]

type callback<T...> = (T...) -> ()

type SignalImpl<T...> = {
	__index: SignalImpl<T...>,
	__type: "Signal",

	new: () -> Signal<T...>,
	Connect: (self: Signal<T...>, callback: callback<T...>) -> Connection<T...>,
	Once: (self: Signal<T...>, callback: callback<T...>) -> Connection<T...>,
	Wait: (self: Signal<T...>, resumeTime: number?) -> (T...),
	Fire: (self: Signal<T...>, T...) -> (),
	OrderFire: (self: Signal<T...>, T...) -> (),
	Clear: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> ()
}

export type Signal<T...> = typeof(setmetatable({} :: {
	_ConnectionList: Connection<T...>?,
	_YieldList: Connection<T...>?,
	Connections: number,
}, {} :: SignalImpl<T...>))

type ConnectionImpl<T...> = {
	__index: ConnectionImpl<T...>,
	__type: "SignalConnection",
	new: (signal: Signal<T...>, callback: callback<T...> | thread) -> Connection<T...>,
	Disconnect: (self: Connection<T...>) -> ()
}

export type Connection<T...> = typeof(setmetatable({} :: {
	_Signal: Signal<T...>,
	_Callback: callback<T...> | thread,

	_Prev: Connection<T...>?,
	_Next: Connection<T...>?,

	Disconnected: boolean,
}, {} :: ConnectionImpl<T...>))

local Connection = {} :: ConnectionImpl<...any>
Connection.__index = Connection
Connection.__type = "SignalConnection"

function Connection.new<T...>(signal: Signal<T...>, callback: callback<T...> | thread): Connection<T...>
	return setmetatable({
		_Signal = signal,
		_Callback = callback,

		_Prev = nil,
		_Next = nil,

		Disconnected = false,
	}, Connection :: ConnectionImpl<T...>)
end

function Connection:Disconnect()
	if self.Disconnected then return end

	if self._Prev then
		self._Prev._Next = self._Next
		if self._Next then
			self._Next._Prev = self._Prev
		end
	elseif self._Next then
		self._Signal._ConnectionList = self._Next
		self._Next._Prev = nil
	else
		self._Signal._ConnectionList = nil
	end

	self._Signal.Connections -= 1

	self.Disconnected = true
end

local Signal = {} :: SignalImpl<...any>
Signal.__index = Signal
Signal.__type = "Signal"

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_ConnectionList = nil,
		_YieldList = nil,
		Connections = 0,
	}, Signal :: SignalImpl<T...>)
end

function Signal:Connect(callback)
	local _connection = Connection.new(self, callback)

	local oldhead = self._ConnectionList
	if oldhead then
		oldhead._Prev = _connection
		_connection._Next = oldhead
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	self.Connections += 1

	return _connection
end

function Signal:Wait(resumeTime)
	local yield = Connection.new(self, coroutine.running())

	local oldhead = self._YieldList
	if oldhead then
		oldhead._Prev = yield
		yield._Next = oldhead
		self._YieldList = yield
	else
		self._YieldList = yield
	end

	if resumeTime then
		task.delay(resumeTime, function()
			if yield._Prev then
				yield._Prev._Next = yield._Next
				if yield._Next then
					yield._Next._Prev = yield._Prev
				end
			elseif yield._Next then
				local newhead = yield._Next
				self._YieldList = newhead
				newhead._Prev = nil
			else
				self._YieldList = nil
			end
			yield.Disconnected = true

			if coroutine.status(yield._Callback :: thread) == 'suspended' then
				coroutine.resume(yield._Callback :: thread, nil)
			end
		end)
	end

	return coroutine.yield(yield._Callback)
end

function Signal:Once(callback)
	local _connection = Connection.new(self, callback)

	if self._ConnectionList then
		local oldhead = self._ConnectionList
		oldhead._Prev = _connection
		_connection._Next = oldhead
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	_connection._Callback = function(...)
		if _connection._Prev then
			_connection._Prev._Next = _connection._Next
			if _connection._Next then
				_connection._Next._Prev = _connection._Prev
			end
		elseif _connection._Next then
			local newhead = _connection._Next
			self._ConnectionList = newhead
			newhead._Prev = nil
		else
			self._ConnectionList = nil
		end
		_connection.Disconnected = true
		self.Connections -= 1

		callback(...)
	end

	return _connection
end

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler<T...>(fn: callback<T...>, ...: T...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

function Signal:Fire(...)
	local _connection = self._ConnectionList

	while _connection do
		if not freeRunnerThread then
			freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			coroutine.resume(freeRunnerThread :: any)
		end
		coroutine.resume(freeRunnerThread :: thread, _connection._Callback, ...)
		_connection = _connection._Next
	end

	local yield = self._YieldList
	self._YieldList = nil

	while yield do
		coroutine.resume(yield._Callback :: thread, ...)
		yield = yield._Next
	end
end

function Signal:OrderFire(...)
	local _connection = self._ConnectionList

	local connections: {callback<typeof(...)>} = table.create(self.Connections)
	local len = self.Connections

	local i = 0
	while _connection do
		connections[len - i] = _connection._Callback :: callback<typeof(...)>
		i += 1
		_connection = _connection._Next
	end

	for _, func in connections do
		if not freeRunnerThread then
			freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			coroutine.resume(freeRunnerThread :: any)
		end
		coroutine.resume(freeRunnerThread :: thread, func, ...)
	end

	local yield = self._YieldList
	self._YieldList = nil

	while yield do
		coroutine.resume(yield._Callback :: thread, ...)
		yield = yield._Next
	end
end

function Signal:Clear()
	self._ConnectionList = nil
	self.Connections = 0
end

function Signal:Destroy()
	self._ConnectionList = nil
	self._YieldList = nil
	self.Connections = 0
end

return table.freeze(Signal)