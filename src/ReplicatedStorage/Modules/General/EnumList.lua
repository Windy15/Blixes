--!strict

--[[
EnumList = {
    EnumType = {
        EnumItem = 1,
        EnumItem = 2,
        EnumItem = 3
    }
}
]]

export type EnumItem = {
    Name: string,
    Type: EnumType,
    Value: number,
}

export type EnumType = {
    [string]: EnumItem,
    __name: string,
    OrderedItems: {EnumItem},
    List: EnumList,
}

export type EnumList = {
    [string]: EnumType,
    __name: string,
}

local EnumsClass = {
    __tostring = function(self)
        return self.__name
    end
}

local EnumType = {
    __tostring = function(self: EnumType)
        return self.List.__name.."."..self.__name
    end,
    __iter = function(self)
        return next, self.ItemsArray
    end,
    __len = function(self)
        return #self.OrderedItems
    end
}

local EnumItem = {}
EnumItem.__tostring = function(self: EnumItem)
    return self.Type.List.__name.."."..self.Type.__name.."."..self.Name
end

local function enumSort(x: EnumItem, y: EnumItem): boolean
    return x.Value < y.Value
end

function EnumType.new(dict: any, typeName: string, list: EnumList): EnumType
    local orderedItems = {} :: {EnumItem}
    for itemName, value in pairs(dict) do
        if typeof(value) == "number" then
            local enumItem = setmetatable({
                Name = itemName,
                Type = dict,
                Value = value
            }, EnumItem)

            table.freeze(enumItem)
            dict[itemName] = enumItem

            table.insert(orderedItems, enumItem :: any)
        end
    end

    table.sort(orderedItems, enumSort)

    dict.ItemsArray = orderedItems
    dict.__name = typeName
    dict.List = list

    setmetatable(dict, EnumType)
    table.freeze(dict)

    return dict
end

function EnumsClass.new(dict: any, listName: string?): EnumList
    listName = listName or "Enum"
    local len = 0
    for name, enumType in pairs(dict) do
        if typeof(enumType) == "table" then
            enumType.Name = name
            EnumType.new(enumType, name, dict)
            len += 1
        end
    end
    dict.__name = listName
    setmetatable(dict, EnumsClass)

    return dict
end

return EnumsClass