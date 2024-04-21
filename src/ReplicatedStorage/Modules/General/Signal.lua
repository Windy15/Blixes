--!nonstrict

type table = {[string]: any}

type SignalImpl = {
	__index: SignalImpl,
	_ConnectionList: table?,
	_YieldList: table?,

	new: () -> Signal,
	Connect: (self: Signal, callback: (...any) -> ()) -> (),
	Once: (self: Signal, callback: (...any) -> ()) -> (),
	Wait: (self: Signal, resumeTime: number?) -> (...any),
	Fire: (...any) -> (),
	Clear: (self: Signal) -> (),
	Destroy: (self: Signal) -> ()
}

export type Signal = typeof(setmetatable({} :: {
	_ConnectionList: table?,
	_YieldList: table?,
}, {} :: SignalImpl))

local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
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

local Connection = {}
Connection.__index = Connection

function Connection.new(signal: Signal, thread)
	return setmetatable({
		_Signal = signal,
		_Thread = thread,
		_Next = nil
	}, Connection)
end

function Connection:Disconnect()
	if self._Signal._ConnectionList == self then
		self._Signal._ConnectionList = self._Signal._ConnectionList.Next
	else
		local before = self._Signal._ConnectionList

		while before._Next ~= self do
			before = before._Next
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

function Signal:Connect(callback: (...any) -> ())
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
	local Yield = Connection.new(self, coroutine.running())

	if self._YieldList then
		Yield._Next = self._YieldList
		self._YieldList = Yield
	else
		self._YieldList = Yield
	end

	if resumeTime then
		task.delay(resumeTime, function()
			local before = self._YieldList

			if before == Yield then
				self._YieldList = self._YieldList.Next
			else
				while before._Next do
					if before._Next == self._YieldList then
						before._Next = self._YieldList._Next
						break
					end
				end
			end

			if coroutine.status(Yield._Thread) == 'suspended' then
				coroutine.resume(Yield._Thread, nil)
			end
		end)
	end

	return coroutine.yield(Yield._Thread)
end

function Signal:Once(callback: (...any) -> ())
	local _connection = Connection.new(self, callback)

	if self._ConnectionList then
		_connection._Next = self._ConnectionList
		self._ConnectionList = _connection
	else
		self._ConnectionList = _connection
	end

	_connection._Thread = function(...)
		local before = self._ConnectionList

		if before == _connection then
			self._ConnectionList = self._ConnectionList.Next
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

function Signal:Fire(...: any)
	local _connection = self._ConnectionList

	while _connection do
		if not freeRunnerThread then
			freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			coroutine.resume(freeRunnerThread)
		end
		coroutine.resume(freeRunnerThread, _connection._Thread, ...)
		_connection = _connection._Next
	end

	local yield = self._YieldList

	while yield do
		coroutine.resume(yield._Thread, ...)
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