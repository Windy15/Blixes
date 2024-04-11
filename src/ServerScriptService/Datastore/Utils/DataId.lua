local HttpService = game:GetService("HttpService")

local DataId = {}

function DataId.generateId()
    return (string.gsub(HttpService:GenerateGUID(false), "-", ""))
end

return DataId