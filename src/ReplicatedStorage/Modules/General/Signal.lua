--!strict

type callback = (...any) -> ()

type SignalImpl = {
	__index: SignalImpl,
	_ConnectionList: Connection?,
	_YieldList: Connection?,

	new: () -> Signal,
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Once: (self: Signal, callback: (...any) -> ()) -> (),
	Wait: (self: Signal, resumeTime: number?) -> (...any),
	Fire: (...any) -> (),
	Clear: (self: Signal) -> (),
	Destroy: (self: Signal) -> ()
}

export type Signal = typeof(setmetatable({} :: {
	_ConnectionList: Connection?,
	_YieldList: Connection?,
}, {} :: SignalImpl))

type ConnectionImpl = {
	new: (signal: Signal, callback: callback | thread) -> Connection,
	Disconnect: (self: Connection) -> ()
}

export type Connection = typeof(setmetatable({} :: {
	_Signal: Signal,
	_Callback: callback | thread,
	_Next: Connection?
}, {} :: ConnectionImpl))

local Connection = {}
Connection.__index = Connection

function Connection.new(signal: Signal, callback: callback | thread): Connection
	return setmetatable({
		_Signal = signal,
		_Callback = callback,
		_Next = nil
	}, Connection)
end

function Connection:Disconnect()
	local before = self._Signal._ConnectionList

	if before == self then
		self._Signal._ConnectionList = (before :: Connection)._Next
	else
		while (before :: Connection)._Next ~= self do
			before = (before :: Connection)._Next
		end

		if before then
			before._Next = self._Next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	return setmetatable({
		_ConnectionList = nil,
		_YieldList = nil,
	}, Signal)
end

function Signal:Connect(callback: callback)
	local _connection = Connection.new(self, callback)

	if self._ConnectionList then
		_connection._Next = self._ConnectionList
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	return _connection
end

function Signal:Wait(resumeTime: number?)
	local yield = Connection.new(self, coroutine.running())

	if self._YieldList then
		yield._Next = self._YieldList
		self._YieldList = yield
	else
		self._YieldList = yield
	end

	if resumeTime then
		task.delay(resumeTime, function()
			local before = self._YieldList

			if before == yield then
				self._YieldList = (before :: Connection)._Next
			else
				while before do
					if before._Next == yield then
						before._Next = yield._Next
						break
					end
				end
			end

			if coroutine.status(yield._Callback :: thread) == 'suspended' then
				coroutine.resume(yield._Callback :: thread, nil)
			end
		end)
	end

	return coroutine.yield(yield._Callback)
end

function Signal:Once(callback: callback)
	local _connection = Connection.new(self, callback)

	if self._ConnectionList then
		_connection._Next = self._ConnectionList
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	_connection._Callback = function(...)
		local before = self._ConnectionList

		if before == _connection then
			self._ConnectionList = (before :: Connection)._Next
		else
			while before do
				if before._Next == _connection then
					before._Next = _connection._Next
					break
				end
				before = before._Next
			end
		end

		callback(...)
	end

	return _connection
end

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler(fn: callback, ...)
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

function Signal:Fire(...: any)
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
		coroutine.resume(yield._Callback, ...)
		yield = yield._Next
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