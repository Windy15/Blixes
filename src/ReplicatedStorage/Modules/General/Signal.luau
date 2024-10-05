--!native
--!strict

--[[
	O(1) connect, disconnect, once
	O(n) fire
]]

type callback<T...> = (T...) -> ()

type SignalImpl<T...> = {
	__index: SignalImpl<T...>,
	__type: "Signal",

	new: () -> Signal<T...>,
	Connect: (self: Signal<T...>, callback: callback<T...>) -> Connection<T...>,
	Once: (self: Signal<T...>, callback: callback<T...>) -> T...?,
	Wait: (self: Signal<T...>, resumeTime: number?) -> (T...),
	Fire: (self: Signal<T...>, T...) -> (),
	Clear: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> ()
}

export type Signal<T...> = typeof(setmetatable({} :: {
	_ConnectionList: Connection<T...>?,
	_YieldList: Connection<T...>?,
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

	_Last: Connection<T...>?,
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

		_Last = nil,
		_Next = nil,

		Disconnected = false,
	}, Connection :: ConnectionImpl<T...>)
end

function Connection:Disconnect()
	if self.Disconnected then return end

	if self._Last then
		self._Last._Next = self._Next
	elseif self._Next then
		self._Signal._ConnectionList = self._Next
		self._Next._Last = nil
	else
		self._Signal._ConnectionList = nil
	end

	self.Disconnected = true
end

local Signal = {} :: SignalImpl<...any>
Signal.__index = Signal
Signal.__type = "Signal"

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_ConnectionList = nil,
		_YieldList = nil,
	}, Signal :: SignalImpl<T...>)
end

function Signal:Connect(callback)
	local _connection = Connection.new(self, callback)

	local oldhead = self._ConnectionList
	if oldhead then
		oldhead._Last = _connection
		_connection._Next = oldhead
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	return _connection
end

function Signal:Wait(resumeTime: number?)
	local yield = Connection.new(self, coroutine.running())

	local oldhead = self._YieldList
	if oldhead then
		oldhead._Last = yield
		yield._Next = oldhead
		self._YieldList = yield
	else
		self._YieldList = yield
	end

	if resumeTime then
		task.delay(resumeTime, function()
			if yield._Last then
				yield._Last._Next = yield._Next
			elseif yield._Next then
				local newhead = yield._Next
				self._YieldList = newhead
				newhead._Last = nil
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
		oldhead._Last = _connection
		_connection._Next = oldhead
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	_connection._Callback = function(...)
		if _connection._Last then
			_connection._Last._Next = _connection._Next
		elseif _connection._Next then
			local newhead = _connection._Next
			self._ConnectionList = newhead
			newhead._Last = nil
		else
			self._ConnectionList = nil
		end
		_connection.Disconnected = true

		callback(...)
	end

	return _connection
end

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler(fn: any, ...)
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

	while yield do
		coroutine.resume(yield._Callback :: thread, ...)
		yield = yield._Next
		self._YieldList = yield
	end
end

function Signal:Clear()
	self._ConnectionList = nil
end

function Signal:Destroy()
	self._ConnectionList = nil
	self._YieldList = nil
end

return table.freeze(Signal)