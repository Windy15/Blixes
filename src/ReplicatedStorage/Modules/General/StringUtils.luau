--!strict
--!native

type anytable = {[any]: any} | SharedTable

export type StringUtils = {
    formatAddress: (t: any, tableName: string?) -> string,
    formatTable: (t: anytable) -> string,
    lastIndexName: (indexChainStr: string) -> string,
    decimalToString: (num: number) -> string,
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

local function tabToStr(t: anytable, depth: number, tables: {anytable}): string
    local str = "{\n"
    for i, v in t :: {[any]: any} do
        str ..= string.rep("\t", depth + 1)..`[{tabValue(i)}] = `

        if type(v) == "table" then
            if next(v) then -- if table isn't empty
                if table.find(tables, v) then
                    str ..= "{CYCLIC REFERENCE: "..tostring(v).."}"
                else
                    local env = table.clone(tables)
                    table.insert(env, v)
                    str ..= tabToStr(v, depth + 1, env)
                end
            else
                str ..= "{}"
            end
        elseif typeof(v) == "SharedTable" then
            if SharedTable.size(v) ~= 0 then
                if table.find(tables, v) then
                    str ..= "{CYCLIC REFERENCE: "..tostring(v).."}"
                else
                    local env = table.clone(tables)
                    table.insert(env, v)
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

function StringUtils.formatTable(t: anytable): string
    if type(t) == "table" then
        return next(t) and tabToStr(t, 0, {}) or "{}"
    elseif typeof(t) == "SharedTable" then
        return SharedTable.size(t) ~= 0 and tabToStr(t, 0, {}) or "{}"
    else
        error("Arguement 1 for StringUtils.formatTable must be a table", 2)
    end
end

local LAST_INDEX_PATTERN = ".+%.(.+)"

function StringUtils.lastIndexName(indexChainStr: string): string?
    return string.match(indexChainStr, LAST_INDEX_PATTERN)
end

function StringUtils.decimalToString(num: number): string
    return string.gsub(string.format("%.16f", num), "0*$", "")
end

return StringUtils :: StringUtils