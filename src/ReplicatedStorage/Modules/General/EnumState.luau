--!strict

local EnumList = require(script.Parent.EnumList)
local Signal = require(script.Parent.Signal)

type EnumStateImpl = {
    __index: EnumStateImpl,
    __type: "EnumState",

    new: (...EnumList.EnumItem) -> EnumState,
    GetState: (self: EnumState) -> EnumList.EnumItem,
    IsState: (self: EnumState, state: EnumList.EnumItem) -> boolean,
    PreviousState: (self: EnumState) -> EnumList.EnumItem,
    NextState: (self: EnumState) -> EnumList.EnumItem,
    SetState: (self: EnumState, EnumList.EnumItem) -> (),

    toIds: (state: EnumState) -> buffer,
    fromIds: (idbuff: buffer) -> EnumState,
}

export type EnumState = typeof(setmetatable({} :: {
    States: {EnumList.EnumItem},
    _Prev: number,
    _Current: number,

    OnStateChanged: Signal.Signal<EnumList.EnumItem>
}, {} :: EnumStateImpl))

local EnumState = {} :: EnumStateImpl
EnumState.__index = EnumState
EnumState.__type = "EnumState"

function EnumState.new(...)
    return setmetatable({
        States = {...},
        _Prev = 1,
        _Current = 1,

        OnStateChanged = Signal.new(),
    }, EnumState)
end

function EnumState:GetState()
    return self.States[self._Current]
end

function EnumState:IsState(state)
    return self.States[self._Current] == state
end

function EnumState:PreviousState()
    return self.States[self._Prev]
end

function EnumState:NextState()
    return self.States[(self._Current % #self.States) + 1]
end

function EnumState:SetState(state: EnumList.EnumItem)
    local index = table.find(self.States, state)
    if not index then
        error(`Invalid state {state} for EnumState`, 2)
    end
    self._Current = index
end

local ID_SIZE = 2

function EnumState.toIds(state)
    local buff = buffer.create(#state.States * ID_SIZE)
    for i, item in state.States do
        buffer.writeu16(buff, i - 1, EnumList.toId(item))
    end
    return buff
end

function EnumState.fromIds(idbuff)
    local states = {}
    for i = 0, buffer.len(idbuff) - 1, ID_SIZE do
        table.insert(states, EnumList.fromId(buffer.readu16(idbuff, i)))
    end
    return EnumState.new(table.unpack(states))
end

return EnumState