local StringUtils = {}

function StringUtils.formatAddress(t, tableName)
    return (tableName and tableName..": " or "")..string.match(tostring(t), "0x(.+)")
end

return StringUtils