--!strict
--!native

type table = {[any]: any}

export type StringUtils = {
    formatAddress: (t: any, tableName: string?) -> string,
    formatTable: (t: table) -> string,
    lastIndexName: (indexChainStr: string) -> string
}

local StringUtils = {}

function StringUtils.formatAddress(t: any, tableName: string?): string
    return (tableName and tableName..": " or "")..string.match(tostring(t), "0x(.+)") :: string
end

local function tabValue(i)
    if type(i) == "string" then
        return '"'..i..'"'
    else
        return tostring(i)
    end
end

local function tabToStr(t: table, depth: number): string
    local str = "{\n"
    for i, v in pairs(t) do
        if type(v) == "table" then
            str ..= string.rep("\t", depth + 1)..`[{tabValue(i)}]`.." = "..tabToStr(v, depth + 1)
        else
            str ..= string.rep("\t", depth + 1)..`[{tabValue(i)}]`.." = "..tabValue(v).."\n"
        end
    end
    str ..= string.rep("\t", depth).."}\n"
    return str
end

function StringUtils.formatTable(t: table): string
    return tabToStr(t, 0)
end

local LAST_INDEX_PATTERN = ".+%.(.+)"

function StringUtils.lastIndexName(indexChainStr: string): string?
    return string.match(indexChainStr, LAST_INDEX_PATTERN)
end

return StringUtils :: StringUtils