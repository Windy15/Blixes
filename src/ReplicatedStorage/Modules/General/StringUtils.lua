--!strict

export type StringUtils = {
    LAST_INDEX_PATTERN: string,
    formatAddress: (t: any, tableName: string?) -> string,
    lastIndexName: (indexChainStr: string) -> string
}

local StringUtils = {
    LAST_INDEX_PATTERN = ".+%.(.+)"
}

function StringUtils.formatAddress(t: any, tableName: string?): string
    return (tableName and tableName..": " or "")..string.match(tostring(t), "0x(.+)") :: string
end

function StringUtils.lastIndexName(indexChainStr: string): string
    return string.match(indexChainStr, StringUtils.LAST_INDEX_PATTERN)
end

return StringUtils :: StringUtils