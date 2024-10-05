--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ClassFolders = {
    {"Tool", ServerScriptService.Tools.Classes}
}

local ClassList: {[string]: any} = {}

for _, categoryData in ipairs(ClassFolders) do
    local category = {}
    ClassList[categoryData[1]] = category
    for _, module in ipairs(categoryData[2]:GetDescendants()) do
        if module:IsA("ModuleScript") then
            category[module.Name] = require(module)
        end
    end
end

function ClassList:GetClass(categoryName: string, className: string)
	local category = self[categoryName]
    if not category then
        error(`Invalid Category Name "{categoryName}"`, 2)
    end
    return category[className]
end

return ClassList