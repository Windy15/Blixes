--!strict

local Types = require(script.Parent.Types)

type ActionBinderImpl = {
    __index: ActionBinderImpl,

    new: (holder: Types.Holder) -> (),

    BindAction: (self: ActionBinder, actionName: string, func: actionFunc) -> (),
    BindKeyToAction: (self: ActionBinder, actionName: string, key: EnumItem, inputEvent: RBXScriptSignal) -> (),

    Destroy: (self: ActionBinder) -> (),
}

type actionFunc = (InputObject, boolean) -> ()

export type ActionBinder = typeof(setmetatable({} :: {
    Actions: {[string]: Action},
}, {} :: ActionBinderImpl))

type Action = {
    Function: (InputObject, boolean) -> (),
    Keybinds: {[EnumItem]: {InputEvent: RBXScriptSignal, Connection: RBXScriptConnection}}
}

local Action = {}

function Action.new()
    return {
        Function = function() end,
        Keybinds = {},
    }
end

local ActionBinder = {} :: ActionBinderImpl
ActionBinder.__index = ActionBinder

function ActionBinder.new(holder)
    return setmetatable({
        Holder = holder,
        Actions = {},
    }, ActionBinder)
end

function ActionBinder:BindAction(actionName, func)
    local action = self.Actions[actionName]
    if not action then
        action = Action.new()
        self.Actions[actionName] = action
    else
        for _, keybindData in action.Keybinds do
            keybindData.Connection:Disconnect()
            keybindData.Connection = keybindData.InputEvent:Connect(func)
        end
    end
    action.Function = func
end

local function checkAction(self: ActionBinder, actionName: string)
    local action = self.Actions[actionName]
    if not action then
        error(`Action {actionName} doesn't exist in ActionBinder`, 2)
    end
    return action
end

function ActionBinder:BindKeyToAction(actionName, key, inputEvent)
    local action = checkAction(self, actionName)
    local KeybindData = action.Keybinds[key]
    if KeybindData then
        KeybindData.Connection:Disconnect()
    end
    KeybindData.InputEvent = inputEvent
    KeybindData.Connection = inputEvent:Connect(action.Function)
end

function ActionBinder:Destroy()
    for name, action in self.Actions do
        for _, keybindData in action.Keybinds do
            keybindData.Connection:Disconnect()
        end
        self.Actions[name] = nil
    end
end

return ActionBinder