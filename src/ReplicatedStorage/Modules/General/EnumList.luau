--!strict

--[[
EnumList = {
    EnumType = {
        EnumItem = 1,
        EnumItem = 2,
        EnumItem = 3,
    }
}
]]

export type EnumItem = {
    Name: string,
    TypeName: string,
    Value: number,
}

export type EnumType = {
    [string]: EnumItem,
    Name: string,
    OrderedItems: {EnumItem},
    List: EnumList,
}

type EnumListImpl = {
    __index: EnumListImpl,

    new: (dict: any, listName: string) -> EnumList,
    FromData: (self: EnumList, data: EnumType) -> EnumType
}

export type EnumList = typeof(setmetatable({} :: {
    [string]: EnumType,
    Name: string,
}, {} :: EnumListImpl))

local EnumType = {
    __tostring = function(self: EnumType)
        return self.List.Name.."."..self.Name
    end,
    __iter = function(self)
        return next, self.ItemsArray
    end,
    __len = function(self)
        return #self.OrderedItems
    end,
}

local EnumItem = {}
EnumItem.__tostring = function(self: EnumItem)
    return self.TypeName.."."..self.Name
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
                TypeName = typeName,
                Value = value
            }, EnumItem)

            table.freeze(enumItem)
            dict[itemName] = enumItem

            table.insert(orderedItems, enumItem :: any)
        end
    end

    table.sort(orderedItems, enumSort)

    dict.ItemsArray = orderedItems
    dict.Name = typeName
    dict.List = list

    setmetatable(dict, EnumType)
    table.freeze(dict)

    return dict
end

local EnumList = {
    __tostring = function(self)
        return self.Name
    end
}
EnumList.__index = EnumList

function EnumList.new(dict: any, listName: string?): EnumList
    listName = listName or "Enum"
    local len = 0
    for name, enumType in pairs(dict) do
        if typeof(enumType) == "table" then
            enumType.Name = name
            EnumType.new(enumType, name, dict)
            len += 1
        end
    end
    dict.Name = listName
    setmetatable(dict, EnumList)

    return dict
end

function EnumList:FromData(enumItemData: EnumItem)
    local enumType = self[enumItemData.TypeName]
    if enumType then
        local item = enumType[enumItemData.Name]
        if item then
            return item
        end
    end
    return nil
end

return EnumList