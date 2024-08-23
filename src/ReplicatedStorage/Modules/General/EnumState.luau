--!strict

local EnumList = require(script.Parent.EnumList)
local Signal = require(script.Parent.Signal)

type EnumStateImpl = {
    __index: EnumStateImpl,
    __type: string,

    new: (...EnumList.EnumItem) -> EnumState,
    GetState: (self: EnumState) -> EnumList.EnumItem,
    PreviousState: (self: EnumState) -> EnumList.EnumItem,
    NextState: (self: EnumState) -> EnumList.EnumItem,
    SetState: (self: EnumState, EnumList.EnumItem) -> (),
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

return EnumState