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

type EnumItemImpl = {
    __index: EnumItemImpl,
    __type: string,
    __tostring: (self: EnumItem) -> string,
}

export type EnumItem = typeof(setmetatable({} :: {
    Name: string,
    TypeName: string,
    Value: number,
    _Id: number,
}, {} :: EnumItemImpl))


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
EnumItem.__index = EnumItem
EnumItem.__type = "EnumItem"
EnumItem.__tostring = function(self: EnumItem)
    return self.TypeName.."."..self.Name
end

local function enumSort(x: EnumItem, y: EnumItem): boolean
    return x.Value < y.Value
end

local EnumIds = setmetatable({} :: {EnumItem}, {__mode = "k"})
local genId = 1

function EnumType.new(dict: any, typeName: string, list: EnumList): EnumType
    local orderedItems = {} :: {EnumItem}

    local newEnumType = {}

    for itemName, value in dict do
        if typeof(value) == "number" then
            local enumItem = setmetatable({
                Name = itemName,
                TypeName = typeName,
                Value = value,
                _Id = genId
            }, EnumItem)
            table.freeze(enumItem)

            EnumIds[genId] = enumItem
            genId += 1

            newEnumType[itemName] = enumItem
            table.insert(orderedItems, enumItem :: any)
        else
            warn(debug.traceback("", 3), "EnumItem '"..itemName.."' value type must be number")
        end
    end

    for name, item in newEnumType do
        dict[name] = item
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
    for name, enumType in dict do
        if typeof(enumType) == "table" then
            EnumType.new(enumType, name, dict)
            len += 1
        end
    end
    dict.Name = listName
    setmetatable(dict, EnumList)

    return dict
end

function EnumList.toId(enumItem: EnumItem)
    return string.format("%x", enumItem._Id)
end

function EnumList.fromId(enumId: string)
    local id = tonumber(enumId, 16)
    if not id then
        error(`Invalid id {enumId} for EnumList`, 2)
    end
    return EnumIds[id]
end

return EnumList