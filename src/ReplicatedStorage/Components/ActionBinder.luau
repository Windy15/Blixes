--!strict

local UserInputService = game:GetService("UserInputService")

local Types = require(script.Parent.Types)

type ActionBinderImpl = {
    __index: ActionBinderImpl,

    new: (holder: Types.Holder) -> (),

    BindAction: (self: ActionBinder, actionName: string, func: actionFunc) -> (),
    BindKeyToAction: (self: ActionBinder, actionName: string, key: EnumItem) -> (),

    Destroy: (self: ActionBinder) -> (),
}

type actionFunc = (InputObject, boolean) -> ()

export type ActionBinder = typeof(setmetatable({} :: {
    Actions: {[string]: Action},
}, {} :: ActionBinderImpl))

type Action = {
    Function: (InputObject, boolean) -> (),
    Keybinds: {[EnumItem]: RBXScriptConnection}
}

local Action = {}

function Action.new()
    return {
        Function = function() end,
        Keybinds = {},
    }
end

local ActionBinder = {} :: ActionBinderImpl

function ActionBinder.new(holder)
    return setmetatable({
        Holder = holder,
        Actions = {},
    }, ActionBinder)
end

function ActionBinder:BindAction(actionName, func)
    if not self.Actions[actionName] then
        self.Actions[actionName] = Action.new()
    end
    self.Actions[actionName].Function = func
end

local function checkAction(self: ActionBinder, actionName: string)
    local action = self.Actions[actionName]
    if not action then
        error(`Action {actionName} doesn't exist in ActionBinder`, 2)
    end
    return action
end

function ActionBinder:BindKeyToAction(actionName, key)
    local action = checkAction(self, actionName)
    if action.Keybinds[key] then
        action.Keybinds[key]:Disconnect()
    end
    action.Keybinds[key] = UserInputService.InputBegan:Connect(action.Function)
end

function ActionBinder:Destroy()
    for name, action in self.Actions do
        for _, connection in action.Keybinds do
            connection:Disconnect()
        end
        self.Actions[name] = nil
    end
end

return ActionBinder