--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Components.Types)

type ActionBinderImpl = {
    __index: ActionBinderImpl,

    new: (holder: Types.Holder) -> (),

    BindAction: (self: ActionBinder, actionName: string, func: actionFunc) -> (),
    BindEventToAction: (self: ActionBinder, actionName: string, inputEvent: RBXScriptSignal) -> (),

    Destroy: (self: ActionBinder) -> (),
}

type actionFunc = (InputObject, boolean) -> ()

export type ActionBinder = typeof(setmetatable({} :: {
    Actions: {[string]: Action},
}, {} :: ActionBinderImpl))

type Action = {
    Function: actionFunc,
    InputEvents: {[RBXScriptSignal]: RBXScriptConnection}
}

local Action = {}

function Action.new(): Action
    return {
        Function = function() end,
        InputEvents = {},
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
        -- update all input events to use new function
        for event, connection in action.InputEvents do
            connection:Disconnect()
            action.InputEvents[event] = event:Connect(func)
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

function ActionBinder:BindEventToAction(actionName, inputEvent)
    local action = checkAction(self, actionName)
    local connection = action.InputEvents[inputEvent]
    if connection then
        connection:Disconnect()
    end
    action.InputEvents[inputEvent] = inputEvent:Connect(action.Function)
end

function ActionBinder:Destroy()
    for name, action in self.Actions do
        for _, connection in action.InputEvents do
            connection:Disconnect()
        end
        self.Actions[name] = nil
    end
end

return ActionBinder