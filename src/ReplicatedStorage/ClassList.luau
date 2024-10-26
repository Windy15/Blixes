--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassFolders = {
    Tool = ReplicatedStorage.Tools.Classes
} :: {[string]: Folder}

local ClassListMeta = {}
ClassListMeta.__index = ClassListMeta

local ClassList = setmetatable({} :: {[string]: any}, ClassListMeta)

for name, folder in ClassFolders do
    local category = {}
    ClassList[name] = category
    for _, module in folder:GetDescendants() do
        if module:IsA("ModuleScript") then
            category[module.Name] = require(module) :: any
        end
    end
end

function ClassListMeta:GetToolClass(toolName: string)
    local class = ClassList.Tool[toolName]
    return (assert(class, `Tool class for '{toolName}' does not exist`))
end

return ClassList