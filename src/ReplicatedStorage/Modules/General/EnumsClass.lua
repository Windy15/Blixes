--!strict

export type EnumType = {
    [string]: {},
    __tostring: () -> string,
    __len: () -> number
}

export type EnumsClass = {
    [string]: EnumType,
    __tostring: () -> string,
    __len: () -> number
}

local EnumsClass = {
    EnumType = {}
}

function EnumsClass.EnumType.new(dict: any, enumsName: string): EnumType
    local len = 0
    for name, enum in pairs(dict) do
        if typeof(enum) == "table" then
            enum.__tostring = function()
                return enumsName.."."..name
            end
            setmetatable(enum, enum)
            table.freeze(enum)

            len += 1
        end
    end

    dict.__tostring = function()
        return enumsName
    end
    dict.__len = function()
        return len
    end
    setmetatable(dict, dict)
    table.freeze(dict)

    return dict
end

function EnumsClass.new(dict: any, listName: string): EnumsClass
    local len = 0
    for name, enumType in pairs(dict) do
        if typeof(enumType) == "table" then
            EnumsClass.EnumType.new(enumType, listName.."."..name)
            len += 1
        end
    end
    setmetatable(dict, {
        __tostring = function()
            return listName or "Enum"
        end,
        __len = function()
            return len
        end
    })

    return dict
end

return EnumsClass