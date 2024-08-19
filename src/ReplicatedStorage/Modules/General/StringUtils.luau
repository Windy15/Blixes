--!native
--!strict

type anytable = {[any]: any} | SharedTable

export type StringUtils = {
    formatAddress: (t: any, tableName: string?) -> string,
    displayTable: (t: anytable) -> string,
    lastIndexName: (indexChainStr: string) -> string,
    decimalToString: (num: number) -> string,
    hashString: (str: string, p: number?) -> number,
}

local StringUtils = {}

function StringUtils.formatAddress(t: any, tableName: string?): string
    return (tableName and tableName..": " or "")..string.match(tostring(t), "0x(.+)") :: string
end

local DefaultPrints = {
    "RaycastParams",
    "RaycastResult",
}

local function tabValue(i)
    if type(i) == "string" then
        return '"'..i..'"'
    elseif typeof(i) == "Instance" then
        return "Instance("..i:GetFullName()..")"
    elseif table.find(DefaultPrints, typeof(i)) then
        return tostring(i)
    elseif typeof(i) ~= type(i) then -- if 'i' is a roblox object
        return typeof(i).."("..tostring(i)..")"
    else
        return tostring(i)
    end
end

local function tabToStr(t: anytable, depth: number, tables: {[anytable]: boolean}): string
    local str = "{\n"
    for i, v in t :: {[any]: any} do
        str ..= string.rep("\t", depth + 1)..`[{tabValue(i)}] = `

        if type(v) == "table" then
            if next(v) then -- if table isn't empty
                if tables[v] then
                    str ..= "{CYCLIC REFERENCE: "..tostring(v).."}"
                else
                    local env = table.clone(tables)
                    env[v] = true
                    str ..= tabToStr(v, depth + 1, env)
                end
            else
                str ..= "{}"
            end
        elseif typeof(v) == "SharedTable" then
            if SharedTable.size(v) ~= 0 then
                if tables[v] then
                    str ..= "{CYCLIC REFERENCE: "..tostring(v).."}"
                else
                    local env = table.clone(tables)
                    env[v] = true
                    str ..= "SharedTable"..tabToStr(v, depth + 1, env)
                end
            else
                str ..= "SharedTable{}"
            end
        else
            str ..= tabValue(v)
        end

        str ..= "\n"
    end
    str ..= string.rep("\t", depth).."}\n"
    return str
end

function StringUtils.displayTable(t: anytable): string
    if type(t) == "table" then
        return next(t) and tabToStr(t, 0, {}) or "{}"
    elseif typeof(t) == "SharedTable" then
        return SharedTable.size(t) ~= 0 and tabToStr(t, 0, {}) or "{}"
    else
        error("Arguement 1 for StringUtils.displayTable must be a table", 2)
    end
end

function StringUtils.lastIndexName(indexChainStr: string): string?
    return string.match(indexChainStr, ".+%.(.+)")
end

function StringUtils.decimalToString(num: number): string
    return string.gsub(string.format("%.16f", num), "0*$", "")
end

local M = 9007199254740992 -- 53 bit integer max

function StringUtils.hashString(str: string, p: number?) -- polynomial rolling hash function
    p = p or 257
    local hash = 0
    local p_pow = 1
    for i = 1, #str do
        local c = string.byte(str, i, i)
        hash = hash + (c - 0) * p_pow % M
        p_pow = (p_pow * p :: number) % M
    end
    return hash
end

return StringUtils :: StringUtils