local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassFolders = {
    {"Tool", ReplicatedStorage.ToolClasses}
}

local ClassList = {}

for _, categoryData in ipairs(ClassFolders) do
    local category = {}
    ClassList[categoryData[1]] = category
    for _, module in ipairs(categoryData[2]:GetDescendants()) do
        if module:IsA("ModuleScript") then
            category[module.Name] = module
        end
    end
end

function ClassList:GetClass(categoryName: string, className: string)
	local category = self[categoryName]
    if not category then
        error(`Invalid Category Name "{categoryName}"`, 2)
    end

    local class = category[className]
    if not class then
        error(`Invalid Class Name "{categoryName}"`, 2)
    end

    return class
end

return ClassList